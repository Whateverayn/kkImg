import React from 'react';
import { requireNativeComponent, processColor, ViewProps } from 'react-native';

interface ThumbnailViewProps extends ViewProps {
    src?: string;
    resizeMode?: 'cover' | 'contain' | 'stretch' | 'center';
}

const KKThumbnailView = requireNativeComponent<ThumbnailViewProps>('KKThumbnailView');

export default function ThumbnailView(props: ThumbnailViewProps) {
    return <KKThumbnailView {...props} />;
}
