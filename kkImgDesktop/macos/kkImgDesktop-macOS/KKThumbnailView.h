#import <Cocoa/Cocoa.h>
#import <React/RCTComponent.h>

@interface KKThumbnailView : NSImageView

@property(nonatomic, copy) NSString *src;
@property(nonatomic, copy) NSString *resizeMode;

@end
