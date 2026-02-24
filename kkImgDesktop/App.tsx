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
  ScrollView,
  Image,
  Switch,
  Platform,
} from 'react-native';

import DraggableView from './DraggableView';
import FilterSegment from './FilterSegment';
import ThumbnailView from './ThumbnailView';
import { t, Locale, getLocale, setLocale } from './i18n';

import C from './platformColors';
import { getToolbarEmitter, getToolbarProgress, getMetadataReader, getExifToolRunner } from './NativeModulesMock';

const toolbarEmitter = getToolbarEmitter();

/**
 * Date strings come pre-formatted by NSDateFormatter from MetadataReader.mm.
 * This function just handles the nil/empty case.
 */
function formatExifDate(raw: string | undefined | null): string {
  if (!raw) return 'NO_DATE';
  return raw;
}

export type AppFile = {
  id: string;
  name: string;
  path: string;
  date: string;
  size: string;
  hasXmp: boolean;
  width?: number;
  height?: number;
  rawMetadata?: any;
  rawExifOutput?: string;
};

function App(): React.JSX.Element {
  const [files, setFiles] = useState<AppFile[]>([]);
  const [appLocale, setAppLocale] = useState<Locale>(getLocale());

  // Selection State
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [lastSelectedId, setLastSelectedId] = useState<string | null>(null);

  // Previous single selection state (keeping for compatibility or preview pane)
  const [activePreviewId, setActivePreviewId] = useState<string | null>(null);

  const [viewMode, setViewMode] = useState<'list' | 'gallery'>('list');

  // App Mode State
  type AppMode = 'metadata' | 'avif' | 'hash';
  const [appMode, setAppMode] = useState<AppMode>('metadata');

  // Inspector State
  type InspectorTab = 'preview' | 'organize' | 'settings' | 'queue';
  const [inspectorTab, setInspectorTab] = useState<InspectorTab>('preview');

  // App Layout State
  const [showInspector, setShowInspector] = useState(true);

  // Settings / Filter State
  type FilterState = 'any' | 'yes' | 'no';
  const [dateFilter, setDateFilter] = useState<FilterState>('any');
  const [gpsFilter, setGpsFilter] = useState<FilterState>('any');
  const [isFilterActive, setIsFilterActive] = useState(false);
  const [isHighlightActive, setIsHighlightActive] = useState(false);

  // Progress Sheet State
  const [isProcessing, setIsProcessing] = useState(false);

  // Listen for Native Inspector State Changes (Toggle open/close + Tab selection)
  React.useEffect(() => {
    const subscription = toolbarEmitter.addListener(
      'onInspectorStateChanged',
      (event: { isOpen: boolean; tab: InspectorTab }) => {
        // Only trigger layout animation if the open/close state actually changes
        if (event.isOpen !== showInspector) {
          LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
          setShowInspector(event.isOpen);
        }

        // If it's open (or opening), set the active tab
        if (event.isOpen) {
          setInspectorTab(event.tab);
        }
      }
    );
    return () => subscription.remove();
  }, [showInspector]);

  React.useEffect(() => {
    // Listen for the native toolbar segment changes
    const viewSub = toolbarEmitter.addListener(
      'onViewModeChanged',
      (event: { mode: 'list' | 'gallery' }) => {
        setViewMode(event.mode);
      }
    );

    const modeSub = toolbarEmitter.addListener(
      'onAppModeChanged',
      (event: { mode: AppMode }) => {
        setAppMode(event.mode);
      }
    );

    const filterSub = toolbarEmitter.addListener(
      'onFilterToggled',
      (event: { isActive: boolean }) => {
        setIsFilterActive(event.isActive);
      }
    );

    return () => {
      viewSub.remove();
      modeSub.remove();
      filterSub.remove();
    };
  }, []);



  // Lazy load ExifTool data when a file is selected for preview
  React.useEffect(() => {
    if (!activePreviewId) return;
    const item = files.find(f => f.id === activePreviewId);
    if (item && item.rawExifOutput === undefined) {
      setFiles(prev => prev.map(f => f.id === activePreviewId ? { ...f, rawExifOutput: 'Loading ExifTool data...' } : f));
      const ExifToolRunner = getExifToolRunner();
      ExifToolRunner.executeCommand([item.path])
        .then((result: any) => {
          setFiles(prev => prev.map(f => f.id === activePreviewId ? { ...f, rawExifOutput: result.stdout } : f));
        })
        .catch((e: any) => {
          console.log('ExifTool error:', e);
          setFiles(prev => prev.map(f => f.id === activePreviewId ? { ...f, rawExifOutput: 'Failed to load extended EXIF data.' } : f));
        });
    }
  }, [activePreviewId, files]);

  const testProgress = () => {
    setIsProcessing(true);
    const ToolbarProgress = getToolbarProgress();
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

  const handleDrop = async (e: any) => {
    let urls: string[] = [];
    if (e.nativeEvent.urls) {
      urls = e.nativeEvent.urls;
    } else if (e.nativeEvent.dataTransfer && e.nativeEvent.dataTransfer.files) {
      urls = e.nativeEvent.dataTransfer.files.map((f: any) => f.uri || f.path || f.name).filter(Boolean);
    }

    if (urls.length > 0) {
      setIsProcessing(true);
      const MetadataReader = getMetadataReader();

      const newFiles: AppFile[] = [];

      for (const url of urls) {
        // Make sure it's a real file path
        const path = url.startsWith('file://') ? decodeURIComponent(url.replace('file://', '')) : url;
        const name = path.split('/').pop() || 'Unknown';

        try {
          // Fast read
          const meta = await MetadataReader.extractBasicMetadata(path);

          let sizeStr = 'Unknown';
          if (meta.fileSize) {
            const bytes = meta.fileSize;
            if (bytes > 1024 * 1024) sizeStr = `${(bytes / 1024 / 1024).toFixed(1)} MB`;
            else sizeStr = `${(bytes / 1024).toFixed(1)} KB`;
          }

          newFiles.push({
            id: path, // Use path as ID to prevent duplicates if dropped twice
            name: name,
            path: path,
            date: formatExifDate(meta.date),
            size: sizeStr,
            hasXmp: meta.hasGps || false, // Mapping hasGps to hasXmp temporarily for UI
            width: meta.width || undefined,
            height: meta.height || undefined,
            rawMetadata: meta,
            rawExifOutput: undefined, // Let the lazy loader handle it
          });
        } catch (error) {
          console.warn(`Failed to read metadata for ${path}:`, error);
          newFiles.push({
            id: path,
            name: name,
            path: path,
            date: 'Unknown',
            size: '0 B',
            hasXmp: false,
            rawExifOutput: 'Read Error',
          });
        }
      }

      // Merge unique based on path
      setFiles(prev => {
        const merged = [...prev];
        newFiles.forEach(nf => {
          if (!merged.find(existing => existing.id === nf.id)) {
            merged.push(nf);
          }
        });
        return merged;
      });
      setIsProcessing(false);
    }
  };

  const handleBatchFixDates = async () => {
    const filesToFix = files.filter(f => f.date === 'NO_DATE');
    if (filesToFix.length === 0) {
      Alert.alert(t('alert.noInfo.title'), t('alert.noInfo.body'));
      return;
    }

    setIsProcessing(true);
    setInspectorTab('queue'); // Switch to queue tab to show activity
    const ToolbarProgress = getToolbarProgress();
    ToolbarProgress.setProgress(10); // Start indeterminate-like progress

    try {
      const ExifToolRunner = getExifToolRunner();
      const MetadataReader = getMetadataReader();
      const filePaths = filesToFix.map(f => f.path);

      const args = [
        '-overwrite_original',
        '-AllDates<FileModifyDate',
        ...filePaths
      ];

      ToolbarProgress.setProgress(50);

      const result = await ExifToolRunner.executeCommand(args);
      console.log('ExifTool batch result:', result);

      ToolbarProgress.setProgress(80);

      // Refresh the dates for modified files
      const updatedFiles = [...files];

      for (const path of filePaths) {
        try {
          const meta = await MetadataReader.extractBasicMetadata(path);
          const idx = updatedFiles.findIndex(f => f.path === path);
          if (idx !== -1) {
            updatedFiles[idx] = {
              ...updatedFiles[idx],
              date: formatExifDate(meta.date),
              hasXmp: meta.hasGps || false,
            };
            // Invalidate ExifTool cache if it was the selected item
            if (updatedFiles[idx].id === activePreviewId) {
              updatedFiles[idx].rawExifOutput = undefined;
            }
          }
        } catch (e) {
          console.warn('Failed to refresh metadata for', path, e);
        }
      }

      setFiles(updatedFiles);
      ToolbarProgress.setProgress(100);

      setTimeout(() => {
        setIsProcessing(false);
        const ToolbarProgress = getToolbarProgress();
        ToolbarProgress.setProgress(0);
      }, 500);

    } catch (error) {
      console.error('Batch fix dates failed:', error);
      Alert.alert(t('alert.error.title'), t('alert.error.body'));
      setIsProcessing(false);
      const ToolbarProgress = getToolbarProgress();
      ToolbarProgress.setProgress(0);
    }
  };

  // Filter the files based on the selected filter filters
  const filteredFiles = React.useMemo(() => {
    if (!isFilterActive) return files;
    // When both are 'any', filter is active but shows everything
    if (dateFilter === 'any' && gpsFilter === 'any') return files;

    return files.filter(f => {
      let dateMatch = true;
      let gpsMatch = true;

      if (dateFilter === 'yes') dateMatch = f.date !== 'NO_DATE';
      else if (dateFilter === 'no') dateMatch = f.date === 'NO_DATE';

      if (gpsFilter === 'yes') gpsMatch = f.hasXmp;
      else if (gpsFilter === 'no') gpsMatch = !f.hasXmp;

      return dateMatch && gpsMatch;
    });
  }, [files, dateFilter, gpsFilter, isFilterActive]);

  const handleSelectAllFiltered = React.useCallback(() => {
    setSelectedIds(new Set(filteredFiles.map(f => f.id)));
  }, [filteredFiles]);

  const handleRemoveSelected = React.useCallback(() => {
    setFiles(prev => prev.filter(f => !selectedIds.has(f.id)));
    setSelectedIds(new Set());
  }, [selectedIds]);

  // Listen for Cmd+A from menu bar or native emitter
  React.useEffect(() => {
    const sub = toolbarEmitter.addListener('onSelectAll', handleSelectAllFiltered);
    return () => sub.remove();
  }, [handleSelectAllFiltered]);

  // Listen for Remove Selected from menu bar
  React.useEffect(() => {
    const sub = toolbarEmitter.addListener('onRemoveSelected', handleRemoveSelected);
    return () => sub.remove();
  }, [handleRemoveSelected]);

  // Listen for arrow key navigation from native responder chain (moveUp:/moveDown:)
  React.useEffect(() => {
    const navigate = (direction: 1 | -1, shift: boolean) => {
      setActivePreviewId(prevId => {
        const activeIdx = filteredFiles.findIndex(f => f.id === prevId);
        const nextIdx = direction === 1
          ? Math.min(activeIdx + 1, filteredFiles.length - 1)
          : Math.max(activeIdx - 1, 0);
        const nextItem = filteredFiles[nextIdx];
        if (nextItem && nextItem.id !== prevId) {
          if (shift) {
            // Range select: add next item to existing selection
            setSelectedIds(prev => {
              const next = new Set(prev);
              next.add(nextItem.id);
              return next;
            });
          } else {
            setSelectedIds(new Set([nextItem.id]));
            setLastSelectedId(nextItem.id);
          }
          return nextItem.id;
        }
        return prevId;
      });
    };
    const upSub = toolbarEmitter.addListener('onMoveUp', (e: any) => navigate(-1, e?.shift ?? false));
    const downSub = toolbarEmitter.addListener('onMoveDown', (e: any) => navigate(1, e?.shift ?? false));
    return () => { upSub.remove(); downSub.remove(); };
  }, [filteredFiles]);

  const handleDragEnd = React.useCallback((movedUrls: string[]) => {
    setFiles(prev => prev.filter(f => !movedUrls.includes(f.path)));
    setSelectedIds(prev => {
      const next = new Set(prev);
      // Clear selection for removed files
      for (const f of prev) {
        // We don't have id here, use path-based lookup before setFiles ran - best effort
      }
      return next;
    });
  }, []);

  const handleRowPress = (item: AppFile, event: any) => {
    const isMeta = event.nativeEvent.metaKey;
    const isShift = event.nativeEvent.shiftKey;

    if (isShift && lastSelectedId) {
      // Range select
      const lastIndex = filteredFiles.findIndex(f => f.id === lastSelectedId);
      const currentIndex = filteredFiles.findIndex(f => f.id === item.id);

      if (lastIndex !== -1 && currentIndex !== -1) {
        const start = Math.min(lastIndex, currentIndex);
        const end = Math.max(lastIndex, currentIndex);

        setSelectedIds(prev => {
          const next = isMeta ? new Set(prev) : new Set<string>();
          for (let i = start; i <= end; i++) {
            next.add(filteredFiles[i].id);
          }
          return next;
        });
      }
    } else if (isMeta) {
      // Toggle select
      setSelectedIds(prev => {
        const next = new Set(prev);
        if (next.has(item.id)) {
          next.delete(item.id);
        } else {
          next.add(item.id);
        }
        return next;
      });
      setLastSelectedId(item.id);
    } else {
      // Single select
      setSelectedIds(new Set([item.id]));
      setLastSelectedId(item.id);
    }

    setActivePreviewId(item.id);
  };

  const handleKeyDown = (e: any) => {
    const key: string = e.nativeEvent.key ?? '';
    const isMeta = e.nativeEvent.metaKey;
    // Cmd+A → Select All
    if ((key === 'a' || key === 'A') && isMeta) {
      handleSelectAllFiltered();
      return;
    }
    // Backspace/Delete → Remove from list
    // macOS "Delete" key reports as 'Backspace' in RN, forward-delete as 'Delete'
    if (key === 'Backspace' || key === 'Delete' || key === '\x7f' || key === '\x08') {
      handleRemoveSelected();
      return;
    }
    // Arrow keys – macOS may report these as 'ArrowDown' or the Unicode private-use chars
    const isDown = key === 'ArrowDown' || key === '\uF702' || key === '\uF701';
    const isUp = key === 'ArrowUp' || key === '\uF700' || key === '\uF703';
    if (isDown || isUp) {
      const activeIdx = filteredFiles.findIndex(f => f.id === activePreviewId);
      const nextIdx = isDown
        ? Math.min(activeIdx + 1, filteredFiles.length - 1)
        : Math.max(activeIdx - 1, 0);
      const nextItem = filteredFiles[nextIdx];
      if (nextItem) {
        if (e.nativeEvent.shiftKey && activeIdx !== -1) {
          setSelectedIds(prev => {
            const next = new Set(prev);
            next.add(nextItem.id);
            return next;
          });
        } else {
          setSelectedIds(new Set([nextItem.id]));
          setLastSelectedId(nextItem.id);
        }
        setActivePreviewId(nextItem.id);
      }
    }
  };

  // The URLs that should be passed to the drag manager (all currently selected items)
  const selectedUrls = files.filter(f => selectedIds.has(f.id)).map(f => f.path);

  const activePreviewItem = files.find(item => item.id === activePreviewId);

  const renderItem = ({ item, index }: { item: AppFile, index: number }) => {
    const isSelected = selectedIds.has(item.id);
    const isMissingDate = item.date === 'NO_DATE';

    // Fix highlight to only apply when isHighlightActive is true; matchesCriteria based on filter criteria (not just missing date)
    const matchesCriteria = (() => {
      let dateMatch = true;
      let gpsMatch = true;
      if (dateFilter === 'yes') dateMatch = item.date !== 'NO_DATE';
      else if (dateFilter === 'no') dateMatch = item.date === 'NO_DATE';
      if (gpsFilter === 'yes') gpsMatch = item.hasXmp;
      else if (gpsFilter === 'no') gpsMatch = !item.hasXmp;
      return dateMatch && gpsMatch;
    })();

    let rowBackgroundColor: any = 'transparent';

    if (isSelected) {
      rowBackgroundColor = C.selectedContentBackgroundColor;
    } else if (isHighlightActive && !isFilterActive && matchesCriteria) {
      // Only highlight when not in filter mode
      rowBackgroundColor = 'rgba(255, 59, 48, 0.2)';
    } else if (index % 2 === 1) {
      rowBackgroundColor = C.alternatingContentBackgroundColor;
    }

    // Determine what URLs to drag. If the user drags a row that isn't selected,
    // drag just that row. If they drag a selected row, drag all selected.
    const dragUrls = isSelected ? selectedUrls : [item.path];

    return (
      <DraggableView
        fileUrls={dragUrls}
        style={{ flex: 1 }}
        onDragEnd={(e) => handleDragEnd(e.nativeEvent.movedUrls)}
      >
        <TouchableOpacity
          activeOpacity={1}
          onPress={(e) => handleRowPress(item, e)}
          style={[
            styles.row,
            { backgroundColor: rowBackgroundColor }
          ]}
        >
          <View style={styles.cellThumb}>
            <ThumbnailView
              src={`file://${item.path}`}
              style={{
                width: item.width && item.height ? Math.min(16, 16 * (item.width / item.height)) : 16,
                height: 16
              }}
              resizeMode="contain"
            />
          </View>
          <Text style={[styles.cell, styles.cellName, { color: isSelected ? C.alternateSelectedControlTextColor : C.controlTextColor }]} numberOfLines={1} ellipsizeMode="middle">
            {item.name}
          </Text>
          <Text style={[
            styles.cell,
            styles.cellDate,
            {
              color: isSelected ? C.alternateSelectedControlTextColor : (isMissingDate ? C.systemOrangeColor : C.controlTextColor),
              fontWeight: isMissingDate ? '600' : 'normal'
            }
          ]}>
            {item.date === 'NO_DATE' ? t('noDate') : item.date}
          </Text>
          <Text style={[styles.cell, styles.cellSize, { color: isSelected ? C.alternateSelectedControlTextColor : C.secondaryLabelColor }]}>
            {item.size}
          </Text>
          <Text style={[
            styles.cell,
            styles.cellXmp,
            { color: isSelected ? C.alternateSelectedControlTextColor : (item.hasXmp ? C.systemGreenColor : C.secondaryLabelColor) }
          ]}>
            {item.hasXmp ? '✓' : '-'}
          </Text>
        </TouchableOpacity>
      </DraggableView>
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
      focusable={true}
      // @ts-ignore
      enableFocusRing={false}
      onKeyDown={handleKeyDown}
      validKeysDown={['a', 'A', 'ArrowUp', 'ArrowDown', 'Backspace', 'Delete', '\uF700', '\uF701', '\uF702', '\uF703']}
    >
      <View style={styles.splitContainer}>
        {/* LEFT PANE: Main Content */}
        <View
          style={styles.mainPane}
        >
          {files.length === 0 ? (
            <View style={styles.emptyStateContainer}>
              <View style={styles.emptyStateIconPlaceholder}>
                <Text style={{ fontSize: 54, fontWeight: '200', color: C.tertiaryLabelColor }}>
                  {appMode === 'metadata' && '􀫊'}
                  {appMode === 'avif' && '􀈄'}
                  {appMode === 'hash' && '􀈷'}
                </Text>
              </View>
              <Text style={styles.emptyStateTitle}>
                {appMode === 'metadata' && t('empty.meta.title')}
                {appMode === 'avif' && t('empty.avif.title')}
                {appMode === 'hash' && t('empty.hash.title')}
              </Text>
              <Text style={styles.emptyStateSubtext}>
                {appMode === 'metadata' && t('empty.meta.sub')}
                {appMode === 'avif' && t('empty.avif.sub')}
                {appMode === 'hash' && t('empty.hash.sub')}
              </Text>
            </View>
          ) : appMode !== 'metadata' ? (
            <View style={styles.galleryContainer}>
              <Text style={styles.galleryText}>{appMode === 'avif' ? 'AVIF Converter' : 'Hasher'}</Text>
              <View style={{ marginTop: 16, paddingHorizontal: 12, paddingVertical: 6, backgroundColor: C.controlBackgroundColor, borderRadius: 6, borderWidth: 1, borderColor: C.separatorColor }}>
                <Text style={{ fontSize: 13, fontWeight: '600', color: C.secondaryLabelColor }}>{t('wip.title')}</Text>
                <Text style={{ fontSize: 11, color: C.tertiaryLabelColor, marginTop: 2 }}>{t('wip.body')}</Text>
              </View>
            </View>
          ) : viewMode === 'list' ? (
            <>
              <View style={styles.listHeader}>
                <View style={styles.cellThumb} />
                <Text style={[styles.columnHeader, styles.cellName]}>{t('col.filename')}</Text>
                <Text style={[styles.columnHeader, styles.cellDate]}>{t('col.date')}</Text>
                <Text style={[styles.columnHeader, styles.cellSize]}>{t('col.size')}</Text>
                <Text style={[styles.columnHeader, styles.cellXmp]}>{t('col.xmp')}</Text>
              </View>

              <FlatList
                data={filteredFiles}
                keyExtractor={item => item.id}
                renderItem={renderItem}
                contentContainerStyle={styles.listContent}
              />
            </>
          ) : (
            <View style={styles.galleryContainer}>
              <Text style={styles.galleryText}>{t('gallery.placeholder')}</Text>
              <View style={{ marginTop: 16, paddingHorizontal: 12, paddingVertical: 6, backgroundColor: C.controlBackgroundColor, borderRadius: 6, borderWidth: 1, borderColor: C.separatorColor }}>
                <Text style={{ fontSize: 13, fontWeight: '600', color: C.secondaryLabelColor }}>{t('wip.title')}</Text>
                <Text style={{ fontSize: 11, color: C.tertiaryLabelColor, marginTop: 2 }}>{t('wip.body')}</Text>
              </View>
            </View>
          )}
        </View>

        {/* RIGHT PANE: Inspector (Preview & Metadata) */}
        {showInspector && (
          <View style={styles.inspectorPane}>
            {files.length > 0 ? (
              <ScrollView style={styles.inspectorScroll} contentContainerStyle={styles.inspectorContent}>
                {/* Inspector Tab Content (Controlled from Native Toolbar) */}
                {inspectorTab === 'preview' && (
                  <View style={styles.tabContent}>
                    {activePreviewItem ? (
                      <>
                        <View style={styles.previewImagePlaceholder}>
                          {activePreviewItem.path ? (
                            <DraggableView
                              style={{ width: '100%', height: '100%', borderRadius: 6 }}
                              fileUrls={(() => {
                                // If the active item is part of the selection, drag all selected items
                                if (selectedIds.has(activePreviewItem.id)) {
                                  return Array.from(selectedIds)
                                    .map(id => files.find(f => f.id === id)?.path)
                                    .filter((p): p is string => !!p);
                                }
                                // Otherwise just drag this one
                                return [activePreviewItem.path];
                              })()}
                              onDragEnd={handleDragEnd}
                            >
                              <ThumbnailView
                                src={`file://${activePreviewItem.path}`}
                                style={{ width: '100%', height: '100%', borderRadius: 6 }}
                                resizeMode="contain"
                              />
                            </DraggableView>
                          ) : (
                            <Text style={styles.previewPlaceholderText}>{t('preview.imagePreview')}</Text>
                          )}
                        </View>
                        <Text style={styles.inspectorTitle}>{activePreviewItem.name}</Text>
                        <View style={styles.metadataRow}>
                          <Text style={styles.metadataLabel}>{t('preview.size')}:</Text>
                          <Text style={styles.metadataValue}>{activePreviewItem.size} {activePreviewItem.width && activePreviewItem.height ? `(${activePreviewItem.width}x${activePreviewItem.height})` : ''}</Text>
                        </View>
                        <View style={styles.metadataRow}>
                          <Text style={styles.metadataLabel}>{t('preview.date')}:</Text>
                          <Text style={styles.metadataValue}>{activePreviewItem.date === 'NO_DATE' ? t('noDate') : activePreviewItem.date}</Text>
                        </View>
                        <View style={styles.metadataRow}>
                          <Text style={styles.metadataLabel}>{t('preview.location')}:</Text>
                          <Text style={styles.metadataValue}>{activePreviewItem.hasXmp ? t('preview.gpsYes') : t('preview.gpsNo')}</Text>
                        </View>

                        {activePreviewItem.rawExifOutput && (
                          <View style={{ marginTop: 16 }}>
                            <Text style={{ fontWeight: 'bold', marginBottom: 4, color: C.labelColor }}>{t('preview.exifTitle')}:</Text>
                            <ScrollView style={{ height: 200, backgroundColor: C.textBackgroundColor, padding: 8, borderRadius: 4, borderWidth: StyleSheet.hairlineWidth, borderColor: C.separatorColor }}>
                              <Text style={{ fontSize: 11, fontFamily: Platform.OS === 'macos' ? 'Menlo' : 'Consolas', color: C.textColor }}>{activePreviewItem.rawExifOutput}</Text>
                            </ScrollView>
                          </View>
                        )}
                      </>
                    ) : (
                      <Text style={styles.metadataValue}>{t('preview.noSelection')}</Text>
                    )}
                  </View>
                )}

                {inspectorTab === 'organize' && (
                  <View style={styles.tabContent}>
                    <Text style={styles.inspectorTitle}>{t('organize.title')}</Text>

                    <View style={styles.settingRow}>
                      <Text style={styles.settingLabel} numberOfLines={1}>{t('organize.filter')}</Text>
                      <Switch
                        value={isFilterActive}
                        onValueChange={setIsFilterActive}
                      />
                    </View>

                    <View style={styles.settingRow}>
                      <Text style={[styles.settingLabel, { color: isFilterActive ? C.tertiaryLabelColor : C.labelColor }]} numberOfLines={1}>{t('organize.highlight')}</Text>
                      <Switch
                        value={isHighlightActive}
                        onValueChange={setIsHighlightActive}
                        disabled={isFilterActive}
                      />
                    </View>

                    <View style={{ marginTop: 16, marginBottom: 16 }}>
                      <View style={{ flexDirection: 'row', gap: 8, marginBottom: 12, alignItems: 'center' }}>
                        <Text style={[styles.settingLabel, { flex: 1 }]}>{t('organize.date')}:</Text>
                        <FilterSegment
                          style={{ flex: 2, height: 24 }}
                          options={[t('organize.filterAny'), t('organize.filterHas'), t('organize.filterNone')]}
                          selectedIndex={dateFilter === 'any' ? 0 : dateFilter === 'yes' ? 1 : 2}
                          onSegmentChange={(e) => {
                            const idx = e.nativeEvent.selectedIndex;
                            setDateFilter(idx === 0 ? 'any' : idx === 1 ? 'yes' : 'no');
                          }}
                        />
                      </View>

                      <View style={{ flexDirection: 'row', gap: 8, marginBottom: 16, alignItems: 'center' }}>
                        <Text style={[styles.settingLabel, { flex: 1 }]}>{t('organize.location')}:</Text>
                        <FilterSegment
                          style={{ flex: 2, height: 24 }}
                          options={[t('organize.filterAny'), t('organize.filterHas'), t('organize.filterNone')]}
                          selectedIndex={gpsFilter === 'any' ? 0 : gpsFilter === 'yes' ? 1 : 2}
                          onSegmentChange={(e) => {
                            const idx = e.nativeEvent.selectedIndex;
                            setGpsFilter(idx === 0 ? 'any' : idx === 1 ? 'yes' : 'no');
                          }}
                        />
                      </View>

                      <Text style={[styles.settingLabel, { fontSize: 11, color: C.tertiaryLabelColor }]}>
                        {t('organize.stats', { shown: filteredFiles.length, selected: selectedIds.size })}
                      </Text>
                    </View>
                  </View>
                )}


                {inspectorTab === 'settings' && (
                  <View style={styles.tabContent}>
                    <Text style={styles.inspectorTitle}>{t('settings.title')} ({appMode})</Text>

                    <View style={{ marginTop: 8 }}>
                      <Text style={[styles.settingLabel, { marginBottom: 8, fontWeight: '600' }]}>{t('settings.batch')}</Text>
                      <TouchableOpacity
                        style={styles.nativeButton}
                        onPress={handleBatchFixDates}
                      >
                        <Text style={styles.nativeButtonText}>{t('settings.fixDates')}</Text>
                      </TouchableOpacity>
                    </View>

                    <View style={{ marginTop: 24 }}>
                      <Text style={[styles.settingLabel, { marginBottom: 8, fontWeight: '600' }]}>{t('settings.language')}</Text>
                      <FilterSegment
                        style={{ height: 24 }}
                        options={['English', '東京弁', '日本語']}
                        selectedIndex={appLocale === 'en' ? 0 : appLocale === 'ja' ? 1 : 2}
                        onSegmentChange={(e) => {
                          const idx = e.nativeEvent.selectedIndex;
                          const newLoc: Locale = idx === 0 ? 'en' : idx === 1 ? 'ja' : 'kansai';
                          setLocale(newLoc);
                          setAppLocale(newLoc);
                        }}
                      />
                    </View>

                    {/* Show WIP placeholder layout when not exactly metadata */}
                    {appMode !== 'metadata' && (
                      <View style={{ marginTop: 24, padding: 12, backgroundColor: C.controlBackgroundColor, borderRadius: 6, borderWidth: 1, borderColor: C.separatorColor }}>
                        <Text style={{ fontSize: 13, fontWeight: '600', color: C.secondaryLabelColor }}>{t('wip.title')}</Text>
                        <Text style={{ fontSize: 11, color: C.tertiaryLabelColor, marginTop: 2 }}>{t('wip.body')}</Text>
                      </View>
                    )}
                  </View>
                )}

                {inspectorTab === 'queue' && (
                  <View style={styles.tabContent}>
                    <Text style={styles.inspectorTitle}>{t('queue.title')}</Text>
                    <Text style={styles.metadataValue}>{t('queue.ready')}</Text>
                    <View style={{ marginTop: 16, padding: 12, backgroundColor: C.controlBackgroundColor, borderRadius: 6, borderWidth: 1, borderColor: C.separatorColor }}>
                      <Text style={{ fontSize: 13, fontWeight: '600', color: C.secondaryLabelColor }}>{t('wip.title')}</Text>
                      <Text style={{ fontSize: 11, color: C.tertiaryLabelColor, marginTop: 2 }}>{t('wip.body')}</Text>
                    </View>
                  </View>
                )}
              </ScrollView>
            ) : (
              <View style={styles.inspectorEmpty}>
                <Text style={styles.inspectorEmptyText}>
                  {appMode === 'metadata' && t('inspector.empty.meta')}
                  {appMode === 'avif' && t('inspector.empty.avif')}
                  {appMode === 'hash' && t('inspector.empty.hash')}
                </Text>
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
    backgroundColor: C.windowBackgroundColor,
  },
  splitContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  mainPane: {
    flex: 1,
    backgroundColor: C.controlBackgroundColor,
  },
  inspectorPane: {
    width: 280,
    borderLeftWidth: StyleSheet.hairlineWidth,
    borderLeftColor: C.separatorColor,
    backgroundColor: C.windowBackgroundColor,
  },
  inspectorScroll: {
    flex: 1,
  },
  inspectorContent: {
    padding: 16,
  },
  tabContent: {
    flex: 1,
  },
  previewImagePlaceholder: {
    width: '100%',
    aspectRatio: 1,
    backgroundColor: C.underPageBackgroundColor,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  previewPlaceholderText: {
    color: C.tertiaryLabelColor,
    fontSize: 14,
  },
  inspectorTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: C.labelColor,
    marginBottom: 16,
  },
  metadataRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  metadataLabel: {
    flex: 1,
    color: C.secondaryLabelColor,
    fontSize: 12,
  },
  metadataValue: {
    flex: 2,
    color: C.labelColor,
    fontSize: 12,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  settingLabel: {
    fontSize: 13,
    color: C.labelColor,
  },
  nativeButton: {
    backgroundColor: C.controlBackgroundColor,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: C.separatorColor,
    borderRadius: 5,
    paddingVertical: 6,
    paddingHorizontal: 12,
    alignItems: 'center',
  },
  nativeButtonText: {
    fontSize: 13,
    color: C.labelColor,
  },
  inspectorEmpty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  inspectorEmptyText: {
    color: C.tertiaryLabelColor,
    fontSize: 13,
  },
  emptyStateContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: C.controlBackgroundColor,
    padding: 32,
  },
  emptyStateIconPlaceholder: {
    marginBottom: 16,
    opacity: 0.6,
  },
  emptyStateTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: C.secondaryLabelColor,
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyStateSubtext: {
    fontSize: 13,
    color: C.tertiaryLabelColor,
    textAlign: 'center',
    maxWidth: 300,
  },
  listHeader: {
    flexDirection: 'row',
    paddingVertical: 6,
    paddingHorizontal: 16,
  },
  columnHeader: {
    fontWeight: '600',
    fontSize: 12,
    color: C.secondaryLabelColor,
  },
  listContent: {
    paddingBottom: 20,
    backgroundColor: C.controlBackgroundColor,
  },
  row: {
    flexDirection: 'row',
    paddingVertical: 6,
    paddingHorizontal: 16,
  },

  cell: {
    fontSize: 12, // Native macOS list font size is usually smaller than iOS
  },
  cellThumb: {
    width: 20, // 16px max width + 4px spacing
    alignItems: 'center',
    justifyContent: 'center',
  },
  cellName: {
    flex: 3,
    paddingRight: 8,
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
    backgroundColor: C.underPageBackgroundColor,
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
