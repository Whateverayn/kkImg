#import "MetadataReader.h"
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

@implementation MetadataReader

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

RCT_EXPORT_METHOD(extractBasicMetadata : (NSString *)filePath resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  if (!filePath || filePath.length == 0) {
    reject(@"invalid_path", @"File path is empty", nil);
    return;
  }

  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
  if (!fileURL) {
    reject(@"invalid_path", @"Could not create file URL", nil);
    return;
  }

  // Create image source
  CGImageSourceRef imageSource =
      CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
  if (!imageSource) {
    reject(@"read_error",
           @"Failed to read image source. It may not be a valid image.", nil);
    return;
  }

  // Get properties
  CFDictionaryRef imageProperties =
      CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
  if (!imageProperties) {
    CFRelease(imageSource);
    reject(@"no_properties", @"No image properties found", nil);
    return;
  }

  NSDictionary *properties = (__bridge_transfer NSDictionary *)imageProperties;

  // Prepare result dictionary
  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  // Extract Orientation
  NSNumber *orientation = properties[(NSString *)kCGImagePropertyOrientation];
  BOOL swapDimensions = NO;
  if (orientation) {
    NSInteger o = [orientation integerValue];
    if (o >= 5 && o <= 8) {
      swapDimensions = YES;
    }
  }

  // Extract Dimensions (Width & Height)
  NSNumber *width = properties[(NSString *)kCGImagePropertyPixelWidth];
  NSNumber *height = properties[(NSString *)kCGImagePropertyPixelHeight];
  if (width && height) {
    if (swapDimensions) {
      result[@"width"] = height;
      result[@"height"] = width;
    } else {
      result[@"width"] = width;
      result[@"height"] = height;
    }
  } else {
    if (width)
      result[@"width"] = width;
    if (height)
      result[@"height"] = height;
  }

  // Extract Dates
  NSDictionary *exif = properties[(NSString *)kCGImagePropertyExifDictionary];
  NSDictionary *tiff = properties[(NSString *)kCGImagePropertyTIFFDictionary];

  NSString *dateStr = nil;
  if (exif && exif[(NSString *)kCGImagePropertyExifDateTimeOriginal]) {
    dateStr = exif[(NSString *)kCGImagePropertyExifDateTimeOriginal];
  } else if (exif && exif[(NSString *)kCGImagePropertyExifDateTimeDigitized]) {
    dateStr = exif[(NSString *)kCGImagePropertyExifDateTimeDigitized];
  } else if (tiff && tiff[(NSString *)kCGImagePropertyTIFFDateTime]) {
    dateStr = tiff[(NSString *)kCGImagePropertyTIFFDateTime];
  }

  if (dateStr) {
    // Parse EXIF date format "YYYY:MM:DD HH:MM:SS"
    NSDateFormatter *exifParser = [[NSDateFormatter alloc] init];
    exifParser.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    exifParser.dateFormat = @"yyyy:MM:dd HH:mm:ss";
    NSDate *date = [exifParser dateFromString:dateStr];

    if (date) {
      // Format with system locale (will use 和暦 if Japanese calendar is
      // active)
      NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
      displayFormatter.locale = [NSLocale currentLocale];
      displayFormatter.calendar = [NSCalendar currentCalendar];
      displayFormatter.dateStyle = NSDateFormatterMediumStyle;
      displayFormatter.timeStyle = NSDateFormatterShortStyle;
      result[@"date"] = [displayFormatter stringFromDate:date];
    } else {
      result[@"date"] = dateStr; // fallback to raw string
    }
  }

  // Detect GPS Presence
  NSDictionary *gps = properties[(NSString *)kCGImagePropertyGPSDictionary];
  if (gps && gps.count > 0) {
    result[@"hasGps"] = @(YES);
  } else {
    result[@"hasGps"] = @(NO);
  }

  // Determine File Size
  NSError *error = nil;
  NSDictionary *fileAttr =
      [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                       error:&error];
  if (fileAttr && !error) {
    result[@"fileSize"] = fileAttr[NSFileSize];
  }

  CFRelease(imageSource);
  resolve(result);
}

@end
