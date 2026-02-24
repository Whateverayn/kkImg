/**
 * FilterSegment - Windows Mock
 *
 * Windows版では SegmentedControl のネイティブ実装は未実装のため、
 * TouchableOpacity を並べたシンプルなボタングループとして実装します。
 */
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ViewProps } from 'react-native';

export interface FilterSegmentProps extends ViewProps {
  options: string[];
  selectedIndex: number;
  onSegmentChange?: (e: { nativeEvent: { selectedIndex: number } }) => void;
}

const FilterSegment: React.FC<FilterSegmentProps> = ({
  options,
  selectedIndex,
  onSegmentChange,
  style,
  ...rest
}) => {
  return (
    <View style={[styles.container, style as any]} {...rest}>
      {options.map((label, idx) => {
        const isSelected = idx === selectedIndex;
        return (
          <TouchableOpacity
            key={idx}
            style={[styles.segment, isSelected && styles.segmentSelected]}
            onPress={() => onSegmentChange?.({ nativeEvent: { selectedIndex: idx } })}
          >
            <Text style={[styles.label, isSelected && styles.labelSelected]}>
              {label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ccc',
    overflow: 'hidden',
  },
  segment: {
    flex: 1,
    paddingVertical: 4,
    alignItems: 'center',
    backgroundColor: '#f0f0f0',
  },
  segmentSelected: {
    backgroundColor: '#0078d4',
  },
  label: {
    fontSize: 12,
    color: '#333',
  },
  labelSelected: {
    color: '#fff',
    fontWeight: '600',
  },
});

export default FilterSegment;
