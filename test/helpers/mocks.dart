import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_repository.dart';
import 'package:intiface_central/bloc/engine/engine_provider.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/bloc/util/network_info_cubit.dart';
import 'package:intiface_central/src/rust/frb_generated.dart';
import 'package:buttplug/buttplug.dart';

// Provider/repository mocks
class MockEngineProvider extends Mock implements EngineProvider {}

class MockEngineRepository extends Mock implements EngineRepository {}

// BLoC/Cubit mocks
class MockEngineControlBloc
    extends MockBloc<EngineControlEvent, EngineControlState>
    implements EngineControlBloc {}

class MockDeviceManagerBloc
    extends MockBloc<DeviceManagerEvent, DeviceManagerState>
    implements DeviceManagerBloc {}

class MockNavigationCubit extends MockCubit<NavigationPage>
    implements NavigationCubit {}

class MockUpdateBloc extends MockBloc<UpdateEvent, UpdateState>
    implements UpdateBloc {}

class MockErrorNotifierCubit extends MockCubit<ErrorNotifierState>
    implements ErrorNotifierCubit {}

class MockIntifaceConfigurationCubit
    extends MockCubit<IntifaceConfigurationState>
    implements IntifaceConfigurationCubit {}

class MockGuiSettingsCubit extends MockCubit<GuiSettingsState>
    implements GuiSettingsCubit {}

class MockUserDeviceConfigurationCubit
    extends MockCubit<UserDeviceConfigurationState>
    implements UserDeviceConfigurationCubit {}

class MockAssetCubit extends MockCubit<AssetEvent> implements AssetCubit {}

class MockNetworkInfoCubit extends MockCubit<NetworkInfoState>
    implements NetworkInfoCubit {}

class MockDeviceCubit extends MockCubit<DeviceState> implements DeviceCubit {}

// FFI mocks
class MockRustLibApi extends Mock implements RustLibApi {}

class MockButtplugClientDevice extends Mock implements ButtplugClientDevice {}
