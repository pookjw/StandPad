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

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    SP_os_feature_enabled_impl::hook();

    [pool release];
}
