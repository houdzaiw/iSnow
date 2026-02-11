import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AgreePolicyPage extends HookConsumerWidget {
  const AgreePolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null,
      backgroundColor: const Color(0xFFFDF5EB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/base_bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    // 标题
                    const Text(
                      'Please read and agree',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 内容
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF212121),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'In order to better protect your rights and interests,please read and agree to the ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: Color(0xFFFF8000),
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.push(
                                    '/web-view?title=Terms of Service&uri=https://www.example.com/terms-of-service',
                                  );
                                },
                            ),
                            const TextSpan(
                              text: ' and ',
                            ),
                            TextSpan(
                              text: 'Privacy policy',
                              style: const TextStyle(
                                color: Color(0xFFFF8000),
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.push(
                                    '/web-view?title=Privacy Policy&uri=https://www.example.com/privacy-policy',
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Agree to Continue 按钮
                    GestureDetector(
                      onTap: () {
                        // 同意并继续
                        context.pop();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 53,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9E707),
                          borderRadius: BorderRadius.circular(53 / 2),
                        ),
                        child: const Text(
                          'Agree to Continue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Disagree 按钮
                    GestureDetector(
                      onTap: () {
                        // 不同意
                        context.pop();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 53,
                        alignment: Alignment.center,
                        child: const Text(
                          'Disagree',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF969696),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              // 关闭按钮
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    context.pop();
                  },
                  child: Image.asset(
                    'assets/base/close_button_image.png',
                    width: 32,
                    height: 32,
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

