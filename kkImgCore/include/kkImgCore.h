#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Execute exiftool with the given arguments (passed as a JSON array string).
 *
 * @param args_json  A JSON array of argument strings, e.g. ["-ver"] or
 *                   ["-overwrite_original", "-AllDates<FileModifyDate", "/path/to/file.jpg"].
 *                   Do NOT include "exiftool" itself; the library prepends it.
 * @return           A heap-allocated JSON string of the form:
 *                   {"stdout":"...","stderr":"...","exitCode":0}
 *                   The caller MUST free this pointer with kkimg_free_string().
 *                   Returns NULL on allocation failure.
 */
char* kkimg_exiftool_execute(const char* args_json);

/**
 * Free a string returned by kkimg_exiftool_execute().
 */
void kkimg_free_string(char* ptr);

#ifdef __cplusplus
}
#endif
