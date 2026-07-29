import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../configs/consts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController(text: '用户昵称');
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
      title: '编辑资料',
      rightText: '保存',
      onRightIconTap: () {
        if (_formKey.currentState!.validate()) {
          // 保存逻辑
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('保存成功')));
          context.pop();
        }
      },
      body: Container(
        //圆角， 白色背景
        margin: const EdgeInsets.only(left: 16, right: 16, top: 20),
        height: 52 * 4 + 20, // 四个条目高度加间隔
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.fieldBorder,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            children: [
              _buildProfileItem(
                context,
                title: '头像',
                onTap: () => showAvatarOptions(context),
                showAvatar: true,
              ),
              Container(height: 0.5, color: AppColors.border),
              _buildProfileItem(
                context,
                title: '昵称',
                onTap: () => _navigateToEditNickname(context),
              ),
              Container(height: 0.5, color: AppColors.border),
              _buildProfileItem(
                context,
                title: '性别',
                onTap: () => _showGenderPicker(context),
                valueWidget: _selectedGender != null
                    ? Image.asset(
                        _selectedGender == '男'
                            ? AppAssets.profileMaleIcon
                            : AppAssets.profileFemaleIcon,
                        width: 20,
                        height: 20,
                      )
                    : null,
              ),
              Container(height: 0.5, color: AppColors.border),
              _buildProfileItem(
                context,
                title: '生日',
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
        decoration: const BoxDecoration(color: AppColors.cardBackground),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bodyStrong),
            Row(
              children: [
                if (showAvatar)
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.avatarPlaceholder,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.textInverse,
                        size: 20,
                      ),
                    ),
                  ),
                if (valueText != null)
                  Text(valueText, style: AppTextStyles.hint),
                if (valueWidget != null) valueWidget,
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primaryPink,
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
          title: const Text('选择性别'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('男'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedGender = '男';
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已选择男')));
                },
              ),
              ListTile(
                title: const Text('女'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedGender = '女';
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已选择女')));
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
    final DateTime lastDate = DateTime.now().subtract(
      const Duration(days: 365 * 18),
    );
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
              primary: AppColors.primaryPink,
              onPrimary: AppColors.textInverse,
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
