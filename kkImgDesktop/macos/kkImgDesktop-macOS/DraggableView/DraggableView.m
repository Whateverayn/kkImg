#import "DraggableView.h"
#import <React/UIView+React.h>

// Forward declaration to trigger rollup from AppDelegate
@interface AppDelegate (RollupExtension)
- (void)rollUpForDrag;
- (void)unrollAfterDrag;
@end

@interface DraggableView ()
@property(nonatomic, assign) NSPoint mouseDownPoint;
@property(nonatomic, assign) BOOL hasDragStarted;
@end

@implementation DraggableView

- (instancetype)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    _hasDragStarted = NO;
  }
  return self;
}

- (void)mouseDown:(NSEvent *)event {
  [super mouseDown:event];
  self.mouseDownPoint = [event locationInWindow];
  self.hasDragStarted = NO;
}

- (void)mouseDragged:(NSEvent *)event {
  NSPoint currentLoc = [event locationInWindow];
  CGFloat dx = currentLoc.x - self.mouseDownPoint.x;
  CGFloat dy = currentLoc.y - self.mouseDownPoint.y;
  CGFloat distance = sqrt(dx * dx + dy * dy);

  // Require at least 3 pixels of movement to trigger a drag
  if (distance < 3.0) {
    return;
  }

  if (!self.fileUrls || self.fileUrls.count == 0) {
    return;
  }

  NSMutableArray<NSDraggingItem *> *dragItems = [NSMutableArray array];

  for (NSString *urlString in self.fileUrls) {
    NSURL *url = [NSURL fileURLWithPath:urlString];
    if (!url)
      continue;

    NSDraggingItem *dragItem =
        [[NSDraggingItem alloc] initWithPasteboardWriter:url];

    // Generate a simple dragged image (icon)
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:urlString];
    if (!icon) {
      icon = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
    }

    NSRect imageRect = NSMakeRect(0, 0, icon.size.width, icon.size.height);
    [dragItem setDraggingFrame:imageRect contents:icon];

    [dragItems addObject:dragItem];
  }

  if (dragItems.count > 0 && !self.hasDragStarted) {
    self.hasDragStarted = YES;
    // Auto-rollup the window when a drag starts
    AppDelegate *delegate =
        (AppDelegate *)[NSApplication sharedApplication].delegate;
    if ([delegate respondsToSelector:@selector(rollUpForDrag)]) {
      [delegate rollUpForDrag];
    }
    [self beginDraggingSessionWithItems:dragItems event:event source:self];
  }
}

// MARK: - NSDraggingSource

- (NSDragOperation)draggingSession:(NSDraggingSession *)session
    sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
  // Allow Copy or Move (depending on modifier keys during the drag)
  return NSDragOperationCopy | NSDragOperationMove | NSDragOperationLink;
}

- (void)draggingSession:(NSDraggingSession *)session
           endedAtPoint:(NSPoint)screenPoint
              operation:(NSDragOperation)operation {
  // Restore window after drag ends (auto-rollup reversal)
  AppDelegate *delegate =
      (AppDelegate *)[NSApplication sharedApplication].delegate;
  if ([delegate respondsToSelector:@selector(unrollAfterDrag)]) {
    [delegate unrollAfterDrag];
  }
  self.hasDragStarted = NO;

  // If files were moved (or deleted) fire the onDragEnd event so JS can remove
  // them from the list
  if ((operation & (NSDragOperationMove | NSDragOperationDelete)) &&
      self.onDragEnd && self.fileUrls.count > 0) {
    self.onDragEnd(
        @{@"movedUrls" : self.fileUrls, @"operation" : @(operation)});
  }
}

@end
