import { requireNativeComponent, ViewProps } from 'react-native';

export interface DraggableViewProps extends ViewProps {
    fileUrls: string[];
    onDragEnd?: (e: { nativeEvent: { movedUrls: string[]; operation: number } }) => void;
}

const RCTDraggableView = requireNativeComponent<DraggableViewProps>('DraggableView');

export default RCTDraggableView;
