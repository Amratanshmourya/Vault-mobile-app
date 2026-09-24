enum SmartCollectionType {
  all('All Items', '🗄️'),
  passkeys('Passkeys', '🛡️'),
  favorites('Favorites', '⭐'),
  weak('Weak Passwords', '⚠️'),
  reused('Reused Passwords', '🔄'),
  old('Older than 180 Days', '⏳'),
  missing2FA('Missing 2FA', '🔐'),
  files('Encrypted Files', '📎'),
  trash('Trash', '🗑️');

  final String label;
  final String icon;
  const SmartCollectionType(this.label, this.icon);
}
