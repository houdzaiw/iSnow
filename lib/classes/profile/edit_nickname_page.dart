import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class EditNicknamePage extends StatefulWidget {
  const EditNicknamePage({super.key});

  @override
  State<EditNicknamePage> createState() => _EditNicknamePageState();
}

class _EditNicknamePageState extends State<EditNicknamePage> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_nicknameController.text.isEmpty) {
      _nicknameController.text = context.l10n.t('profile.nickname');
    }

    return CustomScaffold(
      title: context.l10n.t('profile.editNickname'),
      rightText: context.l10n.t('app.save'),
      onRightIconTap: () {
        if (_formKey.currentState!.validate()) {
          // 保存昵称逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.t('profile.nicknameSaved', {
                  'nickname': _nicknameController.text,
                }),
              ),
            ),
          );
          context.pop();
        }
      },
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppRadius.cardBorder,
                  boxShadow: AppShadows.soft,
                ),
                child: TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    hintText: context.l10n.t('profile.nicknameHint'),
                    hintStyle: AppTextStyles.hint,
                  ),
                  style: AppTextStyles.bodyStrong,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.t('profile.nicknameRequired');
                    }
                    if (value.length > 20) {
                      return context.l10n.t('profile.nicknameTooLong');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xl),
                child: Text(
                  context.l10n.t('profile.nicknameRule'),
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
