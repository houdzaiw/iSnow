import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_scaffold.dart';
import '../../configs/consts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController(text: 'Username');
  final _bioController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthday;

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
      body: Container(
        //圆角， 白色背景
        margin: const EdgeInsets.only(left: 16, right: 16, top: 20),
        height: 52 * 4 + 3, // 四个条目高度加间隔
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            children: [
              _buildProfileItem(
                context,
                title: 'Avatar',
                onTap: () => showAvatarOptions(context),
                showAvatar: true,
              ),
              Container(
                height: 0.5,
                color: const Color(0xFFE0E0E0),
              ),
              _buildProfileItem(
                context,
                title: 'Nickname',
                onTap: () => _navigateToEditNickname(context),
              ),
              Container(
                height: 0.5,
                color: const Color(0xFFE0E0E0),
              ),
              _buildProfileItem(
                context,
                title: 'Gender',
                onTap: () => _showGenderPicker(context),
                valueWidget: _selectedGender != null
                    ? Image.asset(
                  _selectedGender == 'Male'
                      ? 'assets/profile/male_icon.png'
                      : 'assets/profile/female_icon.png',
                  width: 20,
                  height: 20,
                )
                    : null,
              ),
              Container(
                height: 0.5,
                color: const Color(0xFFE0E0E0),
              ),
              _buildProfileItem(
                context,
                title: 'Birthday',
                onTap: () => _showBirthdayPicker(context),
                valueText: _selectedBirthday != null
                    ? '${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    String? valueText,
    Widget? valueWidget,
    bool showAvatar = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Row(
              children: [
                if (showAvatar)
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                if (valueText != null)
                  Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                if (valueWidget != null) valueWidget,
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFF9E707),
                ),
              ],
            ),
          ],
        ),
      ),
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
                  setState(() {
                    _selectedGender = 'Male';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Male selected')),
                  );
                },
              ),
              ListTile(
                title: const Text('Female'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedGender = 'Female';
                  });
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
    final DateTime firstDate = DateTime(1950, 1, 1);
    final DateTime lastDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    DateTime initial = _selectedBirthday ?? DateTime(2000, 1, 1);
    // Ensure initial is within allowed range
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      // lastDate为当前日期减去18年
      lastDate: lastDate,
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
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }
}
