import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../configs/consts.dart';
import '../../localization/app_localizations.dart';
import '../../model/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import '../oauth/provider/login_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _loginProvider = LoginProvider();
  final _imagePicker = ImagePicker();

  UserData? _user;
  String _avatar = '';
  int _selectedGender = 0;
  DateTime? _selectedBirthday;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final cached = await _loginProvider.cachedUser();
      if (cached != null && mounted) {
        _applyUser(cached);
      }
      final remote = await _loginProvider.getMyUserInfo();
      if (mounted) {
        _applyUser(remote);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.t('profile.loadFailed'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyUser(UserData user) {
    setState(() {
      _user = user;
      _avatar = user.avatar ?? '';
      _selectedGender = user.gender;
      if (_nicknameController.text.isEmpty) {
        _nicknameController.text =
            user.nick ?? context.l10n.t('profile.nickname');
      }
      if (_bioController.text.isEmpty) {
        _bioController.text = user.userDesc ?? '';
      }
      final birth = user.birth;
      if (birth != null && birth > 0) {
        _selectedBirthday = DateTime.fromMillisecondsSinceEpoch(birth);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = await _loginProvider.modifyUser(
        nick: _nicknameController.text.trim(),
        gender: _selectedGender,
        avatar: _avatar,
        signature: _bioController.text.trim(),
        birth: _birthValue(),
      );
      if (!mounted) return;
      _applyUser(updated);
      _showMessage(context.l10n.t('profile.saved'));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  int _birthValue() {
    if (_selectedBirthday != null) {
      return _selectedBirthday!.millisecondsSinceEpoch;
    }
    return _user?.birth ?? 0;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: context.l10n.t('profile.editProfile'),
      rightText: _isSaving
          ? context.l10n.t('app.saving')
          : context.l10n.t('app.save'),
      onRightIconTap: _isSaving ? null : _saveProfile,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Align(
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
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    children: [
                      _buildProfileItem(
                        context,
                        title: context.l10n.t('profile.avatar'),
                        onTap: () => _showAvatarOptions(context),
                        showAvatar: true,
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildEditableText(
                        context,
                        title: context.l10n.t('profile.nickname'),
                        controller: _nicknameController,
                        hintText: context.l10n.t('profile.nicknameHint'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.t('profile.nicknameRequired');
                          }
                          if (value.trim().length > 20) {
                            return context.l10n.t('profile.nicknameTooLong');
                          }
                          return null;
                        },
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildProfileItem(
                        context,
                        title: context.l10n.t('profile.gender'),
                        onTap: () => _showGenderPicker(context),
                        valueText: _genderLabel(context, _selectedGender),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildProfileItem(
                        context,
                        title: context.l10n.t('profile.birthday'),
                        onTap: () => _showBirthdayPicker(context),
                        valueText: _selectedBirthday != null
                            ? _formatDate(_selectedBirthday!)
                            : context.l10n.t('profile.notSet'),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildReadOnlyItem(
                        context,
                        title: context.l10n.t('profile.countryRegion'),
                        value: _user?.countryCode ?? _user?.region ?? '--',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildReadOnlyItem(
                        context,
                        title: context.l10n.t('profile.phone'),
                        value: _user?.phone == null
                            ? '--'
                            : '+${_user?.areaCode ?? ''} ${_user!.phone}',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildReadOnlyItem(
                        context,
                        title: context.l10n.t('profile.userId'),
                        value: _user?.uid?.toString() ?? '--',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildBioField(context),
                    ],
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
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showAvatar) _AvatarPreview(avatar: _avatar),
                  if (valueText != null)
                    Flexible(
                      child: Text(
                        valueText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.hint,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryPink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableText(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: title, hintText: hintText),
        validator: validator,
      ),
    );
  }

  Widget _buildReadOnlyItem(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.hint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: TextFormField(
        controller: _bioController,
        maxLines: 3,
        maxLength: 120,
        decoration: InputDecoration(
          labelText: context.l10n.t('profile.bio'),
          hintText: context.l10n.t('profile.bioHint'),
        ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showAvatarOptions(
      context,
      onAlbumSelected: () => _pickAndUploadAvatar(ImageSource.gallery),
      onCameraSelected: () => _pickAndUploadAvatar(ImageSource.camera),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      final avatarPath = await _loginProvider.uploadAvatarFile(image.path);
      if (!mounted) return;
      setState(() => _avatar = avatarPath);
      _showMessage(context.l10n.t('profile.avatarUploaded'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(context.l10n.t('profile.avatarUploadFailed'));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                  setState(() => _selectedGender = 1);
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
                  setState(() => _selectedGender = 2);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBirthdayPicker(BuildContext context) async {
    final firstDate = DateTime(1950, 1, 1);
    final lastDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    var initial = _selectedBirthday ?? DateTime(2000, 1, 1);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
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
    if (picked != null && mounted) {
      setState(() => _selectedBirthday = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _genderLabel(BuildContext context, int gender) {
    return switch (gender) {
      1 => context.l10n.t('profile.male'),
      2 => context.l10n.t('profile.female'),
      _ => context.l10n.t('profile.notSet'),
    };
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.avatarPlaceholder,
        shape: BoxShape.circle,
      ),
      child: avatar.isEmpty || !avatar.startsWith('http')
          ? const Icon(Icons.person, color: AppColors.textInverse, size: 20)
          : Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person,
                color: AppColors.textInverse,
                size: 20,
              ),
            ),
    );
  }
}
