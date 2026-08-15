import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Picks an image from the device (gallery or camera) and returns its raw
/// bytes, or null when the user cancels.
///
/// The gallery path relies on the modern system photo picker, so on Android 11+
/// no storage permission is needed and on iOS the caller's photo-library
/// usage description is used. Camera uses the system camera app. This class is
/// kept tiny and injectable so widget tests can supply a fake: the native
/// picker cannot run under `flutter test`.
class AvatarImagePicker {
  final ImagePicker? _picker;

  const AvatarImagePicker({ImagePicker? picker}) : _picker = picker;

  ImagePicker get _instance => _picker ?? ImagePicker();

  /// Raw bytes of the picked image, or null when the user dismisses the picker.
  Future<Uint8List?> pickGallery() => _pick(ImageSource.gallery);

  /// Raw bytes of the captured photo, or null when the user cancels.
  Future<Uint8List?> pickCamera() => _pick(ImageSource.camera);

  Future<Uint8List?> _pick(ImageSource source) async {
    final XFile? file = await _instance.pickImage(source: source);
    return file?.readAsBytes();
  }
}