#import <AppKit/AppKit.h>
#import <React/RCTComponent.h>
#import <React/RCTView.h>

@interface DraggableView : RCTView <NSDraggingSource>

@property(nonatomic, copy) NSArray<NSString *> *fileUrls;
@property(nonatomic, copy) RCTBubblingEventBlock onDragEnd;

@end
