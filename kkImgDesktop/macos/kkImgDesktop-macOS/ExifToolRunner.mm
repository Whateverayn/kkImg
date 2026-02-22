#import "ExifToolRunner.h"
#import <Foundation/Foundation.h>

@implementation ExifToolRunner

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

// Executes a shell command using NSTask and returns the stdout and stderr
RCT_REMAP_METHOD(executeCommand,
                 executeCommandWithArgs : (NSArray<NSString *> *)
                     args resolver : (RCTPromiseResolveBlock)
                         resolve rejecter : (RCTPromiseRejectBlock)reject) {
  if (!args || args.count == 0) {
    reject(@"invalid_args", @"Arguments array is empty", nil);
    return;
  }

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTask *task = [[NSTask alloc] init];

        // We assume exiftool is in the standard path. To be safe, we run it via
        // bash/zsh or directly if we know the full path. Since it's usually in
        // /usr/local/bin or /opt/homebrew/bin running via `/usr/bin/env` is a
        // standard way to wrap it.
        [task setLaunchPath:@"/usr/bin/env"];

        NSMutableArray *taskArgs = [NSMutableArray arrayWithObject:@"exiftool"];
        [taskArgs addObjectsFromArray:args];
        [task setArguments:taskArgs];

        NSPipe *outPipe = [NSPipe pipe];
        NSPipe *errPipe = [NSPipe pipe];
        [task setStandardOutput:outPipe];
        [task setStandardError:errPipe];

        @try {
          [task launch];

          NSFileHandle *outFile = [outPipe fileHandleForReading];
          NSFileHandle *errFile = [errPipe fileHandleForReading];

          NSData *outData = [outFile readDataToEndOfFile];
          NSData *errData = [errFile readDataToEndOfFile];

          [task waitUntilExit];

          NSString *outString =
              [[NSString alloc] initWithData:outData
                                    encoding:NSUTF8StringEncoding];
          NSString *errString =
              [[NSString alloc] initWithData:errData
                                    encoding:NSUTF8StringEncoding];

          int status = [task terminationStatus];

          if (status == 0) {
            resolve(@{
              @"stdout" : outString ? outString : @"",
              @"stderr" : errString ? errString : @""
            });
          } else {
            // Exiftool can sometimes return non-zero even on partial success,
            // but we treat it as an error here We'll pass stdout in the
            // rejection's userInfo if needed
            NSString *errorMsg = [NSString
                stringWithFormat:@"ExifTool exited with status %d: %@", status,
                                 errString];
            NSError *error = [NSError
                errorWithDomain:@"ExifToolError"
                           code:status
                       userInfo:@{@"stdout" : outString ? outString : @""}];
            reject([NSString stringWithFormat:@"%d", status], errorMsg, error);
          }
        } @catch (NSException *exception) {
          reject(@"launch_failed",
                 [NSString stringWithFormat:@"Failed to launch ExifTool: %@",
                                            exception.reason],
                 nil);
        }
      });
}

@end
