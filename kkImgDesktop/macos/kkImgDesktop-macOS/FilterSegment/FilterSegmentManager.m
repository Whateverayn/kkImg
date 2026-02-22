#import "FilterSegmentManager.h"
#import "FilterSegmentView.h"

@implementation FilterSegmentManager

RCT_EXPORT_MODULE(FilterSegment)

RCT_EXPORT_VIEW_PROPERTY(options, NSArray)
RCT_EXPORT_VIEW_PROPERTY(selectedIndex, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onSegmentChange, RCTBubblingEventBlock)

- (NSView *)view {
  return [[FilterSegmentView alloc] init];
}

@end
