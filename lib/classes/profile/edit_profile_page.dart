import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../configs/consts.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
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
    if (_nicknameController.text.isEmpty) {
      _nicknameController.text = context.l10n.t('profile.nickname');
    }

    return CustomScaffold(
      title: context.l10n.t('profile.editProfile'),
      rightText: context.l10n.t('app.save'),
      onRightIconTap: () {
        if (_formKey.currentState!.validate()) {
          // 保存逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.t('profile.saved'))),
          );
          context.pop();
        }
      },
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.cardBorder,
            boxShadow: AppShadows.soft,
          ),
          child: Form(
            key: _formKey,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: 4,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final items = [
                  _buildProfileItem(
                    context,
                    title: context.l10n.t('profile.avatar'),
                    onTap: () => showAvatarOptions(context),
                    showAvatar: true,
                  ),
                  _buildProfileItem(
                    context,
                    title: context.l10n.t('profile.nickname'),
                    onTap: () => _navigateToEditNickname(context),
                    valueText: _nicknameController.text,
                  ),
                  _buildProfileItem(
                    context,
                    title: context.l10n.t('profile.gender'),
                    onTap: () => _showGenderPicker(context),
                    valueWidget: _selectedGender != null
                        ? Image.asset(
                            _selectedGender == 'male'
                                ? AppAssets.profileMaleIcon
                                : AppAssets.profileFemaleIcon,
                            width: 20,
                            height: 20,
                          )
                        : null,
                  ),
                  _buildProfileItem(
                    context,
                    title: context.l10n.t('profile.birthday'),
                    onTap: () => _showBirthdayPicker(context),
                    valueText: _selectedBirthday != null
                        ? '${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}'
                        : null,
                  ),
                ];
                return items[index];
              },
            ),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.avatarPlaceholder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textInverse,
                      size: 20,
                    ),
                  ),
                if (valueText != null)
                  Text(valueText, style: AppTextStyles.hint),
                if (valueWidget != null) valueWidget,
                const SizedBox(width: AppSpacing.sm),
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
          backgroundColor: AppColors.cardBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardBorder,
          ),
          title: Text(
            context.l10n.t('profile.chooseGender'),
            style: AppTextStyles.title,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.male, color: AppColors.primaryPink),
                title: Text(
                  context.l10n.t('profile.male'),
                  style: AppTextStyles.bodyStrong,
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedGender = 'male';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('profile.selectedMale')),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.female, color: AppColors.primaryPink),
                title: Text(
                  context.l10n.t('profile.female'),
                  style: AppTextStyles.bodyStrong,
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedGender = 'female';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('profile.selectedFemale')),
                    ),
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
