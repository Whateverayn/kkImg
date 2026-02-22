#import "KKThumbnailViewManager.h"
#import "KKThumbnailView.h"
#import <React/RCTUIManager.h>

@implementation KKThumbnailViewManager

RCT_EXPORT_MODULE(KKThumbnailView)

- (NSView *)view {
  return [[KKThumbnailView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(src, NSString)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, NSString)

@end
