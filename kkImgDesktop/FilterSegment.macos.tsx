import { requireNativeComponent, ViewProps } from 'react-native';

export interface FilterSegmentProps extends ViewProps {
    /** Labels for each segment, e.g. ['Any', 'Has', 'None'] */
    options: string[];
    /** 0-based selected index */
    selectedIndex: number;
    /** Called when user taps a segment */
    onSegmentChange?: (e: { nativeEvent: { selectedIndex: number } }) => void;
}

const RCTFilterSegment = requireNativeComponent<FilterSegmentProps>('FilterSegment');

export default RCTFilterSegment;
