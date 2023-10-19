#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <execinfo.h>
#import <cstring>
#import <substrate.h>

BOOL isCalledFromMethod(Class cls, SEL name) {
    void *buffer[3];
    auto count = backtrace(buffer, 3);

    if (count < 3) {
        return NO;
    }

    auto addr = buffer[2];
    struct dl_info info;
    dladdr(addr, &info);

    auto baseAddr = class_getMethodImplementation(cls, name);

    return info.dli_saddr == baseAddr;
}

namespace SP_os_feature_enabled_impl {
    BOOL (*original)(const char *arg0, const char *arg1);
    BOOL custom(const char *arg0, const char *arg1) {
        if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "SuperDomino")) {
            return YES;
        } else if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "Domino")) {
            return YES;
        } else if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "Autobahn")) {
            return YES;
        } else if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "Maglev")) {
            return YES;
        } else {
            return original(arg0, arg1);
        }
    }

    void hook() {
        auto handle = dlopen("/usr/lib/system/libsystem_featureflags.dylib", RTLD_NOW);
        auto symbol = dlsym(handle, "_os_feature_enabled_impl");
        MSHookFunction(symbol, reinterpret_cast<void *>(&custom), reinterpret_cast<void **>(&original));
        dlclose(handle);
    }
}

namespace SP_SBFEffectiveDeviceClass {
    long (*original)();
    long custom() {
        if (isCalledFromMethod(NSClassFromString(@"SBAmbientPresentationController"), NSSelectorFromString(@"initWithWindowScene:"))) {
            return 0;
        } else {
            return original(); // 0x2 on iPadOS, 0x0 on iOS
        }
    }

    void hook() {
        auto handle = dlopen("/System/Library/PrivateFrameworks/SpringBoardFoundation.framework/SpringBoardFoundation", RTLD_NOW);
        auto symbol = dlsym(handle, "SBFEffectiveDeviceClass");
        MSHookFunction(symbol, reinterpret_cast<void *>(&custom), reinterpret_cast<void **>(&original));
        dlclose(handle);
    }
}

namespace SP_UIDevice {
    namespace userInterfaceIdiom {
        UIUserInterfaceIdiom (*original)(UIDevice *self, SEL _cmd);
        UIUserInterfaceIdiom custom(UIDevice *self, SEL _cmd) {
            if (isCalledFromMethod(NSClassFromString(@"SBAmbientPresentationController"), NSSelectorFromString(@"initWithWindowScene:"))) {
                return UIUserInterfaceIdiomPhone;
            } else {
                return original(self, _cmd);
            }
        }

        void hook() {
            MSHookMessageEx(
                UIDevice.class,
                @selector(userInterfaceIdiom),
                reinterpret_cast<IMP>(&custom),
                reinterpret_cast<IMP *>(&original)
            );
        }
    }
}

namespace SP_SBHomeHardwareButton {
    namespace doublePressDown {
        void custom(id self, SEL _cmd, UIPressesEvent *event) {
            [UIApplication.sharedApplication.connectedScenes enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:NSClassFromString(@"SBWindowScene")]) {
                    auto windowScene = reinterpret_cast<__kindof UIWindowScene *>(obj);

                    // SBAmbientPresentationController
                    id controller = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(windowScene, NSSelectorFromString(@"ambientPresentationController"));

                    auto isPresented = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(controller, NSSelectorFromString(@"isPresented"));
                    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(controller, NSSelectorFromString(@"_setPresented:"), !isPresented);
                }
            }];
        }

        void hook() {
            MSHookMessageEx(
                NSClassFromString(@"SBHomeHardwareButton"),
                NSSelectorFromString(@"doublePressDown:"),
                reinterpret_cast<IMP>(&custom),
                nullptr
            );
        }
    }
}

namespace SP_SBAmbientPresentationController {
    namespace isAlwaysOnPolicyActive {
        BOOL custom(id self, SEL _cmd) {
            return YES;
        }

        void hook() {
            MSHookMessageEx(
                NSClassFromString(@"SP_SBAmbientPresentationController"),
                NSSelectorFromString(@"isAlwaysOnPolicyActive"),
                reinterpret_cast<IMP>(&custom),
                nullptr
            );
        }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    SP_os_feature_enabled_impl::hook();
    SP_SBFEffectiveDeviceClass::hook();
    SP_UIDevice::userInterfaceIdiom::hook();
    SP_SBHomeHardwareButton::doublePressDown::hook();
    SP_SBAmbientPresentationController::isAlwaysOnPolicyActive::hook();

    [pool release];
}
