//
//  Xprop.m
//  Xprop
//
//  Created by Vadim on 4/17/13.
//  Copyright (c) 2013 Shpakovski. All rights reserved.
//

#import "Xprop.h"

@implementation Xprop


+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

- (id)init
{
    if (self = [super init]) {
        // Create menu items, initialize UI, etc.

        // Sample Menu Item:
        NSMenuItem *viewMenuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
        if (viewMenuItem) {
            [[viewMenuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *sample = [[[NSMenuItem alloc] initWithTitle:@"Do Action" action:@selector(doMenuAction) keyEquivalent:@""] autorelease];
            [sample setTarget:self];
            [[viewMenuItem submenu] addItem:sample];
        }
    }
    return self;
}

// Sample Action, for menu item:
- (void) doMenuAction
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Hello, World" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end