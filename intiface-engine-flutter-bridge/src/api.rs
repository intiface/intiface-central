use crate::{
  in_process_frontend::FlutterIntifaceEngineFrontend,
  logging::FlutterTracingWriter,
  mobile_init,
};
use anyhow::Result;
use buttplug::server::device::configuration::{DeviceConfigurationManagerBuilder, SerialSpecifier};
pub use buttplug::{
  core::message::{ButtplugActuatorFeatureMessageType, ButtplugDeviceMessageType, ButtplugSensorFeatureMessageType, DeviceFeature, DeviceFeatureActuator, DeviceFeatureRaw, DeviceFeatureSensor, Endpoint, FeatureType},
  server::device::{
    configuration::{ProtocolCommunicationSpecifier, UserDeviceCustomization, UserDeviceDefinition, UserDeviceIdentifier, WebsocketSpecifier, DeviceConfigurationManager},
    protocol::get_default_protocol_map,
  },
  util::device_configuration::{load_protocol_configs, save_user_config}
};
use flutter_rust_bridge::{frb, StreamSink};
use futures::{pin_mut, StreamExt};
use lazy_static::lazy_static;
use once_cell::sync::OnceCell;
use sentry::ClientInitGuard;
use std::{
  collections::HashSet, fs, ops::RangeInclusive, sync::{
    atomic::{AtomicBool, Ordering},
    Arc, Mutex, RwLock,
  }, thread, time::Duration
};
use tokio::{
  select,
  sync::{broadcast, Notify}, runtime::Runtime,
};
use tracing_futures::Instrument;

pub use intiface_engine::{EngineOptions, EngineOptionsExternal, IntifaceEngine, IntifaceMessage};

static CRASH_REPORTING: OnceCell<ClientInitGuard> = OnceCell::new();
static ENGINE_NOTIFIER: OnceCell<Arc<Notify>> = OnceCell::new();
lazy_static! {
  static ref RUNTIME: Arc<Mutex<Option<Runtime>>> = Arc::new(Mutex::new(None));
  static ref LOGGER: Arc<Mutex<Option<FlutterTracingWriter>>> = Arc::new(Mutex::new(None));
  static ref RUN_STATUS: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
  static ref ENGINE_BROADCASTER: Arc<broadcast::Sender<IntifaceMessage>> =
    Arc::new(broadcast::channel(255).0);
  static ref BACKDOOR_INCOMING_BROADCASTER: Arc<broadcast::Sender<String>> =
    Arc::new(broadcast::channel(255).0);
  // This is a weird wrapping, but there's a reason for it. The DCM has internal mutability, but we
  // also want to be able to completely replace it (if the user clears configurations and starts
  // over, as is possible with central). However, we also want to share the DCM with the Buttplug
  // Server while it's running. Therefore, we pull Read versions of the lock while the server is
  // running, which means we can't stop the Arc and start over until we're clear of the owning
  // process.
  //
  // The cavaet here is that, if the engine task/isolate panics, we'll be stuck with a poisoned read
  // lock. While this probably shouldn't happen, it does. A lot. So we'll need to check for an
  // active runtime whenever we try to get write locks, and clear poisoning if there's no runtime
  // active.
  static ref DEVICE_CONFIG_MANAGER: Arc<RwLock<Arc<DeviceConfigurationManager>>> = 
    Arc::new(RwLock::new(Arc::new(load_protocol_configs(&None, &None, false).unwrap().finish().unwrap())));
}

#[frb(mirror(EngineOptionsExternal))]
pub struct _EngineOptionsExternal {
  pub device_config_json: Option<String>,
  pub user_device_config_json: Option<String>,
  pub user_device_config_path: Option<String>,
  pub server_name: String,
  pub websocket_use_all_interfaces: bool,
  pub websocket_port: Option<u16>,
  pub frontend_websocket_port: Option<u16>,
  pub frontend_in_process_channel: bool,
  pub max_ping_time: u32,
  pub allow_raw_messages: bool,
  pub use_bluetooth_le: bool,
  pub use_serial_port: bool,
  pub use_hid: bool,
  pub use_lovense_dongle_serial: bool,
  pub use_lovense_dongle_hid: bool,
  pub use_xinput: bool,
  pub use_lovense_connect: bool,
  pub use_device_websocket_server: bool,
  pub device_websocket_server_port: Option<u16>,
  pub crash_main_thread: bool,
  pub crash_task_thread: bool,
  pub websocket_client_address: Option<String>,
  pub broadcast_server_mdns: bool,
  pub mdns_suffix: Option<String>,
  pub repeater_mode: bool,
  pub repeater_local_port: Option<u16>,
  pub repeater_remote_address: Option<String>,
}

pub fn runtime_started() -> bool {
  RUNTIME.lock().unwrap().is_some()
}

pub fn run_engine(sink: StreamSink<String>, args: EngineOptionsExternal) -> Result<()> {
  if RUN_STATUS.load(Ordering::Relaxed) {
    return Err(anyhow::Error::msg("Server already running!"));
  }
  RUN_STATUS.store(true, Ordering::Relaxed);

  let mut runtime_storage = RUNTIME.lock().unwrap();

  if runtime_storage.is_some() {
    return Err(anyhow::Error::msg("Runtime already created!"));
  }

  let runtime = mobile_init::create_runtime(sink.clone())
    .expect("Runtime should work, otherwise we can't function.");

  if ENGINE_NOTIFIER.get().is_none() {
    info!("Creating notifier");
    ENGINE_NOTIFIER
      .set(Arc::new(Notify::new()))
      .expect("We already checked creation so this shouldn't fail");
  } else {
    info!("Notifier already created");
  }

  let frontend = Arc::new(FlutterIntifaceEngineFrontend::new(
    sink.clone(),
    ENGINE_BROADCASTER.clone(),
  ));
  info!("Frontend logging set up.");
  let frontend_waiter = frontend.notify_on_creation();
  let engine = Arc::new(IntifaceEngine::default());
  let engine_clone = engine.clone();
  let engine_clone_clone = engine.clone();
  let notify = ENGINE_NOTIFIER.get().expect("Should be set").clone();
  let notify_clone = notify.clone();
  let notify_clone_clone = notify.clone();
  let options = args.into();

  let mut backdoor_incoming = BACKDOOR_INCOMING_BROADCASTER.subscribe();
  let outgoing_sink = sink.clone();
  let sink_clone = sink.clone();

  // TODO This is not doing what its supposed to. We're taking our Arc from the read guard, then
  // just dropping the read guard.
  let dcm = (*DEVICE_CONFIG_MANAGER.read().unwrap()).clone();
  runtime.spawn(
    async move {
      info!("Entering main join.");

      tokio::join!(
        // Backdoor server task
        async move {
          // Once we finish our waiter, continue. If we cancel the server run before then, just kill the
          // task.
          info!("Entering backdoor waiter task");
          select! {
            _ = frontend_waiter => {
              // This firing means the frontend is set up, and we just want to continue to creating our backdoor server.
            }
            _ = notify_clone.notified() => {
              return;
            }
          };
          // At this point we know we'll have a server.
          let backdoor_server = if let Some(backdoor_server) = engine_clone.backdoor_server() {
            backdoor_server
          } else {
            // If we somehow *don't* have a server here, something has gone very wrong. Just die.
            return;
          };
          let backdoor_server_stream = backdoor_server.event_stream();
          pin_mut!(backdoor_server_stream);
          loop {
            select! {
              msg = backdoor_incoming.recv() => {
                match msg {
                  Ok(msg) => {
                    //let runtime = RUNTIME.get().expect("Runtime not initialized");
                    let sink = outgoing_sink.clone();
                    let backdoor_server_clone = backdoor_server.clone();
                    tokio::spawn(async move {
                      sink.add(backdoor_server_clone.parse_message(&msg).await);
                    });
                  }
                  Err(_) => break
                }
              },
              outgoing = backdoor_server_stream.next() => {
                match outgoing {
                  Some(msg) => { sink.add(msg); }
                  None => break
                }
              },
              _ = notify_clone.notified() => break
            }
          }
          info!("Exiting backdoor waiter task");
        }
        .instrument(info_span!("IC Backdoor server task")),
        // Main engine task.
        async move {
          info!("Entering main engine waiter task");
          if let Err(e) = engine.run(&options, Some(frontend), &Some(dcm)).await {
            error!("Error running engine: {:?}", e);
          }
          info!("Exiting main engine waiter task");
          notify_clone_clone.notify_waiters();
        }.instrument(info_span!("IC main engine task")),
        // Our notifier needs to run in a task by itself, because we don't want our engine future to get
        // cancelled, so we can't select between it and the notifier. It needs to shutdown gracefully.
        async move {
          info!("Entering engine stop notification task");
          notify.notified().await;
          info!("Notifier called, stopping engine");
          engine_clone_clone.stop();
        }
      );
      RUN_STATUS.store(false, Ordering::Relaxed);
      sink_clone.close();
      info!("Exiting main join.");
    }
    .instrument(info_span!("IC main engine task")),
  );
  *runtime_storage = Some(runtime);
  Ok(())
}

pub fn send(msg_json: String) {
  let msg: IntifaceMessage = serde_json::from_str(&msg_json).unwrap();
  if ENGINE_BROADCASTER.receiver_count() > 0 {
    ENGINE_BROADCASTER
      .send(msg)
      .expect("This should be infallible since we already checked for receivers");
  }
}

pub fn stop_engine() {
  info!("Stop engine called in rust.");
  if let Some(notifier) = ENGINE_NOTIFIER.get() {
    notifier.notify_waiters();
  }
  // Need to park ourselves real quick to let the other runtime threads finish out.
  //
  // HACK The android JNI drop calls (and sometimes windows UWP calls) are slow (100ms+) and need
  // quite a while to get everything disconnected if there are currently connected devices. If they
  // don't run to completion, the runtime won't shutdown properly and everything will stall. Running
  // runtime_shutdown() doesn't work here because these are all tasks that may be stalled at the OS
  // level so we don't have enough info. Waiting on this is not the optimal way to do it, but I also
  // don't have a good way to know when shutdown is finished right now. So waiting it is. 1s isn't
  // super noticable from an UX standpoint.
  thread::sleep(Duration::from_millis(500));
  let runtime;
  {
    runtime = RUNTIME.lock().unwrap().take();
  }
  if let Some(rt) = runtime {
    info!("Shutting down runtime");
    rt.shutdown_timeout(Duration::from_secs(1));
    info!("Runtime shutdown complete");
  }
  RUN_STATUS.store(false, Ordering::Relaxed);
}

pub fn send_backend_server_message(msg: String) {
  if BACKDOOR_INCOMING_BROADCASTER.receiver_count() > 0 {
    BACKDOOR_INCOMING_BROADCASTER
      .send(msg)
      .expect("This should be infallible since we already checked for receivers");
  }
}



// "Exposed" types are mirrors of internal Buttplug types, but with all public members and typing
// that's amiable to FlutterRustBridge translation. These types can't be directly mirrored because
// the library itself has private members.
//
// "But don't you own the library also?" I mean, yes, I do, but I cannot emotionally handle bringing
// myself to set the struct members public there just for this application. I hate having ethics.

#[derive(Debug, Clone)]
pub struct ExposedUserDeviceIdentifier {
  pub address: String,
  pub protocol: String,
  pub identifier: Option<String>,
}

impl From<UserDeviceIdentifier> for ExposedUserDeviceIdentifier {
  fn from(value: UserDeviceIdentifier) -> Self {
    Self {
      address: value.address().clone(),
      protocol: value.protocol().clone(),
      identifier: value.identifier().clone()
    }
  }
}

impl Into<UserDeviceIdentifier> for ExposedUserDeviceIdentifier {
  fn into(self) -> UserDeviceIdentifier {
    UserDeviceIdentifier::new(&self.address, &self.protocol, &self.identifier)
  }
}


#[derive(Debug, Clone)]
pub struct ExposedSerialSpecifier {
  pub baud_rate: u32,
  pub data_bits: u8,
  pub stop_bits: u8,
  pub parity: String,
  pub port: String,
}

impl From<SerialSpecifier> for ExposedSerialSpecifier {
  fn from(value: SerialSpecifier) -> Self {
    Self {
      port: value.port().clone(),
      parity: value.parity().clone().into(),
      baud_rate: value.baud_rate().clone(),
      data_bits: value.data_bits().clone(),
      stop_bits: value.stop_bits().clone()
    }
  }
}

impl Into<SerialSpecifier> for ExposedSerialSpecifier {
  fn into(self) -> SerialSpecifier {
    SerialSpecifier::new(&self.port, self.baud_rate, self.data_bits, self.stop_bits, self.parity.chars().next().unwrap())
  }
}

#[derive(Debug, Clone)]
pub struct ExposedWebsocketSpecifier {
  pub name: String,
}

impl From<WebsocketSpecifier> for ExposedWebsocketSpecifier {
  fn from(value: WebsocketSpecifier) -> Self {
    Self {
      name: value.name().clone()
    }
  }
}

impl Into<WebsocketSpecifier> for ExposedWebsocketSpecifier {
  fn into(self) -> WebsocketSpecifier {
    WebsocketSpecifier::new(&self.name)
  }
}

#[derive(Debug, Clone)]
pub struct ExposedDeviceFeatureActuator {
  pub step_range: (u32, u32),
  pub step_limit: (u32, u32),
  pub messages: Vec<ButtplugActuatorFeatureMessageType>,
}

impl From<DeviceFeatureActuator> for ExposedDeviceFeatureActuator {
  fn from(value: DeviceFeatureActuator) -> Self {
    Self {
      step_range: (*value.step_range().start(), *value.step_range().end()),
      step_limit: (*value.step_limit().start(), *value.step_limit().end()),
      messages: value.messages().iter().cloned().collect()
    }
  }
}

impl Into<DeviceFeatureActuator> for ExposedDeviceFeatureActuator {
  fn into(self) -> DeviceFeatureActuator {
    DeviceFeatureActuator::new(
      &RangeInclusive::new(self.step_range.0, self.step_range.1), 
      &RangeInclusive::new(self.step_limit.0, self.step_limit.1), 
      &HashSet::from_iter(self.messages.iter().cloned())
    )
  }
}

#[derive(Debug, Clone)]
pub struct ExposedDeviceFeatureSensor
{
  pub value_range: Vec<(i32, i32)>,
  pub messages: Vec<ButtplugSensorFeatureMessageType>,
}

impl From<DeviceFeatureSensor> for ExposedDeviceFeatureSensor {
  fn from(value: DeviceFeatureSensor) -> Self {
    Self {
      value_range: value.value_range().iter().map(|val| (*val.start(), *val.end())).collect(),
      messages: value.messages().iter().cloned().collect()
    }
  }
}

impl Into<DeviceFeatureSensor> for ExposedDeviceFeatureSensor {
  fn into(self) -> DeviceFeatureSensor {
    DeviceFeatureSensor::new(
      &self.value_range.iter().map(|val| RangeInclusive::new(val.0, val.1)).collect(),
      &HashSet::from_iter(self.messages.iter().cloned())
    )
  }
}

#[derive(Debug, Clone)]
pub struct ExposedDeviceFeature {
  pub description: String,
  pub feature_type: FeatureType,
  pub actuator: Option<ExposedDeviceFeatureActuator>,
  pub sensor: Option<ExposedDeviceFeatureSensor>,
  // Leave out raw here, we'll never need it in the UI anyways
}

impl From<DeviceFeature> for ExposedDeviceFeature {
  fn from(value: DeviceFeature) -> Self {
    Self {
      description: value.description().clone(),
      feature_type: *value.feature_type(),
      actuator: value.actuator().clone().and_then(|x| Some(ExposedDeviceFeatureActuator::from(x))),
      sensor: value.sensor().clone().and_then(|x| Some(ExposedDeviceFeatureSensor::from(x)))
    }
  }
}

impl Into<DeviceFeature> for ExposedDeviceFeature {
  fn into(self) -> DeviceFeature {
    DeviceFeature::new(
      &self.description, 
      self.feature_type,
      &self.actuator.and_then(|x| Some(x.into())), 
      &self.sensor.and_then(|x| Some(x.into())))
  }
}

pub struct ExposedUserDeviceCustomization {
  pub display_name: Option<String>,
  pub allow: bool,
  pub deny: bool,
  pub index: u32,
}

impl From<UserDeviceCustomization> for ExposedUserDeviceCustomization {
  fn from(value: UserDeviceCustomization) -> Self {
    Self {
      display_name: value.display_name().clone(),
      allow: value.allow(),
      deny: value.deny(),
      index: value.index()
    }
  }
}

impl Into<UserDeviceCustomization> for ExposedUserDeviceCustomization {
  fn into(self) -> UserDeviceCustomization {
    UserDeviceCustomization::new(
      &self.display_name.clone(),
      self.allow,
      self.deny,
      self.index
    )
  }
}

pub struct ExposedUserDeviceDefinition {
  pub name: String,
  pub features: Vec<ExposedDeviceFeature>,
  pub user_config: ExposedUserDeviceCustomization,
}

impl From<UserDeviceDefinition> for ExposedUserDeviceDefinition {
  fn from(value: UserDeviceDefinition) -> Self {
    Self {
      name: value.name().clone(),
      features: value.features().iter().cloned().map(|x| x.into()).collect(),
      user_config: value.user_config().clone().into()
    }
  }
}

impl Into<UserDeviceDefinition> for ExposedUserDeviceDefinition {
  fn into(self) -> UserDeviceDefinition {
    UserDeviceDefinition::new(
      &self.name, 
      &self.features.iter().cloned().map(|x| x.into()).collect::<Vec<DeviceFeature>>(), 
      &self.user_config.into())
  }
}

#[frb(mirror(FeatureType))]
pub enum _FeatureType {
  Unknown,
  Vibrate,
  // Single Direction Rotation Speed
  Rotate,
  Oscillate,
  Constrict,
  Inflate,
  // For instances where we specify a position to move to ASAP. Usually servos, probably for the
  // OSR-2/SR-6.
  Position,
  // Sensor Types
  Battery,
  RSSI,
  Button,
  Pressure,
  // Currently unused but possible sensor features:
  // Temperature,
  // Accelerometer,
  // Gyro,
  //
  // Raw Feature, for when raw messages are on
  Raw,
}

#[frb(mirror(ButtplugActuatorFeatureMessageType))]
pub enum _ButtplugActuatorFeatureMessageType {
  ScalarCmd,
  RotateCmd,
  LinearCmd
}

#[frb(mirror(ButtplugSensorFeatureMessageType))]
pub enum _ButtplugSensorFeatureMessageType {
  SensorReadCmd,
  SensorSubscribeCmd,
}

#[frb(mirror(Endpoint))]
pub enum _Endpoint {
  Command,
  Firmware,
  Rx,
  RxAccel,
  RxBLEBattery,
  RxBLEModel,
  RxPressure,
  RxTouch,
  Tx,
  TxMode,
  TxShock,
  TxVibrate,
  TxVendorControl,
  Whitelist,
  Generic0,
  Generic1,
  Generic2,
  Generic3,
  Generic4,
  Generic5,
  Generic6,
  Generic7,
  Generic8,
  Generic9,
  Generic10,
  Generic11,
  Generic12,
  Generic13,
  Generic14,
  Generic15,
  Generic16,
  Generic17,
  Generic18,
  Generic19,
  Generic20,
  Generic21,
  Generic22,
  Generic23,
  Generic24,
  Generic25,
  Generic26,
  Generic27,
  Generic28,
  Generic29,
  Generic30,
  Generic31,
}

#[frb(mirror(ButtplugDeviceMessageType))]
pub enum _ButtplugDeviceMessageType {
  VibrateCmd,
  LinearCmd,
  RotateCmd,
  StopDeviceCmd,
  RawWriteCmd,
  RawReadCmd,
  RawSubscribeCmd,
  RawUnsubscribeCmd,
  BatteryLevelCmd,
  RSSILevelCmd,
  ScalarCmd,
  SensorReadCmd,
  SensorSubscribeCmd,
  SensorUnsubscribeCmd,
  // Deprecated generic commands
  SingleMotorVibrateCmd,
  // Deprecated device specific commands
  FleshlightLaunchFW12Cmd,
  LovenseCmd,
  KiirooCmd,
  VorzeA10CycloneCmd,
}

pub fn setup_device_configuration_manager(base_config: Option<String>, user_config: Option<String>) {
  if let Ok(mut dcm) = DEVICE_CONFIG_MANAGER.try_write() {
    *dcm = Arc::new(load_protocol_configs(&base_config, &user_config, false).unwrap().finish().unwrap());
  }
}

pub fn get_user_websocket_communication_specifiers() -> Vec<(String, ExposedWebsocketSpecifier)> {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  let mut ws_specs = vec!();
  for kv in dcm.user_communication_specifiers() {
    for comm_spec in kv.value() {
      if let ProtocolCommunicationSpecifier::Websocket(ws) = comm_spec {
        ws_specs.push((kv.key().to_owned(), ExposedWebsocketSpecifier::from(ws.clone())))
      }  
    }
  }
  ws_specs
}

pub fn get_user_serial_communication_specifiers() -> Vec<(String, ExposedSerialSpecifier)> {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  let mut port_specs = vec!();
  for kv in dcm.user_communication_specifiers() {
    for comm_spec in kv.value() {
      if let ProtocolCommunicationSpecifier::Serial(port) = comm_spec {
        port_specs.push((kv.key().to_owned(), ExposedSerialSpecifier::from(port.clone())))
      }  
    }
  }
  port_specs
}

pub fn get_user_device_definitions() -> Vec<(ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition)> {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm
    .user_device_definitions()
    .iter()
    .map(|kv| (kv.key().clone().into(), kv.value().clone().into()))
    .collect()  
}

pub fn get_protocol_names() -> Vec<String> {
  get_default_protocol_map()
    .keys()
    .into_iter()
    .cloned()
    .collect()
}

pub fn add_websocket_specifier(protocol: String, name: String) {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm.add_user_communication_specifier(&protocol, &ProtocolCommunicationSpecifier::Websocket(WebsocketSpecifier::new(&name)));
}

pub fn remove_websocket_specifier(protocol: String, name: String) {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm.remove_user_communication_specifier(&protocol, &ProtocolCommunicationSpecifier::Websocket(WebsocketSpecifier::new(&name)));
}

pub fn add_serial_specifier(protocol: String, port: String, baud_rate: u32, data_bits: u8, stop_bits: u8, parity: String) {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm.add_user_communication_specifier(&protocol, &ProtocolCommunicationSpecifier::Serial(SerialSpecifier::new(&port, baud_rate, data_bits, stop_bits, parity.chars().next().unwrap())));
}

pub fn remove_serial_specifier(protocol: String, port: String) {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm.remove_user_communication_specifier(&protocol, &ProtocolCommunicationSpecifier::Serial(SerialSpecifier::new_from_name(&port)));
}

pub fn update_user_config(identifier: ExposedUserDeviceIdentifier, config: ExposedUserDeviceDefinition) {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm.add_user_device_definition(&identifier.into(), &config.into());
}

pub fn remove_user_config(identifier: ExposedUserDeviceIdentifier) {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  dcm.remove_user_device_definition(&identifier.into());
}

pub fn get_user_config_str() -> String {
  let dcm = DEVICE_CONFIG_MANAGER.try_read().expect("We should have a reader at this point");
  save_user_config(&dcm).unwrap()
}

pub fn setup_logging(sink: StreamSink<String>) {
  // Default log to debug, we'll filter in UI if we need it.
  std::env::set_var(
    "RUST_LOG",
    format!("debug,h2=warn,reqwest=warn,rustls=warn,hyper=warn"),
  );
  *LOGGER.lock().unwrap() = Some(FlutterTracingWriter::new(sink));
}

pub fn shutdown_logging() {
  *LOGGER.lock().unwrap() = None;
}

pub fn crash_reporting(sentry_api_key: String) {
  // Set up Sentry
  info!("Initializing native crash reporting.");
  let _ = CRASH_REPORTING.set(sentry::init((
    sentry_api_key,
    sentry::ClientOptions {
      release: sentry::release_name!(),
      ..Default::default()
    },
  )));
  info!("Native crash reporting initialized");
}