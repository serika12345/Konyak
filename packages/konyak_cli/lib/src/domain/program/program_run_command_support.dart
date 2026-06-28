bool isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}

String winedbgAttachProcessId(String processId) {
  final normalized = processId.trim();
  if (normalized.startsWith(RegExp('0x', caseSensitive: false))) {
    return normalized;
  }
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
    return '0x$normalized';
  }

  return normalized;
}
