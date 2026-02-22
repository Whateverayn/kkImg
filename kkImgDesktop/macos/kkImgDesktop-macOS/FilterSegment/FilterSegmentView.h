#import <AppKit/AppKit.h>
#import <React/RCTComponent.h>
#import <React/RCTView.h>

@interface FilterSegmentView : RCTView

/// Array of NSString labels, e.g. @["Any", "Has", "None"]
@property(nonatomic, copy) NSArray<NSString *> *options;

/// Currently selected segment index (0-based). Set to -1 for no selection.
@property(nonatomic, assign) NSInteger selectedIndex;

/// Fired when user selects a segment. Payload: { selectedIndex: number }
@property(nonatomic, copy) RCTBubblingEventBlock onSegmentChange;

@end
