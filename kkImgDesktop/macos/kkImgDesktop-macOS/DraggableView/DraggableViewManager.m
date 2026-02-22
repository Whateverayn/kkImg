#import "DraggableViewManager.h"
#import "DraggableView.h"

@implementation DraggableViewManager

RCT_EXPORT_MODULE()

RCT_EXPORT_VIEW_PROPERTY(fileUrls, NSArray)
RCT_EXPORT_VIEW_PROPERTY(onDragEnd, RCTBubblingEventBlock)

- (NSView *)view {
  return [[DraggableView alloc] init];
}

@end
