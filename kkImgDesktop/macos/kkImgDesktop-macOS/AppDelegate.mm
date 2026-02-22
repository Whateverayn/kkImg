#import "AppDelegate.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTEventEmitter.h>

// Import Swift bridging header (Xcode auto-generates this for the target)
#import "kkImgDesktop-Swift.h"

@interface ToolbarEmitter : RCTEventEmitter <RCTBridgeModule>
+ (void)emitViewModeChanged:(NSString *)mode;
+ (void)emitAppModeChanged:(NSString *)mode;
+ (void)emitInspectorStateChanged:(NSDictionary *)state;
+ (void)emitFilterToggled:(BOOL)isActive;
+ (void)emitSelectAll;
+ (void)emitRemoveSelected;
+ (void)emitRollupWindow:(BOOL)rollUp;
+ (void)emitMoveUp:(BOOL)shift;
+ (void)emitMoveDown:(BOOL)shift;
@end

@implementation ToolbarEmitter

RCT_EXPORT_MODULE();

static ToolbarEmitter *sharedInstance = nil;

- (instancetype)init {
  self = [super init];
  if (self) {
    sharedInstance = self;
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[
    @"onViewModeChanged", @"onAppModeChanged", @"onInspectorStateChanged",
    @"onFilterToggled", @"onSelectAll", @"onRemoveSelected", @"onRollupWindow",
    @"onMoveUp", @"onMoveDown"
  ];
}

+ (void)emitViewModeChanged:(NSString *)mode {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onViewModeChanged"
                                 body:@{@"mode" : mode}];
  }
}

+ (void)emitInspectorStateChanged:(NSDictionary *)state {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onInspectorStateChanged" body:state];
  }
}

+ (void)emitAppModeChanged:(NSString *)mode {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onAppModeChanged"
                                 body:@{@"mode" : mode}];
  }
}

+ (void)emitFilterToggled:(BOOL)isActive {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onFilterToggled"
                                 body:@{@"isActive" : @(isActive)}];
  }
}

+ (void)emitSelectAll {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onSelectAll" body:@{}];
  }
}

+ (void)emitRemoveSelected {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onRemoveSelected" body:@{}];
  }
}

+ (void)emitRollupWindow:(BOOL)rollUp {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onRollupWindow"
                                 body:@{@"rollUp" : @(rollUp)}];
  }
}

+ (void)emitMoveUp:(BOOL)shift {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onMoveUp" body:@{@"shift" : @(shift)}];
  }
}

+ (void)emitMoveDown:(BOOL)shift {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onMoveDown"
                                 body:@{@"shift" : @(shift)}];
  }
}

@end

@interface ToggleSegmentedControl : NSSegmentedControl
@end

@implementation ToggleSegmentedControl
- (void)mouseDown:(NSEvent *)event {
  NSInteger preClick = self.selectedSegment;
  [super mouseDown:event];

  NSPoint mouseLoc = [self.window mouseLocationOutsideOfEventStream];
  NSPoint localPoint = [self convertPoint:mouseLoc fromView:nil];
  BOOL isInside = NSPointInRect(localPoint, self.bounds);

  if (isInside && self.selectedSegment == preClick && preClick != -1) {
    self.selectedSegment = -1;
    [self sendAction:self.action to:self.target];
  }
}
@end

@interface HoverTrafficLightButton : NSButton
@property(nonatomic, assign) BOOL isHovering;
@end

@implementation HoverTrafficLightButton

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    self.bordered = NO;
    self.title = @"";
  }
  return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
  [super viewWillMoveToWindow:newWindow];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (newWindow) {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(windowStateChanged:)
               name:NSWindowDidBecomeKeyNotification
             object:newWindow];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(windowStateChanged:)
               name:NSWindowDidResignKeyNotification
             object:newWindow];
  }
}

- (void)windowStateChanged:(NSNotification *)notif {
  [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas {
  [super updateTrackingAreas];
  for (NSTrackingArea *area in self.trackingAreas) {
    [self removeTrackingArea:area];
  }
  NSTrackingAreaOptions options =
      NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited;
  NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                      options:options
                                                        owner:self
                                                     userInfo:nil];
  [self addTrackingArea:area];
}

- (void)mouseEntered:(NSEvent *)event {
  self.isHovering = YES;
  [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event {
  self.isHovering = NO;
  [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
  [super mouseDown:event];
  [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event {
  [super mouseUp:event];

  // Fix hover getting stuck if mouse is released outside
  NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
  if (!NSPointInRect(location, self.bounds)) {
    self.isHovering = NO;
  }

  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
  BOOL isActive = [self.window isKeyWindow];
  BOOL isDark = [self.effectiveAppearance.name containsString:@"Dark"];

  // Custom draw the traffic light to perfectly mimic macOS 11+ window buttons
  NSRect rect = NSMakeRect(0, 0, 14, 14);
  NSBezierPath *path =
      [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 0.5, 0.5)];

  if (isActive) {
    if (self.cell.isHighlighted) {
      [[NSColor colorWithSRGBRed:0.25 green:0.25 blue:0.25 alpha:1.0] setFill];
      [[NSColor colorWithWhite:0.0 alpha:0.3] setStroke];
    } else {
      // System Gray close to Apple's standard "custom" traffic lights
      [[NSColor colorWithSRGBRed:0.56 green:0.58 blue:0.6 alpha:1.0] setFill];
      [[NSColor colorWithWhite:0.0 alpha:0.12] setStroke];
    }
  } else {
    // Perfect inactive window traffic light colors
    NSColor *inactiveFill = isDark ? [NSColor colorWithWhite:0.31 alpha:1.0]
                                   : [NSColor colorWithWhite:0.86 alpha:1.0];
    NSColor *inactiveStroke = isDark ? [NSColor colorWithWhite:0.0 alpha:0.2]
                                     : [NSColor colorWithWhite:0.0 alpha:0.12];
    [inactiveFill setFill];
    [inactiveStroke setStroke];
  }

  [path fill];
  [path stroke];

  if (self.isHovering) {
    NSImage *icon = [NSImage imageWithSystemSymbolName:@"square.split.1x2"
                              accessibilityDescription:nil];
    if (icon) {
      [icon setTemplate:YES];
      NSColor *tintColor =
          isActive ? [NSColor colorWithWhite:0.1 alpha:0.75]
                   : (isDark ? [NSColor colorWithWhite:0.6 alpha:0.75]
                             : [NSColor colorWithWhite:0.4 alpha:0.75]);

      NSRect imgRect = NSMakeRect(
          2.5, 2.5, 9, 9); // Size the symbol carefully inside the 14px circle

      [icon lockFocus];
      [tintColor set];
      NSRectFillUsingOperation(
          NSMakeRect(0, 0, icon.size.width, icon.size.height),
          NSCompositingOperationSourceAtop);
      [icon unlockFocus];

      [icon drawInRect:imgRect
              fromRect:NSZeroRect
             operation:NSCompositingOperationSourceOver
              fraction:1.0];
    }
  }
}
@end

@interface AppDelegate () <NSToolbarDelegate>
@property(nonatomic, strong) NSProgressIndicator *toolbarProgressIndicator;
@property(nonatomic, assign) BOOL isInspectorOpen;
@property(nonatomic, assign) NSInteger currentInspectorTab;
@property(nonatomic, assign) CGFloat preRollupHeight;
@end

@implementation AppDelegate

- (void)selectAll:(id)sender {
  [ToolbarEmitter emitSelectAll];
}

// Called by Edit > Delete (standard macOS responder chain)
- (void)delete:(id)sender {
  [ToolbarEmitter emitRemoveSelected];
}

// These are called by the standard macOS moveUp:/moveDown: responder chain
// (triggered by NSApplication passing up/down arrow key events)
- (void)moveUp:(id)sender {
  [ToolbarEmitter emitMoveUp:NO];
}

- (void)moveDown:(id)sender {
  [ToolbarEmitter emitMoveDown:NO];
}

- (void)removeSelected:(id)sender {
  [ToolbarEmitter emitRemoveSelected];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  self.isInspectorOpen = YES;
  self.currentInspectorTab = 0;

  self.moduleName = @"kkImgDesktop";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  [super applicationDidFinishLaunching:notification];

  self.window.titleVisibility = NSWindowTitleHidden;
  self.window.titlebarAppearsTransparent = NO;
  self.window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;

  // Setup Progress Indicator (Donut style)
  self.toolbarProgressIndicator =
      [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];
  self.toolbarProgressIndicator.style =
      NSProgressIndicatorStyleSpinning; // This makes it circular
  self.toolbarProgressIndicator.controlSize = NSControlSizeSmall;
  self.toolbarProgressIndicator.displayedWhenStopped = YES; // Force visibility
  self.toolbarProgressIndicator.indeterminate = NO;         // Determinate donut
  self.toolbarProgressIndicator.maxValue = 100.0;
  self.toolbarProgressIndicator.doubleValue = 0.0;

  NSToolbar *toolbar =
      [[NSToolbar alloc] initWithIdentifier:@"kkImgToolbar_v3"];
  toolbar.delegate = self;
  toolbar.displayMode = NSToolbarDisplayModeIconOnly;
  self.window.toolbar = toolbar;

  // --- Custom Titlebar Button Injection ---
  NSWindow *mainWindow = NSApplication.sharedApplication.mainWindow;
  if (!mainWindow)
    mainWindow = NSApplication.sharedApplication.windows.firstObject;

  if (mainWindow) {
    NSButton *zoomButton = [mainWindow standardWindowButton:NSWindowZoomButton];
    if (zoomButton) {
      NSView *titleBarView = zoomButton.superview;
      if (titleBarView) {
        // HIJACK the standard miniaturize (Yellow) button to perform our custom
        // Rollup action
        NSButton *miniaturizeButton =
            [mainWindow standardWindowButton:NSWindowMiniaturizeButton];
        if (miniaturizeButton) {
          miniaturizeButton.enabled = YES;
          miniaturizeButton.target = self;
          miniaturizeButton.action = @selector(toggleRollupMode:);
        }
      }
    }
  } // End of titlebar setup

  // --- Wire Preferences... (Cmd+,) to Settings Tab ---
  NSMenu *mainMenu = [NSApplication sharedApplication].mainMenu;
  NSMenu *appMenu = mainMenu.itemArray.firstObject.submenu;
  if (appMenu) {
    for (NSMenuItem *item in appMenu.itemArray) {
      if ([item.keyEquivalent isEqualToString:@","]) {
        item.target = self;
        item.action = @selector(showSettings:);
      }
    }
  }

  // --- Inject custom items into the Edit menu ---
  // Find the Edit menu (index 2 in standard macOS apps)
  NSMenuItem *editMenuItem = nil;
  for (NSMenuItem *item in mainMenu.itemArray) {
    if ([item.title isEqualToString:@"Edit"]) {
      editMenuItem = item;
      break;
    }
  }
  if (editMenuItem) {
    NSMenu *editMenu = editMenuItem.submenu;
    // xcstrings handles the display strings
    // We just wire the delete: action to the Delete menu item (backspace key)
    for (NSMenuItem *item in editMenu.itemArray) {
      if (([item.keyEquivalent isEqualToString:@"\x08"] ||
           [item.keyEquivalent isEqualToString:@"\x7f"]) &&
          item.keyEquivalentModifierMask == 0) {
        item.action = @selector(delete:);
        item.target = self;
      }
    }
  }

  // Global key event monitor for arrow keys
  [NSEvent
      addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                   handler:^NSEvent *(NSEvent *event) {
                                     NSResponder *firstResponder =
                                         NSApplication.sharedApplication
                                             .keyWindow.firstResponder;
                                     BOOL isTextField =
                                         [firstResponder
                                             isKindOfClass:[NSTextView
                                                               class]] ||
                                         [firstResponder
                                             isKindOfClass:[NSTextField class]];
                                     if (!isTextField) {
                                       BOOL shiftHeld =
                                           (event.modifierFlags &
                                            NSEventModifierFlagShift) != 0;
                                       if (event.keyCode == 126) { // Up arrow
                                         [ToolbarEmitter emitMoveUp:shiftHeld];
                                         return nil;
                                       } else if (event.keyCode ==
                                                  125) { // Down arrow
                                         [ToolbarEmitter
                                             emitMoveDown:shiftHeld];
                                         return nil;
                                       }
                                     }
                                     return event;
                                   }];

} // <- Correctly close applicationDidFinishLaunching

- (void)toggleRollupMode:(id)sender {
  NSWindow *window = NSApplication.sharedApplication.mainWindow;
  if (!window)
    return;

  NSRect frame = window.frame;
  CGFloat compactHeight = 85.0; // Just enough for titlebar + toolbar

  if (frame.size.height > compactHeight + 10) {
    // Roll up
    self.preRollupHeight = frame.size.height;
    frame.origin.y += frame.size.height - compactHeight;
    frame.size.height = compactHeight;
  } else {
    // Unroll
    CGFloat targetHeight =
        self.preRollupHeight > 0 ? self.preRollupHeight : 700.0;
    frame.origin.y -= targetHeight - frame.size.height;
    frame.size.height = targetHeight;
  }
  [window setFrame:frame display:YES animate:YES];
}

- (void)rollUpForDrag {
  NSWindow *window = NSApplication.sharedApplication.mainWindow;
  if (!window)
    return;

  NSRect frame = window.frame;
  CGFloat compactHeight = 85.0;

  if (frame.size.height > compactHeight + 10) {
    // Only roll up if not already rolled up
    self.preRollupHeight = frame.size.height;
    frame.origin.y += frame.size.height - compactHeight;
    frame.size.height = compactHeight;
    [window setFrame:frame display:YES animate:YES];
  }
}

- (void)unrollAfterDrag {
  NSWindow *window = NSApplication.sharedApplication.mainWindow;
  if (!window)
    return;

  // Only unroll if we have a remembered height (meaning we rolled up for a
  // drag)
  if (self.preRollupHeight > 0) {
    NSRect frame = window.frame;
    CGFloat targetHeight = self.preRollupHeight;
    frame.origin.y -= targetHeight - frame.size.height;
    frame.size.height = targetHeight;
    [window setFrame:frame display:YES animate:YES];
  }
}

// NSToolbarDelegate Methods
- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:
    (NSToolbar *)toolbar {
  return @[
    @"AppModeSegment", @"ViewModeSegment", @"InspectorTabsSegment",
    @"ProgressItem", NSToolbarFlexibleSpaceItemIdentifier
  ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:
    (NSToolbar *)toolbar {
  return @[
    @"AppModeSegment", NSToolbarFlexibleSpaceItemIdentifier, @"ViewModeSegment",
    NSToolbarFlexibleSpaceItemIdentifier, @"ProgressItem",
    @"InspectorTabsSegment"
  ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
        itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag {
  if ([itemIdentifier isEqualToString:@"AppModeSegment"]) {
    NSToolbarItem *item =
        [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    NSSegmentedControl *segmentedControl = [NSSegmentedControl
        segmentedControlWithLabels:@[ @"Metadata", @"AVIF", @"Hash" ]
                      trackingMode:NSSegmentSwitchTrackingSelectOne
                            target:self
                            action:@selector(appModeChanged:)];
    segmentedControl.selectedSegment = 0; // Default: Metadata
    item.view = segmentedControl;
    item.minSize = NSMakeSize(210, 24);
    return item;
  } else if ([itemIdentifier isEqualToString:@"ViewModeSegment"]) {
    NSToolbarItem *item =
        [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    NSSegmentedControl *segmentedControl = [NSSegmentedControl
        segmentedControlWithLabels:@[ @"List", @"Gallery" ]
                      trackingMode:NSSegmentSwitchTrackingSelectOne
                            target:self
                            action:@selector(viewModeChanged:)];
    segmentedControl.selectedSegment = 0;
    item.view = segmentedControl;
    item.minSize = NSMakeSize(140, 24);
    return item;
  } else if ([itemIdentifier isEqualToString:@"InspectorTabsSegment"]) {
    NSToolbarItem *item =
        [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    ToggleSegmentedControl *segmentedControl = [ToggleSegmentedControl
        segmentedControlWithImages:@[
          [NSImage imageWithSystemSymbolName:@"info.circle"
                    accessibilityDescription:@"Info"],
          [NSImage
              imageWithSystemSymbolName:@"line.horizontal.3.decrease.circle"
               accessibilityDescription:@"Organize"],
          [NSImage imageWithSystemSymbolName:@"slider.horizontal.3"
                    accessibilityDescription:@"Settings"],
          [NSImage imageWithSystemSymbolName:@"list.bullet"
                    accessibilityDescription:@"Queue"]
        ]
                      trackingMode:NSSegmentSwitchTrackingSelectOne
                            target:self
                            action:@selector(inspectorTabChanged:)];

    if (self.isInspectorOpen) {
      segmentedControl.selectedSegment = self.currentInspectorTab;
    } else {
      segmentedControl.selectedSegment = -1;
    }

    [segmentedControl setWidth:56 forSegment:0];
    [segmentedControl setWidth:56 forSegment:1];
    [segmentedControl setWidth:56 forSegment:2];
    [segmentedControl setWidth:56 forSegment:3];

    item.view = segmentedControl;
    return item;
  } else if ([itemIdentifier isEqualToString:@"ProgressItem"]) {
    NSToolbarItem *item =
        [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    item.view = self.toolbarProgressIndicator;
    item.minSize = NSMakeSize(16, 16);
    item.maxSize = NSMakeSize(16, 16);
    return item;
  }
  return nil;
}

- (void)appModeChanged:(NSSegmentedControl *)sender {
  NSString *mode = @"metadata";
  if (sender.selectedSegment == 1)
    mode = @"avif";
  else if (sender.selectedSegment == 2)
    mode = @"hash";
  [ToolbarEmitter emitAppModeChanged:mode];
}

- (void)viewModeChanged:(NSSegmentedControl *)sender {
  NSString *mode = sender.selectedSegment == 0 ? @"list" : @"gallery";
  [ToolbarEmitter emitViewModeChanged:mode];
}

- (void)filterToggleChanged:(NSSegmentedControl *)sender {
  BOOL isActive = sender.selectedSegment == 0;
  [ToolbarEmitter emitFilterToggled:isActive];
}

- (void)inspectorTabChanged:(NSSegmentedControl *)sender {
  if (sender.selectedSegment == -1) {
    self.isInspectorOpen = NO;
  } else {
    self.isInspectorOpen = YES;
    self.currentInspectorTab = sender.selectedSegment;
  }

  NSString *tab = @"preview";
  if (self.currentInspectorTab == 1) {
    tab = @"organize";
  } else if (self.currentInspectorTab == 2) {
    tab = @"settings";
  } else if (self.currentInspectorTab == 3) {
    tab = @"queue";
  }

  [ToolbarEmitter emitInspectorStateChanged:@{
    @"isOpen" : @(self.isInspectorOpen),
    @"tab" : tab
  }];
}

- (void)showSettings:(id)sender {
  self.isInspectorOpen = YES;
  self.currentInspectorTab = 2; // Settings tab index

  NSWindow *mainWindow = NSApplication.sharedApplication.mainWindow;
  if (!mainWindow)
    mainWindow = NSApplication.sharedApplication.windows.firstObject;
  if (mainWindow && mainWindow.toolbar) {
    for (NSToolbarItem *item in mainWindow.toolbar.visibleItems) {
      if ([item.itemIdentifier isEqualToString:@"InspectorTabsSegment"]) {
        NSSegmentedControl *seg = (NSSegmentedControl *)item.view;
        seg.selectedSegment = 2;
        break;
      }
    }
  }

  [ToolbarEmitter
      emitInspectorStateChanged:@{@"isOpen" : @YES, @"tab" : @"settings"}];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
#if DEBUG
  return
      [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main"
                                 withExtension:@"jsbundle"];
#endif
}

/// This method controls whether the `concurrentRoot`feature of React18 is
/// turned on or off.
///
/// @see: https://reactjs.org/blog/2022/03/29/react-v18.html
/// @note: This requires to be rendering on Fabric (i.e. on the New
/// Architecture).
/// @return: `true` if the `concurrentRoot` feature is enabled. Otherwise, it
/// returns `false`.
- (BOOL)concurrentRootEnabled {
#ifdef RN_FABRIC_ENABLED
  return true;
#else
  return false;
#endif
}

@end

// Expose a Native Module to control the Progress Indicator from React
// Native
@interface ToolbarProgress : NSObject <RCTBridgeModule>
@end

@implementation ToolbarProgress

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

RCT_EXPORT_METHOD(setProgress : (double)progress) {
  dispatch_async(dispatch_get_main_queue(), ^{
    AppDelegate *appDelegate =
        (AppDelegate *)[NSApplication sharedApplication].delegate;
    if (appDelegate.toolbarProgressIndicator) {
      if (progress > 0 && progress < 100) {
        appDelegate.toolbarProgressIndicator.doubleValue = progress;
        appDelegate.toolbarProgressIndicator.hidden = NO;
      } else {
        appDelegate.toolbarProgressIndicator.doubleValue = 0;
      }
    }
  });
}

@end

// Import the MetadataReader module so it compiles as part of the AppDelegate
// translation unit
#import "DraggableView/DraggableView.m"
#import "DraggableView/DraggableViewManager.m"
#import "ExifToolRunner.mm"
#import "MetadataReader.mm"
