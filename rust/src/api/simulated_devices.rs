use anyhow::Result;
use buttplug_server_device_config::{
    SimulatedDeviceArchetype, SimulatedDeviceConfigEntry, SimulatedDeviceFeatureSummary,
};

use crate::api::device_config_manager::DEVICE_CONFIG_MANAGER;

#[derive(Debug, Clone)]
pub struct ExposedSimulatedDeviceConfigEntry {
    pub identifier: String,
    pub display_name: Option<String>,
    pub address: String,
}

impl From<SimulatedDeviceConfigEntry> for ExposedSimulatedDeviceConfigEntry {
    fn from(value: SimulatedDeviceConfigEntry) -> Self {
        Self {
            identifier: value.identifier().clone(),
            display_name: value.display_name().clone(),
            address: value.address().clone(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ExposedSimulatedDeviceArchetype {
    pub identifier: String,
    pub display_name: String,
    pub output_features: Vec<ExposedSimulatedDeviceFeatureSummary>,
}

impl From<SimulatedDeviceArchetype> for ExposedSimulatedDeviceArchetype {
    fn from(value: SimulatedDeviceArchetype) -> Self {
        Self {
            identifier: value.identifier,
            display_name: value.display_name,
            output_features: value
                .output_features
                .into_iter()
                .map(ExposedSimulatedDeviceFeatureSummary::from)
                .collect(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ExposedSimulatedDeviceFeatureSummary {
    pub description: String,
    pub output_type: String,
    pub index: u32,
}

impl From<SimulatedDeviceFeatureSummary> for ExposedSimulatedDeviceFeatureSummary {
    fn from(value: SimulatedDeviceFeatureSummary) -> Self {
        Self {
            description: value.description,
            output_type: value.output_type,
            index: value.index,
        }
    }
}

pub fn get_available_simulated_archetypes() -> Vec<ExposedSimulatedDeviceArchetype> {
    let dcm = DEVICE_CONFIG_MANAGER
        .try_read()
        .expect("We should have a reader at this point");
    dcm.available_simulated_archetypes()
        .into_iter()
        .map(ExposedSimulatedDeviceArchetype::from)
        .collect()
}

pub fn get_user_simulated_devices() -> Vec<ExposedSimulatedDeviceConfigEntry> {
    let dcm = DEVICE_CONFIG_MANAGER
        .try_read()
        .expect("We should have a reader at this point");
    dcm.simulated_devices()
        .into_iter()
        .map(ExposedSimulatedDeviceConfigEntry::from)
        .collect()
}

pub fn add_simulated_device(identifier: String, display_name: Option<String>) -> Result<()> {
    let dcm = DEVICE_CONFIG_MANAGER
        .try_read()
        .expect("We should have a reader at this point");
    dcm.add_simulated_device(SimulatedDeviceConfigEntry::new(&identifier, display_name))
        .map_err(|e| anyhow::anyhow!(format!("{:?}", e)))
}

pub fn remove_simulated_device(address: String) {
    let dcm = DEVICE_CONFIG_MANAGER
        .try_read()
        .expect("We should have a reader at this point");
    dcm.remove_simulated_device(&address);
}
