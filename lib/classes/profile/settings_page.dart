import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScaffold(
      title: '设置',
      body: Center(
        child: Text(
          '暂无更多设置',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
