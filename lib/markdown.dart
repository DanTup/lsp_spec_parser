final _typeScriptBlockPattern =
    new RegExp(r'\n```typescript([\S\s]*?)\n```', multiLine: true);

/// Extracts fenced code blocks that are explicitly marked as TypeScript from a
/// markdown document.
List<String> extractTypeScriptBlocks(String text) {
  return _typeScriptBlockPattern
      .allMatches(text)
      .map((m) => m.group(1).trim())
      .toList();
}
