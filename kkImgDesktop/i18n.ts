/**
 * i18n.ts — lightweight localisation for kkImg
 *
 * Supported locales: 'en' | 'ja' | 'kansai'
 * Add new locales by extending the `strings` object.
 *
 * Usage:
 *   import { t } from './i18n';
 *   <Text>{t('emptyState.metadata.title')}</Text>
 */

export type Locale = 'en' | 'ja' | 'kansai';

// ─── String Table ──────────────────────────────────────────────────────────

const strings: Record<Locale, Record<string, string>> = {
    // ── English ───────────────────────────────────────────────────────────────
    en: {
        // Empty state
        'empty.meta.title': 'Drop Images to View Metadata',
        'empty.meta.sub': 'Supports JPG, PNG, HEIC, TIFF, RAW',
        'empty.avif.title': 'Drop Images to Convert to AVIF',
        'empty.avif.sub': 'Batch convert multiple files to AVIF format instantly',
        'empty.hash.title': 'Drop Files to Calculate Hashes',
        'empty.hash.sub': 'Generate MD5, SHA-1, and SHA-256 for rapid deduplication',

        // List header columns
        'col.filename': 'Filename',
        'col.date': 'Date',
        'col.size': 'Size',
        'col.xmp': 'XMP Metadata',

        // Gallery placeholder
        'gallery.placeholder': 'Gallery View',
        'gallery.wip': 'Coming Soon',

        // Inspector — empty
        'inspector.empty.meta': 'Select an image to view Metadata',
        'inspector.empty.avif': 'Select an image for AVIF Settings',
        'inspector.empty.hash': 'Select a file to view Hashes',

        // Inspector — preview tab
        'preview.imagePreview': 'Image Preview',
        'preview.noSelection': 'Select an item to view preview',
        'preview.size': 'Size',
        'preview.date': 'Date',
        'preview.location': 'Location (GPS)',
        'preview.gpsYes': 'Coordinates attached',
        'preview.gpsNo': 'None',
        'preview.exifTitle': 'Raw ExifTool Output',

        // Inspector — organize tab
        'organize.title': 'Organize',
        'organize.filter': 'Filter list to matching items',
        'organize.highlight': 'Highlight matching items',
        'organize.date': 'Date',
        'organize.location': 'Location',
        'organize.filterAny': 'Any',
        'organize.filterHas': 'Has',
        'organize.filterNone': 'None',
        'organize.stats': '{shown} shown · {selected} selected',

        // Inspector — settings tab
        'settings.title': 'Settings',
        'settings.batch': 'Batch Actions',
        'settings.fixDates': 'Fix Dates (Match Modified)',
        'settings.language': 'Language',
        'settings.wip': 'Coming Soon',

        // Inspector — queue tab
        'queue.title': 'Progress Queue',
        'queue.ready': 'Ready',
        'queue.wip': 'Coming Soon',

        // WIP banner (used for AVIF / Hash modes, Gallery, etc.)
        'wip.title': '􀣋  Coming Soon',
        'wip.body': 'This feature is under development.',

        // Alerts
        'alert.noInfo.title': 'No Info',
        'alert.noInfo.body': 'All files already have valid dates.',
        'alert.error.title': 'Error',
        'alert.error.body': 'Failed to update dates.',

        // Misc
        'noDate': 'No Date',
        'unknown': 'Unknown',
    },

    // ── Japanese (日本語) ──────────────────────────────────────────────────────
    ja: {
        'empty.meta.title': '画像をドロップしてメタデータを表示',
        'empty.meta.sub': 'JPG / PNG / HEIC / TIFF / RAW に対応',
        'empty.avif.title': '画像をドロップして AVIF に変換',
        'empty.avif.sub': '複数ファイルを一括で AVIF 形式に変換します',
        'empty.hash.title': 'ファイルをドロップしてハッシュを計算',
        'empty.hash.sub': 'MD5 / SHA-1 / SHA-256 で重複ファイルを素早く検出',

        'col.filename': 'ファイル名',
        'col.date': '日時',
        'col.size': 'サイズ',
        'col.xmp': 'XMP メタデータ',

        'gallery.placeholder': 'ギャラリー表示',
        'gallery.wip': '開発中',

        'inspector.empty.meta': '画像を選択するとメタデータを表示します',
        'inspector.empty.avif': '画像を選択すると AVIF 設定を表示します',
        'inspector.empty.hash': 'ファイルを選択するとハッシュを表示します',

        'preview.imagePreview': 'プレビュー',
        'preview.noSelection': 'アイテムを選択するとプレビューを表示します',
        'preview.size': 'サイズ',
        'preview.date': '日時',
        'preview.location': '位置情報 (GPS)',
        'preview.gpsYes': '座標あり',
        'preview.gpsNo': 'なし',
        'preview.exifTitle': 'ExifTool 詳細出力',

        'organize.title': '整理',
        'organize.filter': '条件に合うアイテムに絞り込む',
        'organize.highlight': '条件に合うアイテムを強調',
        'organize.date': '日時',
        'organize.location': '位置情報',
        'organize.filterAny': 'すべて',
        'organize.filterHas': 'あり',
        'organize.filterNone': 'なし',
        'organize.stats': '{shown} 件表示 · {selected} 件選択',

        'settings.title': '設定',
        'settings.batch': '一括アクション',
        'settings.fixDates': '日時を修正 (更新日時に合わせる)',
        'settings.language': '言語 (Language)',
        'settings.wip': '開発中',

        'queue.title': '処理キュー',
        'queue.ready': '待機中',
        'queue.wip': '開発中',

        'wip.title': '􀣋  開発中',
        'wip.body': 'この機能は現在開発中です.',

        'alert.noInfo.title': '更新不要',
        'alert.noInfo.body': 'すべてのファイルはすでに有効な日時を持っています。',
        'alert.error.title': 'エラー',
        'alert.error.body': '日時の更新に失敗しました。',

        'noDate': '日時なし',
        'unknown': '不明',
    },

    // ── Kansai dialect (関西弁) ───────────────────────────────────────────────
    kansai: {
        'empty.meta.title': '画像ほかしてメタデータみたろか',
        'empty.meta.sub': 'JPG・PNG・HEIC・TIFF・RAW, なんでもこいや',
        'empty.avif.title': '画像ほかして AVIF に変えたろ',
        'empty.avif.sub': 'まとめてがーっと AVIF に変えたるで',
        'empty.hash.title': 'ファイルほかしてハッシュ出したろ',
        'empty.hash.sub': 'MD5・SHA-1・SHA-256 で重複なんてすぐわかるで',

        'col.filename': 'ファイル名',
        'col.date': 'いつのん',
        'col.size': 'どんくらい',
        'col.xmp': 'XMPとか',

        'gallery.placeholder': 'ギャラリー表示',
        'gallery.wip': '作ってる途中やねん',

        'inspector.empty.meta': '画像選んだらメタデータ出したるで',
        'inspector.empty.avif': '画像選んだら AVIF の設定出したるで',
        'inspector.empty.hash': 'ファイル選んだらハッシュ出したるで',

        'preview.imagePreview': 'プレビュー',
        'preview.noSelection': 'なんか選んでや',
        'preview.size': '大きさ',
        'preview.date': 'いつのん',
        'preview.location': 'どこやねん (GPS)',
        'preview.gpsYes': '場所わかるで',
        'preview.gpsNo': 'わからんわ',
        'preview.exifTitle': 'ExifTool の中身やで',

        'organize.title': 'ええ感じにする',
        'organize.filter': '条件に合うやつだけ残す',
        'organize.highlight': '条件に合うやつ目立たせる',
        'organize.date': 'いつのん',
        'organize.location': 'どこやねん',
        'organize.filterAny': 'なんでも',
        'organize.filterHas': 'あり',
        'organize.filterNone': 'なし',
        'organize.stats': '{shown} 件出てる · {selected} 件選んでる',

        'settings.title': '設定',
        'settings.batch': 'まとめてやる',
        'settings.fixDates': '日時ちゃんとして (更新日時に合わせる)',
        'settings.language': '言葉 (Language)',
        'settings.wip': '今つくってるとこやねん',

        'queue.title': '処理キュー',
        'queue.ready': '待っとるで',
        'queue.wip': '今つくってるとこやねん',

        'wip.title': '􀣋  今つくってるとこやねん',
        'wip.body': 'この機能はまだできてへんねん. ちょっと待っといてや.',

        'alert.noInfo.title': 'いらんで',
        'alert.noInfo.body': '全部のファイル、もうええ感じの日時入ってるで。',
        'alert.error.title': 'エラー',
        'alert.error.body': '日時更新、失敗したわ。',

        'noDate': '日時なし',
        'unknown': '知らんけど',
    },
};

// ─── Locale Detection ──────────────────────────────────────────────────────

/**
 * Detect the current locale from the system.
 * Falls back to 'en' for any unrecognised locale.
 */
function detectLocale(): Locale {
    // React Native exposes the device locale via NativeModules or I18nManager,
    // but `Intl` is the most reliable cross-platform approach here.
    try {
        const tag = Intl.DateTimeFormat().resolvedOptions().locale ?? '';
        if (tag.startsWith('ja')) return 'ja';
        // Add more locales here as needed
    } catch (_) { }
    return 'en';
}

let _locale: Locale = detectLocale();

/** Override the locale at runtime (e.g., from user settings). */
export function setLocale(locale: Locale): void {
    _locale = locale;
}

export function getLocale(): Locale {
    return _locale;
}

// ─── Translation Function ──────────────────────────────────────────────────

/**
 * Translate a key using the current locale.
 * Supports simple {placeholder} interpolation.
 *
 * @example
 *   t('organize.stats', { shown: 42, selected: 3 })
 *   // "42 件表示 · 3 件選択" (in ja)
 */
export function t(key: string, vars?: Record<string, string | number>): string {
    const table = strings[_locale] ?? strings.en;
    let value = table[key] ?? strings.en[key] ?? key;
    if (vars) {
        for (const [k, v] of Object.entries(vars)) {
            value = value.replaceAll(`{${k}}`, String(v));
        }
    }
    return value;
}
