import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final cloudinary = CloudinaryPublic('seu_cloud_name', 'seu_upload_preset');

  Future<List<String>> uploadImages(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: 'propertask/propriedades'),
      );
      urls.add(response.secureUrl);
    }
    return urls;
  }
}
