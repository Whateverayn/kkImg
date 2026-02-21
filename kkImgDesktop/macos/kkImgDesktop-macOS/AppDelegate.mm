#import "AppDelegate.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTEventEmitter.h>

@interface ToolbarEmitter : RCTEventEmitter <RCTBridgeModule>
+ (void)emitViewModeChanged:(NSString *)mode;
+ (void)emitToggleInspector;
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
  return @[ @"onViewModeChanged", @"onToggleInspector" ];
}

+ (void)emitViewModeChanged:(NSString *)mode {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onViewModeChanged"
                                 body:@{@"mode" : mode}];
  }
}

+ (void)emitToggleInspector {
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"onToggleInspector" body:@{}];
  }
}

@end

@interface AppDelegate () <NSToolbarDelegate>
@property(nonatomic, strong) NSProgressIndicator *toolbarProgressIndicator;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
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

  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"kkImgToolbar"];
  toolbar.delegate = self;
  toolbar.displayMode = NSToolbarDisplayModeIconOnly;
  self.window.toolbar = toolbar;
}

// NSToolbarDelegate Methods
- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:
    (NSToolbar *)toolbar {
  return @[
    @"ViewModeSegment", @"ToggleInspectorItem", @"ProgressItem",
    NSToolbarFlexibleSpaceItemIdentifier
  ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:
    (NSToolbar *)toolbar {
  // Put segment in center, progress and inspector toggle on the right.
  return @[
    NSToolbarFlexibleSpaceItemIdentifier, @"ViewModeSegment",
    NSToolbarFlexibleSpaceItemIdentifier, @"ProgressItem",
    @"ToggleInspectorItem"
  ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
        itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag {
  if ([itemIdentifier isEqualToString:@"ViewModeSegment"]) {
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
  } else if ([itemIdentifier isEqualToString:@"ToggleInspectorItem"]) {
    NSToolbarItem *item =
        [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    item.label = @"Inspector";
    item.paletteLabel = @"Inspector";
    item.toolTip = @"Show/Hide Inspector";

    // Use standard system SF Symbol for sidebar (if available, mostly >= 11.0)
    if (@available(macOS 11.0, *)) {
      item.image = [NSImage imageWithSystemSymbolName:@"sidebar.right"
                             accessibilityDescription:@"Toggle Inspector"];
    } else {
      item.image =
          [NSImage imageNamed:NSImageNameTouchBarGetInfoTemplate]; // Fallback
    }

    item.target = self;
    item.action = @selector(toggleInspector:);
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

- (void)viewModeChanged:(NSSegmentedControl *)sender {
  NSString *mode = sender.selectedSegment == 0 ? @"list" : @"gallery";
  [ToolbarEmitter emitViewModeChanged:mode];
}

- (void)toggleInspector:(NSToolbarItem *)sender {
  [ToolbarEmitter emitToggleInspector];
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

// Expose a Native Module to control the Progress Indicator from React Native
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
        appDelegate.toolbarProgressIndicator.hidden = YES;
      }
    }
  });
}

@end
