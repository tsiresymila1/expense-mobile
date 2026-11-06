String normalizeDisplayName(String value) {
  final normalized = value.trim();
  if (normalized.length < 2) {
    throw ArgumentError.value(value, 'value', 'Name must contain 2 characters');
  }
  return normalized;
}

String resolveDisplayName({
  required String email,
  String? profileName,
  Map<String, dynamic> metadata = const {},
}) {
  final profile = profileName?.trim();
  if (profile != null && profile.isNotEmpty) return profile;

  final metadataName = metadata['name'];
  if (metadataName is String && metadataName.trim().isNotEmpty) {
    return metadataName.trim();
  }

  final emailPrefix = email.split('@').first.trim();
  return emailPrefix.isEmpty ? email : emailPrefix;
}
