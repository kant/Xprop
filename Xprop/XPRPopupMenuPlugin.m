#import "XPRPopupMenuPlugin.h"
#import "JRSwizzle.h"

@implementation XPRPopupMenuPlugin

+ (void)pluginDidLoad:(NSBundle *)bundle
{
    // Plugin should be loaded only once
    static id shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[[self class] alloc] initWithBundle:bundle];
    });
}

#pragma mark -

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    self = [super init];
    if (self) {

        // Override behavior of the menu available on Control-6
        NSError *swizzleError = nil;
        if ([self replaceXcodeImplementationWithError:&swizzleError])
            NSLog(@"%@ successfully loaded", [self pluginNameWithBundle:bundle]);
        else
            NSLog(@"Cannot load %@: %@", [self pluginNameWithBundle:bundle], swizzleError);
    }
    return self;
}

#pragma mark -

- (NSString *)pluginNameWithBundle:(NSBundle *)bundle
{
    NSString *pluginName = [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension];
    NSString *shortVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *build = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ %@ (%@)", pluginName, shortVersion, build];
}

- (BOOL)replaceXcodeImplementationWithError:(NSError **)outError
{
    // Replace -[IDEPathCell populatePopUpMenu:withItems:] with custom implementation
    return [NSClassFromString(@"IDEPathCell") jr_swizzleMethod:@selector(populatePopUpMenu:withItems:)
                                                    withMethod:@selector(XPR_populatePopUpMenu:withItems:) error:outError];
}

@end

#pragma mark -

@implementation NSObject (XPR_Swizzling)

- (void)XPR_populatePopUpMenu:(NSMenu *)menu withItems:(NSArray *)items
{
    // First, Xcode fills the popup menu with default document items
    [self XPR_populatePopUpMenu:menu withItems:items];

    // Next, we hide properties and synthesizers from the popup menu
    for (NSMenuItem *menuItem in menu.itemArray) {

        // Leave all separators in place
        id navigableItem = menuItem.representedObject;
        NSString *itemTitle = ([navigableItem respondsToSelector:@selector(name)] ? [navigableItem performSelector:@selector(name)] : nil);
        if (itemTitle.length == 0) continue;

        // Check the first symbol, it should be special
        if ([itemTitle hasPrefix:@"+"] || [itemTitle hasPrefix:@"-"] || [itemTitle hasPrefix:@"@"]) continue;

        // Now menuItem should be removed from the popup menu. However, its represented objects is observable.
        // As result, we cannot use [menu removeItem:menuItem]. The method [menuItem setHidden:NO] does not work.
        // So, we make an item invisible by setting its custom view to the empty object. This works like a charm.
        [menuItem setView:[[[NSView alloc] initWithFrame:CGRectZero] autorelease]];
    }
}

@end
