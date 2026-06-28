class CloudinaryConfig {
  CloudinaryConfig._();
  static const String cloudName    = 'YOUR_CLOUD_NAME';   // replace
  static const String uploadPreset = 'YOUR_PRESET_NAME';  // replace
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}