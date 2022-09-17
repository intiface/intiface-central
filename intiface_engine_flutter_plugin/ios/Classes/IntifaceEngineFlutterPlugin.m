#import "IntifaceEngineFlutterPlugin.h"
#if __has_include(<intiface_engine_flutter_plugin/intiface_engine_flutter_plugin-Swift.h>)
#import <intiface_engine_flutter_plugin/intiface_engine_flutter_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "intiface_engine_flutter_plugin-Swift.h"
#endif

@implementation IntifaceEngineFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIntifaceEngineFlutterPlugin registerWithRegistrar:registrar];
}
@end
