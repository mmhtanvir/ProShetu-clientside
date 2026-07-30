/// Central asset registry. Never reference raw asset paths in widgets.
abstract final class AppAssets {
  static const String _icons = 'assets/icons';
  static const String _images = 'assets/images';

  static const String logoShield = '$_icons/logo_shield.svg';

  // Prevent unused warnings until image assets land.
  // ignore: unused_field
  static const String _reservedImages = _images;
}
