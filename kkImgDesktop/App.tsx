import React, { useState } from 'react';
import {
  SafeAreaView,
  StyleSheet,
  Text,
  View,
  FlatList,
  PlatformColor,
  Alert,
  NativeEventEmitter,
  NativeModules,
  Animated,
  Easing,
  TouchableOpacity,
  LayoutAnimation,
} from 'react-native';

const { ToolbarEmitter, ToolbarProgress } = NativeModules;
const toolbarEmitter = new NativeEventEmitter(ToolbarEmitter);

const mockData = [
  { id: '1', name: 'IMG_20230101.jpg', date: '2023-01-01 10:23:45', size: '2.4 MB', hasXmp: true },
  { id: '2', name: 'IMG_20230102.jpg', date: '2023-01-02 14:10:02', size: '3.1 MB', hasXmp: false },
  { id: '3', name: 'DSC00123.raw', date: '2023-01-05 09:45:11', size: '24.5 MB', hasXmp: true },
  { id: '4', name: 'Untitled.png', date: 'No Date', size: '1.2 MB', hasXmp: false }, // "日付のないファイルの炙り出し"
  { id: '5', name: 'IMG_20230106.jpg', date: '2023-01-06 11:20:00', size: '2.8 MB', hasXmp: true },
];

function App(): React.JSX.Element {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'list' | 'gallery'>('list');

  // App Layout State
  const [showInspector, setShowInspector] = useState(true);

  // Progress Sheet State
  const [isProcessing, setIsProcessing] = useState(false);

  // Toggle Inspector from toolbar (Native event to trigger show/hide)
  React.useEffect(() => {
    const subscription = toolbarEmitter.addListener(
      'onToggleInspector',
      () => {
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setShowInspector(prev => !prev);
      }
    );
    return () => subscription.remove();
  }, []);

  React.useEffect(() => {
    // Listen for the native toolbar segment changes
    const subscription = toolbarEmitter.addListener(
      'onViewModeChanged',
      (event: { mode: 'list' | 'gallery' }) => {
        setViewMode(event.mode);
      }
    );

    return () => {
      subscription.remove();
    };
  }, []);

  const testProgress = () => {
    setIsProcessing(true);
    ToolbarProgress.setProgress(5);
    let currentProgress = 5;
    const interval = setInterval(() => {
      currentProgress += Math.random() * 15;
      if (currentProgress >= 100) {
        ToolbarProgress.setProgress(100);
        clearInterval(interval);
        setTimeout(() => {
          ToolbarProgress.setProgress(0);
          setIsProcessing(false);
        }, 500);
      } else {
        ToolbarProgress.setProgress(currentProgress);
      }
    }, 200);
  };

  const handleDrop = (e: any) => {
    console.log('onDrop event fired!');
    console.log('event.nativeEvent.dataTransfer:', JSON.stringify(e.nativeEvent.dataTransfer, null, 2));

    // Extract URLs from various places depending on what React Native macOS passed
    let urls: string[] = [];
    if (e.nativeEvent.urls) {
      urls = e.nativeEvent.urls;
    } else if (e.nativeEvent.dataTransfer && e.nativeEvent.dataTransfer.files) {
      urls = e.nativeEvent.dataTransfer.files.map((f: any) => f.uri || f.path || f.name).filter(Boolean);
    }

    console.log('Extracted URLs:', urls);

    if (urls.length > 0) {
      // Simulate a background process
      setIsProcessing(true);

      // Initial progress 5%
      ToolbarProgress.setProgress(5);

      // Simulate progressing
      let currentProgress = 5;
      const interval = setInterval(() => {
        currentProgress += Math.random() * 15;
        if (currentProgress >= 100) {
          ToolbarProgress.setProgress(100);
          clearInterval(interval);
          setTimeout(() => {
            ToolbarProgress.setProgress(0); // Hide it
            setIsProcessing(false);
          }, 500);
        } else {
          ToolbarProgress.setProgress(currentProgress);
        }
      }, 200);
    } else {
      console.warn('No URLs found in drop event.');
    }
  };

  const selectedItem = mockData.find(item => item.id === selectedId);

  const renderItem = ({ item }: { item: typeof mockData[0] }) => {
    const isSelected = item.id === selectedId;
    const isMissingDate = item.date === 'No Date';

    return (
      <TouchableOpacity
        activeOpacity={1}
        onPress={() => setSelectedId(item.id)}
        style={[
          styles.row,
          isSelected && { backgroundColor: PlatformColor('selectedContentBackgroundColor') }
        ]}
      >
        <Text style={[styles.cell, styles.cellName, { color: isSelected ? PlatformColor('alternateSelectedControlTextColor') : PlatformColor('controlTextColor') }]}>
          {item.name}
        </Text>
        <Text style={[
          styles.cell,
          styles.cellDate,
          {
            color: isSelected ? PlatformColor('alternateSelectedControlTextColor') : (isMissingDate ? PlatformColor('systemOrangeColor') : PlatformColor('controlTextColor')),
            fontWeight: isMissingDate ? '600' : 'normal'
          }
        ]}>
          {item.date}
        </Text>
        <Text style={[styles.cell, styles.cellSize, { color: isSelected ? PlatformColor('alternateSelectedControlTextColor') : PlatformColor('secondaryLabelColor') }]}>
          {item.size}
        </Text>
        <Text style={[
          styles.cell,
          styles.cellXmp,
          { color: isSelected ? PlatformColor('alternateSelectedControlTextColor') : (item.hasXmp ? PlatformColor('systemGreenColor') : PlatformColor('secondaryLabelColor')) }
        ]}>
          {item.hasXmp ? 'Available (Diff)' : 'None'}
        </Text>
      </TouchableOpacity>
    );
  };

  return (
    <View
      style={styles.container}
      // @ts-ignore
      draggedTypes={['fileUrl']}
      onDrop={handleDrop}
      onDragEnter={() => console.log('Drag entered')}
      onDragOver={() => console.log('Drag over')}
      acceptsFirstMouse={true}
    >
      <View style={styles.splitContainer}>
        {/* LEFT PANE: Main Content */}
        <View
          style={styles.mainPane}
        >
          {viewMode === 'list' ? (
            <>
              <View style={styles.listHeader}>
                <Text style={[styles.columnHeader, styles.cellName]}>Filename</Text>
                <Text style={[styles.columnHeader, styles.cellDate]}>Date</Text>
                <Text style={[styles.columnHeader, styles.cellSize]}>Size</Text>
                <Text style={[styles.columnHeader, styles.cellXmp]}>XMP Metadata</Text>
              </View>

              <FlatList
                data={mockData}
                keyExtractor={item => item.id}
                renderItem={renderItem}
                contentContainerStyle={styles.listContent}
                ItemSeparatorComponent={() => <View style={styles.separator} />}
              />
            </>
          ) : (
            <View
              style={styles.galleryContainer}
            >
              <Text style={styles.galleryText}>Gallery View (Placeholder)</Text>
              <Text style={styles.gallerySubtext}>D&D support is active here too!</Text>
            </View>
          )}
        </View>

        {/* RIGHT PANE: Inspector (Preview & Metadata) */}
        {showInspector && (
          <View style={styles.inspectorPane}>
            {selectedItem ? (
              <View style={styles.inspectorContent}>
                <View style={styles.previewImagePlaceholder}>
                  <Text style={styles.previewPlaceholderText}>Image Preview</Text>
                </View>
                <Text style={styles.inspectorTitle}>{selectedItem.name}</Text>
                <View style={styles.metadataRow}>
                  <Text style={styles.metadataLabel}>Size:</Text>
                  <Text style={styles.metadataValue}>{selectedItem.size}</Text>
                </View>
                <View style={styles.metadataRow}>
                  <Text style={styles.metadataLabel}>Date:</Text>
                  <Text style={styles.metadataValue}>{selectedItem.date}</Text>
                </View>
                <View style={styles.metadataRow}>
                  <Text style={styles.metadataLabel}>XMP:</Text>
                  <Text style={styles.metadataValue}>{selectedItem.hasXmp ? 'Available' : 'None'}</Text>
                </View>
              </View>
            ) : (
              <View style={styles.inspectorEmpty}>
                <Text style={styles.inspectorEmptyText}>No item selected</Text>
              </View>
            )}
          </View>
        )}
      </View>

    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: PlatformColor('windowBackgroundColor'),
  },
  splitContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  mainPane: {
    flex: 1,
    backgroundColor: PlatformColor('controlBackgroundColor'),
  },
  inspectorPane: {
    width: 280,
    borderLeftWidth: StyleSheet.hairlineWidth,
    borderLeftColor: PlatformColor('separatorColor'),
    backgroundColor: PlatformColor('windowBackgroundColor'),
  },
  inspectorContent: {
    padding: 16,
  },
  previewImagePlaceholder: {
    width: '100%',
    aspectRatio: 1,
    backgroundColor: PlatformColor('underPageBackgroundColor'),
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  previewPlaceholderText: {
    color: PlatformColor('tertiaryLabelColor'),
    fontSize: 14,
  },
  inspectorTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: PlatformColor('labelColor'),
    marginBottom: 16,
  },
  metadataRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  metadataLabel: {
    flex: 1,
    color: PlatformColor('secondaryLabelColor'),
    fontSize: 12,
  },
  metadataValue: {
    flex: 2,
    color: PlatformColor('labelColor'),
    fontSize: 12,
  },
  inspectorEmpty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  inspectorEmptyText: {
    color: PlatformColor('tertiaryLabelColor'),
    fontSize: 13,
  },
  listHeader: {
    flexDirection: 'row',
    paddingVertical: 6,
    paddingHorizontal: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: PlatformColor('gridColor'),
    backgroundColor: PlatformColor('controlBackgroundColor'),
  },
  columnHeader: {
    fontWeight: '600',
    fontSize: 12,
    color: PlatformColor('secondaryLabelColor'),
  },
  listContent: {
    paddingBottom: 20,
    backgroundColor: PlatformColor('controlBackgroundColor'),
  },
  row: {
    flexDirection: 'row',
    paddingVertical: 6,
    paddingHorizontal: 16,
  },
  separator: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: PlatformColor('gridColor'),
  },
  cell: {
    fontSize: 12, // Native macOS list font size is usually smaller than iOS
  },
  cellName: {
    flex: 3,
  },
  cellDate: {
    flex: 2,
  },
  cellSize: {
    flex: 1,
  },
  cellXmp: {
    flex: 1.5,
  },
  galleryContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: PlatformColor('underPageBackgroundColor'),
  },
  galleryText: {
    fontSize: 16,
    fontWeight: '600',
    color: PlatformColor('secondaryLabelColor'),
    marginBottom: 8,
  },
  gallerySubtext: {
    fontSize: 12,
    color: PlatformColor('tertiaryLabelColor'),
  },
});

export default App;
