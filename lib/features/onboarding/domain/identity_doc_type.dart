/// Identity document options for verification.
enum IdentityDocType {
  nid(requiredImages: 2),
  birthCertificate(requiredImages: 1);

  const IdentityDocType({required this.requiredImages});

  /// NID needs front + back; birth certificate needs one photo.
  final int requiredImages;
}
