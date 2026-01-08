import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_scaffold.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController(text: 'Username');
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Edit Profile',
      rightText: 'Save',
      onRightIconTap: () {
        if (_formKey.currentState!.validate()) {
          // 保存逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save successful!')),
          );
          context.pop();
        }
      },
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileItem(
              context,
              title: 'Avatar',
              onTap: () => _showAvatarOptions(context),
            ),
            const SizedBox(height: 12),
            _buildProfileItem(
              context,
              title: 'Nickname',
              onTap: () => _navigateToEditNickname(context),
            ),
            const SizedBox(height: 12),
            _buildProfileItem(
              context,
              title: 'Gender',
              onTap: () => _showGenderPicker(context),
            ),
            const SizedBox(height: 12),
            _buildProfileItem(
              context,
              title: 'Birthday',
              onTap: () => _showBirthdayPicker(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, {required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF212121),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Album'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement image picker from gallery
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Album selected')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement image picker from camera
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera selected')),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEditNickname(BuildContext context) {
    context.push('/edit-nickname');
  }

  void _showGenderPicker(BuildContext context) {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Male'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Male selected')),
                  );
                },
              ),
              ListTile(
                title: const Text('Female'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Female selected')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBirthdayPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      //lastDate为当前日期减去18年
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF9E707),
              onPrimary: Color(0xFF212121),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Birthday selected: ${picked.year}-${picked.month}-${picked.day}')),
      );
    }
  }
}

