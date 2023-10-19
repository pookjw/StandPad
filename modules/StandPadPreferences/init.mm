#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <substrate.h>

namespace SP_PSUIPrefsListController {
    namespace viewDidLoad {
        void (*original)(__kindof UIViewController *self, SEL _cmd);
        void custom(__kindof UIViewController *self, SEL _cmd) {
            original(self, _cmd);

            NSMutableArray<UIBarButtonItemGroup *> *trailingItemGroups = [self.navigationItem.trailingItemGroups mutableCopy];

            __block auto unretainedSelf = self;
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithPrimaryAction:[UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"moon.stars.circle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                __kindof UIViewController *viewController = [NSClassFromString(@"AMAmbientSettingsDetailController") new];
                [unretainedSelf presentViewController:viewController animated:YES completion:nil];
                [viewController release];
            }]];
            
            UIBarButtonItemGroup *group = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[item] representativeItem:nil];
            [item release];
            
            [trailingItemGroups addObject:group];
            [group release];
            
            self.navigationItem.trailingItemGroups = trailingItemGroups;
            [trailingItemGroups release];
        }

        void hook() {
            MSHookMessageEx(
                NSClassFromString(@"PSUIPrefsListController"),
                NSSelectorFromString(@"viewDidLoad"),
                reinterpret_cast<IMP>(&custom),
                reinterpret_cast<IMP *>(&original)
            );
        }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    dlopen("/System/Library/PreferenceBundles/AmbientSettings.bundle/AmbientSettings", RTLD_NOW);
    SP_PSUIPrefsListController::viewDidLoad::hook();

    [pool release];
}
