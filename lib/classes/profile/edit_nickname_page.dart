import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class EditNicknamePage extends StatefulWidget {
  const EditNicknamePage({super.key});

  @override
  State<EditNicknamePage> createState() => _EditNicknamePageState();
}

class _EditNicknamePageState extends State<EditNicknamePage> {
  final _nicknameController = TextEditingController(text: '用户昵称');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: '编辑昵称',
      rightText: '保存',
      onRightIconTap: () {
        if (_formKey.currentState!.validate()) {
          // 保存昵称逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('昵称已保存：${_nicknameController.text}')),
          );
          context.pop();
        }
      },
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppRadius.fieldBorder,
                ),
                child: TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '请输入昵称',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '昵称不能为空';
                    }
                    if (value.length > 20) {
                      return '昵称不能超过20个字符';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '昵称长度为1-20个字符',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
