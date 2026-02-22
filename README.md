# kkImg
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

Re-encode images, change or add date information.

![Screenshot](s/image-200.avif)

## Version 2.x (React Native for macOS)

This project has been rewritten from the ground up using React Native for macOS.
The goal of version 2.0 is to establish a robust, native-feeling user interface with deep OS integration (such as native drag-and-drop, multi-selection, and native thumbnail rendering). 

Currently, the focus is purely on the UI, and most core logic from the 1.x Python era has not yet been ported. 
A Windows version is planned for the future.

### Feature Parity & Implementation Status

| Feature | v1 (Python/Flet) | v2 (React Native for macOS) |
| :--- | :---: | :---: |
| Native macOS UI / UX | ❌ | ✅ |
| Native Drag & Drop from/to Finder | ❌ | ✅ |
| Native Thumbnail Rendering | ❌ | ✅ |
| Custom Kansai Dialect | ❌ | ✅ |
| Window Shade | ❌ | ✅ |
| Batch Convert to AVIF (`avifenc`) | ✅ | (Coming Soon) |
| Convert via Magick fallback | ✅ | (Coming Soon) |
| Parse Date from filenames | ✅ | (Coming Soon) |
| Write EXIF Dates (`exiftool`) | ✅ | (Coming Soon) |
| Deduplication Hash generation | ❌ | (Coming Soon) |
