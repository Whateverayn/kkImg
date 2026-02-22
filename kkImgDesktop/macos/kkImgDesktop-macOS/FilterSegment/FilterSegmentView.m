#import "FilterSegmentView.h"

@interface FilterSegmentView ()
@property(nonatomic, strong) NSSegmentedControl *segmentedControl;
@end

@implementation FilterSegmentView

- (instancetype)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    _segmentedControl = [[NSSegmentedControl alloc] init];
    _segmentedControl.trackingMode = NSSegmentSwitchTrackingSelectOne;
    _segmentedControl.segmentStyle = NSSegmentStyleRounded;
    _segmentedControl.target = self;
    _segmentedControl.action = @selector(segmentChanged:);
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_segmentedControl];

    [NSLayoutConstraint activateConstraints:@[
      [_segmentedControl.leadingAnchor
          constraintEqualToAnchor:self.leadingAnchor],
      [_segmentedControl.trailingAnchor
          constraintEqualToAnchor:self.trailingAnchor],
      [_segmentedControl.centerYAnchor
          constraintEqualToAnchor:self.centerYAnchor],
    ]];
  }
  return self;
}

- (void)setOptions:(NSArray<NSString *> *)options {
  _options = options;
  _segmentedControl.segmentCount = options.count;
  for (NSInteger i = 0; i < options.count; i++) {
    [_segmentedControl setLabel:options[i] forSegment:i];
  }
  // Restore selection after rebuilding segments
  _segmentedControl.selectedSegment = _selectedIndex;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
  _selectedIndex = selectedIndex;
  _segmentedControl.selectedSegment = selectedIndex;
}

- (void)segmentChanged:(NSSegmentedControl *)sender {
  _selectedIndex = sender.selectedSegment;
  if (self.onSegmentChange) {
    self.onSegmentChange(@{@"selectedIndex" : @(sender.selectedSegment)});
  }
}

@end
