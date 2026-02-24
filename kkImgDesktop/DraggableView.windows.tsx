/**
 * DraggableView - Windows Mock
 *
 * Windows版ではD&Dのネイティブ実装は未実装のため、
 * 単純なViewラッパーとして動作します。
 */
import React from 'react';
import { View, ViewProps } from 'react-native';

export interface DraggableViewProps extends ViewProps {
  fileUrls: string[];
  onDragEnd?: (e: { nativeEvent: { movedUrls: string[]; operation: number } }) => void;
}

const DraggableView: React.FC<DraggableViewProps> = ({ fileUrls, onDragEnd, children, ...rest }) => {
  // Windows: D&D未実装のため単純なViewとして描画
  return <View {...rest}>{children}</View>;
};

export default DraggableView;
