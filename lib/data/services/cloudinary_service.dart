// ═══════════════════════════════════════════════════════════════════════════
// CLOUDINARY PROFILE IMAGE — STEP-BY-STEP GUIDE
// ═══════════════════════════════════════════════════════════════════════════
//
// STEP 1 ─ Create a free Cloudinary account
// ──────────────────────────────────────────
// 1. Go to https://cloudinary.com/users/register/free
// 2. Sign up → Dashboard → note your:
//      - Cloud Name   (e.g. "edumanage123")
//      - API Key      (e.g. "748392018283...")
//      - API Secret   (keep this PRIVATE — never put it in Flutter code)
//
// STEP 2 ─ Create an Upload Preset (UNSIGNED — for mobile)
// ─────────────────────────────────────────────────────────
// 1. Dashboard → Settings → Upload → "Upload presets" → Add upload preset
// 2. Signing mode: "Unsigned"
// 3. Folder: "profile_photos"    (optional but keeps things tidy)
// 4. Allowed formats: jpg, png, webp
// 5. Incoming transformations:
//      - Resize: crop = fill, width = 400, height = 400, gravity = face
//        (auto-centers on the face and squares the avatar)
// 6. Click Save → copy the Preset Name  (e.g. "edumanage_avatars")
//
// STEP 3 ─ Add dependency
// ────────────────────────
// pubspec.yaml:
//   dependencies:
//     http: ^1.2.1          # already in most projects
//     image_picker: ^1.1.2  # already used in profile_screen.dart
//
// Run: flutter pub get
//
// STEP 4 ─ Add Cloudinary config to your .env / app constants
// ────────────────────────────────────────────────────────────
// Create lib/core/constants/cloudinary_config.dart with CloudinaryConfig class.
//
// STEP 5 ─ Create the upload service (this file)
// ───────────────────────────────────────────────
// Save as: lib/data/services/cloudinary_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:school_management_system/core/constants/cloudinary_config.dart';

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  /// Uploads [file] to Cloudinary and returns the secure HTTPS URL.
  ///
  /// Uses an unsigned upload preset — no API secret is needed on the
  /// client, which is safe for mobile apps. The preset is configured in
  /// the Cloudinary dashboard to restrict folder and apply transformations.
  ///
  /// [publicId] becomes the filename on Cloudinary. Using the user's UID
  /// makes every upload idempotent — re-uploading replaces the same asset
  /// instead of creating duplicates. Cloudinary appends a version number
  /// automatically so the URL changes on each update, busting caches.
  Future<String> uploadProfilePhoto({
    required File file,
    required String uid,
  }) async {
    final uri = Uri.parse(CloudinaryConfig.uploadUrl);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['public_id'] = 'profile_photos/$uid'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        // Cloudinary auto-detects image type from the file header —
        // no Content-Type header is needed here.
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} — ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // secure_url is always HTTPS and includes a version parameter
    return json['secure_url'] as String;
  }
}

// STEP 6 ─ Replace the Firebase Storage upload in profile_screen.dart
// ────────────────────────────────────────────────────────────────────
// Find _pickAndUploadPhoto() in profile_screen.dart and replace the
// upload section (lines starting with "final ref2 = ...") with:
//
//   Future<void> _pickAndUploadPhoto() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 75,
//       maxWidth: 800,    // reduce bandwidth before upload
//       maxHeight: 800,
//     );
//     if (picked == null) return;
//
//     setState(() => _uploadingPhoto = true);
//     try {
//       final uid = ref.read(authProvider).user?.uid;
//       if (uid == null) return;
//
//       // ── Upload to Cloudinary ────────────────────────────────
//       final url = await CloudinaryService.instance.uploadProfilePhoto(
//         file: File(picked.path),
//         uid: uid,
//       );
//
//       // ── Save URL to Firestore + Firebase Auth ───────────────
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .update({'photoUrl': url});
//       await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
//
//       ref.invalidate(_profileProvider);
//
//       if (mounted) _showSnack('Profile photo updated', AppColors.success);
//     } catch (e) {
//       if (mounted) _showSnack('Upload failed: $e', AppColors.danger);
//     } finally {
//       if (mounted) setState(() => _uploadingPhoto = false);
//     }
//   }
//
// STEP 7 ─ Display the Cloudinary URL anywhere an image is shown
// ──────────────────────────────────────────────────────────────
// The URL returned is a standard HTTPS link — just pass it to Image.network:
//
//   Image.network(
//     profile.photoUrl,
//     fit: BoxFit.cover,
//     // Add a resize transformation right in the URL for thumbnails:
//     // replace '/upload/' with '/upload/w_100,h_100,c_fill,g_face/'
//     errorBuilder: (_, __, ___) => _avatarFallback(profile.name),
//   )
//
// STEP 8 ─ Optional: resize on-the-fly via URL transformations
// ─────────────────────────────────────────────────────────────
// Cloudinary lets you resize images by editing the URL — no re-upload needed.
//
// Original:  https://res.cloudinary.com/demo/image/upload/profile_photos/abc.jpg
// Thumbnail: https://res.cloudinary.com/demo/image/upload/w_80,h_80,c_fill/profile_photos/abc.jpg
//
// Helper function to add:
//
//   String cloudinaryThumb(String url, {int size = 80}) {
//     return url.replaceFirst(
//       '/upload/',
//       '/upload/w_$size,h_$size,c_fill,g_face,q_auto,f_auto/',
//     );
//   }
//
//   // Usage:
//   Image.network(cloudinaryThumb(profile.photoUrl, size: 100))
//
// ═══════════════════════════════════════════════════════════════════════════
// FIREBASE STORAGE vs CLOUDINARY — COMPARISON
// ═══════════════════════════════════════════════════════════════════════════
// Feature              Firebase Storage        Cloudinary (free tier)
// ─────────────────────────────────────────────────────────────────────────
// Free storage         5 GB                    25 GB
// Free bandwidth       1 GB/day                25 GB/month
// On-the-fly resize    No (manual only)        Yes (URL params)
// Auto face-crop       No                      Yes (g_face)
// WebP conversion      No                      Yes (f_auto)
// Setup in Flutter     firebase_storage pkg    Just http package
// Auth required        Yes (Storage Rules)     No (unsigned preset)
// ─────────────────────────────────────────────────────────────────────────
// Verdict: Cloudinary is recommended for profile avatars — better free tier,
// auto transformations, and no Firebase Storage Rules to configure.
// ═══════════════════════════════════════════════════════════════════════════