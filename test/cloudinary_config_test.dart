import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/constants/cloudinary_config.dart';

void main() {
  group('CloudinaryConfig', () {
    test('uses real upload configuration values', () {
      expect(CloudinaryConfig.cloudName, isNot(contains('YOUR_')));
      expect(CloudinaryConfig.uploadPreset, isNot(contains('YOUR_')));
      expect(CloudinaryConfig.uploadUrl, contains(CloudinaryConfig.cloudName));
      expect(CloudinaryConfig.uploadUrl, contains('/image/upload'));
    });
  });
}
