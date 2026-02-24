/**
 * platformColors.ts
 *
 * macOS のセマンティックカラー（PlatformColor）に対するフォールバックを提供します。
 * macOS: PlatformColor('labelColor') などのシステムカラーを使用
 * Windows / その他: 対応するフォールバック静的カラーを使用
 */
import { Platform, PlatformColor } from 'react-native';

type PlatformColorValue = ReturnType<typeof PlatformColor> | string;

function pc(macOSName: string, fallback: string): PlatformColorValue {
  if (Platform.OS === 'macos') {
    return PlatformColor(macOSName);
  }
  return fallback;
}

export const colors = {
  // Labels
  labelColor: pc('labelColor', '#000000'),
  secondaryLabelColor: pc('secondaryLabelColor', '#6e6e73'),
  tertiaryLabelColor: pc('tertiaryLabelColor', '#aeaeb2'),
  quaternaryLabelColor: pc('quaternaryLabelColor', '#c7c7cc'),

  // Content
  textColor: pc('textColor', '#000000'),
  textBackgroundColor: pc('textBackgroundColor', '#ffffff'),
  controlTextColor: pc('controlTextColor', '#000000'),
  alternateSelectedControlTextColor: pc('alternateSelectedControlTextColor', '#ffffff'),

  // Background
  windowBackgroundColor: pc('windowBackgroundColor', '#f0f0f0'),
  controlBackgroundColor: pc('controlBackgroundColor', '#f8f8f8'),
  underPageBackgroundColor: pc('underPageBackgroundColor', '#e8e8e8'),

  // Separators
  separatorColor: pc('separatorColor', '#d1d1d1'),

  // Selection
  selectedContentBackgroundColor: pc('selectedContentBackgroundColor', '#0078d4'),
  alternatingContentBackgroundColor: pc('alternatingContentBackgroundColor', '#f5f5f5'),

  // System colors
  systemOrangeColor: pc('systemOrangeColor', '#ff8c00'),
  systemGreenColor: pc('systemGreenColor', '#107c10'),
  systemBlueColor: pc('systemBlueColor', '#0078d4'),
};

export default colors;
