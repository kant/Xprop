#import "XPRPopupMenuPlugin.h"
#import "JRSwizzle.h"

@implementation XPRPopupMenuPlugin {
    NSMenuItem *_XcodeMenuItem;
}

static XPRPopupMenuPlugin *XPRSharedPlugin = nil;

+ (void)pluginDidLoad:(NSBundle *)bundle
{
    // Plugin should be loaded only once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        XPRSharedPlugin = [[[self class] alloc] initWithBundle:bundle];
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

        // Add a custom menu item
        [self createXcodeMenuItem];
    }
    return self;
}

#pragma mark - Installation

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

#pragma mark - Settings

NSString *const XPRHidesProperiesFromDocumentItems = @"XPRHidesProperiesFromDocumentItems";

- (BOOL)hidesPropertiesFromDocumentItems
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:XPRHidesProperiesFromDocumentItems];
}

- (void)setHidesPropertiesFromDocumentItems:(BOOL)hidesPropertiesFromDocumentItems
{
    [[NSUserDefaults standardUserDefaults] setBool:hidesPropertiesFromDocumentItems forKey:XPRHidesProperiesFromDocumentItems];
    [self resetMenuItem];
}

#pragma mark - Xcode menu

- (void)createXcodeMenuItem
{
    // Add separator after the last menu item
    NSMenuItem *viewMenuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
    NSMenuItem *standardEditorItem = [viewMenuItem.submenu itemWithTitle:@"Standard Editor"];
    NSMenu *standardItemsMenu = standardEditorItem.submenu;
    [standardItemsMenu addItem:[NSMenuItem separatorItem]];

    // Add the toggle menu item in the bottom
    _XcodeMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(toggleProperties:) keyEquivalent:@""];
    _XcodeMenuItem.target = self;
    [standardItemsMenu addItem:_XcodeMenuItem];
    [self resetMenuItem];
}

- (void)toggleProperties:(id)sender
{
    self.hidesPropertiesFromDocumentItems = !self.hidesPropertiesFromDocumentItems;
}

- (void)resetMenuItem
{
    _XcodeMenuItem.title = (self.hidesPropertiesFromDocumentItems
                             ? NSLocalizedString(@"Show Properties in Document Items", @"Menu title for showing properties and synthesizers")
                             : NSLocalizedString(@"Hide Properties from Document Items", @"Menu title for hiding properties and synthesizers"));
}

@end

#pragma mark - Hacking

@implementation NSObject (XPR_Swizzling)

- (void)XPR_populatePopUpMenu:(NSMenu *)menu withItems:(NSArray *)items
{
    // First, Xcode fills the popup menu with default document items
    [self XPR_populatePopUpMenu:menu withItems:items];

    // Do not modify menu if the plugin is disabled
    if (!XPRSharedPlugin.hidesPropertiesFromDocumentItems) return;

    // Retrieve sibling cells to check out self position
    NSArray *cells = nil;
    @try { cells = [self valueForKeyPath:@"delegate.navBar.pathControl.pathComponentCells"]; } @catch (NSException *exception) { }

    // We should hide properties only in the last Document Items cell
    if (cells.lastObject != self) return;

    // Next, we hide properties and synthesizers from the popup menu
    for (NSMenuItem *menuItem in menu.itemArray) {

        // Pragma mark items have no image, leave them in place
        if (menuItem.image == nil) continue;

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

        // Also, we disable the item to skip it when using keys Up and Down
        [menuItem setEnabled:NO];
    }
}

@end
