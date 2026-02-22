#import "KKThumbnailView.h"
#import <ImageIO/ImageIO.h>

@implementation KKThumbnailView

- (instancetype)init {
  if (self = [super initWithFrame:NSZeroRect]) {
    self.imageScaling = NSImageScaleProportionallyUpOrDown;
  }
  return self;
}

- (void)setResizeMode:(NSString *)resizeMode {
  if (_resizeMode != resizeMode) {
    _resizeMode = [resizeMode copy];
    if ([resizeMode isEqualToString:@"cover"]) {
      self.imageScaling = NSImageScaleAxesIndependently;
    } else if ([resizeMode isEqualToString:@"contain"]) {
      self.imageScaling = NSImageScaleProportionallyUpOrDown;
    } else if ([resizeMode isEqualToString:@"stretch"]) {
      self.imageScaling = NSImageScaleAxesIndependently;
    } else if ([resizeMode isEqualToString:@"center"]) {
      self.imageScaling = NSImageScaleNone;
    } else {
      self.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
  }
}

- (void)setSrc:(NSString *)src {
  if (_src != src) {
    _src = [src copy];
    [self loadImage];
  }
}

- (void)loadImage {
  if (!self.src || self.src.length == 0) {
    self.image = nil;
    return;
  }

  // Handle both file:// URLs and raw paths
  NSString *path = [self.src stringByReplacingOccurrencesOfString:@"file://"
                                                       withString:@""];
  NSURL *fileURL = [NSURL fileURLWithPath:path];

  // Fast path: use NSWorkspace iconForFile if it's super small, or
  // CGImageSourceCreateThumbnailAtIndex for actual image content matching
  // aspect ratio. We'll use CGImageSource for high-quality, aspect-correct
  // thumbnails.

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef thumbnail = NULL;
        CGImageSourceRef imageSource =
            CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);

        if (imageSource) {
          // Create thumbnail options: Max dimension 1024 to keep memory low but
          // look crisp, create from image ALWAYS (don't rely on potentially
          // missing embedded thumb).
          NSDictionary *options = @{
            (id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
            (id)kCGImageSourceThumbnailMaxPixelSize : @1024,
            (id)kCGImageSourceCreateThumbnailWithTransform :
                @YES // Respect EXIF orientation!
          };

          thumbnail = CGImageSourceCreateThumbnailAtIndex(
              imageSource, 0, (__bridge CFDictionaryRef)options);
          CFRelease(imageSource);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          if (thumbnail) {
            NSImage *image = [[NSImage alloc] initWithCGImage:thumbnail
                                                         size:NSZeroSize];
            self.image = image;
            CGImageRelease(thumbnail);
          } else {
            // Fallback to file icon if image cannot be read
            self.image = [[NSWorkspace sharedWorkspace] iconForFile:path];
          }
        });
      });
}

@end
