import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final cloudinary = CloudinaryPublic(
    'dqthwfibc', // seu cloud name do print
    'ml_default', // seu upload preset do print
  );

  Future<List<String>> uploadImages(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder:
              'propertask/propriedades', // opcional: organiza suas imagens numa pasta
        ),
      );
      urls.add(response.secureUrl);
    }
    return urls;
  }
}
