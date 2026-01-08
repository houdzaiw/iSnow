import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_scaffold.dart';

class EditNicknamePage extends StatefulWidget {
  const EditNicknamePage({super.key});

  @override
  State<EditNicknamePage> createState() => _EditNicknamePageState();
}

class _EditNicknamePageState extends State<EditNicknamePage> {
  final _nicknameController = TextEditingController(text: 'Username');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Edit Nickname',
      rightText: 'Save',
      onRightIconTap: () {
        if (_formKey.currentState!.validate()) {
          // 保存昵称逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nickname saved: ${_nicknameController.text}')),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your nickname',
                    hintStyle: TextStyle(color: Color(0xFF999999)),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF212121),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nickname cannot be empty';
                    }
                    if (value.length > 20) {
                      return 'Nickname cannot exceed 20 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Nickname should be 1-20 characters',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

