/**
 * NativeModulesMock.ts
 *
 * Windows版ビルド用に NativeModules のモック実装を提供します。
 * App.tsx 内の NativeModules アクセスを安全に行うためのフォールバックです。
 */

import { Platform, NativeEventEmitter, NativeModules } from 'react-native';

// ---- ToolbarEmitter Mock ----
// macOS: NativeModules.ToolbarEmitter は実際のネイティブモジュール
// Windows: イベントを発行しないダミーのEmitter

class NoopEventEmitter {
  addListener(_event: string, _callback: (...args: any[]) => void) {
    return { remove: () => {} };
  }
  removeAllListeners(_event: string) {}
  emit(_event: string, ..._args: any[]) {}
}

// ---- ToolbarProgress Mock ----
const ToolbarProgressMock = {
  setProgress: (_value: number) => {
    // Windows: no-op
  },
};

// ---- MetadataReader Mock ----
const MetadataReaderMock = {
  extractBasicMetadata: async (_path: string) => {
    // Windows: ダミーのメタデータを返す
    return {
      fileSize: 0,
      date: null,
      hasGps: false,
      width: null,
      height: null,
    };
  },
};

// ---- ExifToolRunner Mock ----
const ExifToolRunnerMock = {
  executeCommand: async (_args: string[]) => {
    // Windows: ダミー結果を返す
    return { stdout: '[Windows mock: ExifTool not available]', stderr: '' };
  },
};

// ---- Platform-aware exports ----

export function getToolbarEmitter(): NoopEventEmitter | NativeEventEmitter {
  if (Platform.OS === 'macos') {
    const { ToolbarEmitter } = NativeModules;
    if (ToolbarEmitter) {
      return new NativeEventEmitter(ToolbarEmitter);
    }
  }
  return new NoopEventEmitter() as any;
}

export function getToolbarProgress(): typeof ToolbarProgressMock {
  if (Platform.OS === 'macos') {
    const { ToolbarProgress } = NativeModules;
    if (ToolbarProgress) return ToolbarProgress;
  }
  return ToolbarProgressMock;
}

export function getMetadataReader(): typeof MetadataReaderMock {
  if (Platform.OS === 'macos') {
    const { MetadataReader } = NativeModules;
    if (MetadataReader) return MetadataReader;
  }
  return MetadataReaderMock;
}

export function getExifToolRunner(): typeof ExifToolRunnerMock {
  if (Platform.OS === 'macos') {
    const { ExifToolRunner } = NativeModules;
    if (ExifToolRunner) return ExifToolRunner;
  }
  return ExifToolRunnerMock;
}
