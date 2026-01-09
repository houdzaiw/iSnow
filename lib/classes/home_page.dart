// dart
import 'package:flutter/material.dart';

import '../widgets/custom_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9E707),
      body: Container(
        margin: EdgeInsets.only(
          left: 22,
          right: 22,
          top: MediaQuery.of(context).padding.top + 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFF9E707),
            width: 2,
          ),
        ),
        child: Center(
        ),
      ),
    );
  }

}
