/**
 * ThumbnailView - Windows Mock
 *
 * Windows版ではネイティブのサムネイルビューの代わりに
 * React NativeのImageコンポーネントで代替します。
 */
import React from 'react';
import { Image, View, ViewProps, StyleSheet } from 'react-native';

interface ThumbnailViewProps extends ViewProps {
  src?: string;
  resizeMode?: 'cover' | 'contain' | 'stretch' | 'center';
}

export default function ThumbnailView({ src, resizeMode = 'contain', style, ...rest }: ThumbnailViewProps) {
  if (!src) {
    return <View style={[styles.placeholder, style as any]} {...rest} />;
  }
  return (
    <Image
      source={{ uri: src }}
      style={style as any}
      resizeMode={resizeMode}
    />
  );
}

const styles = StyleSheet.create({
  placeholder: {
    backgroundColor: '#e0e0e0',
  },
});
