import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class ImagePickerSheet extends StatefulWidget {
  const new({super.key});

  static Future<ImageSource?> pick(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) {
        return ImagePickerSheet();
      },
    );
  }

  @override
  State<ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<ImagePickerSheet> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text("Camera"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Gallery"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
