#import "Xprop.h"
#import "JRSwizzle.h"

@interface NSObject (XPR_swizzle)

- (void)XPR_populatePopUpMenu:(NSMenu *)menu withItems:(NSArray *)items;

@end

#pragma mark -

@implementation Xprop

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[[self class] alloc] initWithPlugin:plugin];
    });
}

#pragma mark -

- (instancetype)initWithPlugin:(NSBundle *)plugin
{
    // Replace menu popup method with the custom one
    NSError *swizzleError = nil;
    if (![NSClassFromString(@"IDEPathCell") jr_swizzleMethod:@selector(populatePopUpMenu:withItems:)
                                                  withMethod:@selector(XPR_populatePopUpMenu:withItems:) error:&swizzleError]) {
        NSLog(@"Cannot load plugin method: %@", swizzleError);
        return nil;
    }

    self = [super init];
    if (self) {

        // Notify about
        NSString *pluginName = [[[plugin bundlePath] lastPathComponent] stringByDeletingPathExtension];
        NSString *shortVersion = [plugin objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *build = [plugin objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSLog(@"%@ %@ (%@) successfully loaded", pluginName, shortVersion, build);
    }
    return self;
}

- (void)dealloc
{
    // Cleanup properly
    [super dealloc];
}

@end

#pragma mark -

@implementation NSObject (XPR_helpers)

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
        [menuItem setView:[[NSView alloc] initWithFrame:CGRectZero]];
    }
}

@end
