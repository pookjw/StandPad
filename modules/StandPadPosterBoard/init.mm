#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <cstring>
#import <substrate.h>

namespace SP_os_feature_enabled_impl {
    BOOL (*original)(const char *arg0, const char *arg1);
    BOOL custom(const char *arg0, const char *arg1) {
        if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "SuperDomino")) {
            return YES;
        } else if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "Domino")) {
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

namespace SP_PRPosterAmbientConfiguration {
    namespace setHidden {
        void (*original)(id self, SEL _cmd, BOOL arg0);
        void custom(id self, SEL _cmd, BOOL arg0) {
            original(self, _cmd, NO);
        }

        void hook() {
            MSHookMessageEx(
                NSClassFromString(@"PRPosterAmbientConfiguration"),
                NSSelectorFromString(@"setHidden:"),
                reinterpret_cast<IMP>(&custom),
                reinterpret_cast<IMP *>(&original)
            );
        }
    }

    namespace hidden {
        BOOL custom(id self, SEL _cmd) {
            return NO;
        }

        void hook() {
            MSHookMessageEx(
                NSClassFromString(@"PRPosterAmbientConfiguration"),
                NSSelectorFromString(@"hidden"),
                reinterpret_cast<IMP>(&custom),
                nullptr
            );
        }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    SP_os_feature_enabled_impl::hook();
    SP_PRPosterAmbientConfiguration::setHidden::hook();
    SP_PRPosterAmbientConfiguration::hidden::hook();

    [pool release];
}
