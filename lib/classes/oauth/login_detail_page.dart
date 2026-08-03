import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../model/country_info.dart';
import '../../model/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/agreement_links_text.dart';
import '../../widgets/country_picker_sheet.dart';
import 'provider/login_provider.dart';

class LoginDetailPage extends HookConsumerWidget {
  const LoginDetailPage({
    super.key,
    this.initialAreaCode,
    this.initialCountryCode,
  });

  final String? initialAreaCode;
  final String? initialCountryCode;

  CountryDialOption _initialCountry() {
    final initialIsoCode = initialCountryCode?.trim().toUpperCase();
    final fallbackCountry = CountryInfo.fallbackList.firstWhere(
      (country) => country.isoCode.toUpperCase() == initialIsoCode,
      orElse: () => CountryInfo.saudiArabia,
    );
    final areaCode = initialAreaCode?.trim();
    return CountryDialOption.fromCountryInfo(
      fallbackCountry,
    ).copyWith(areaCode: areaCode?.isNotEmpty == true ? areaCode : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController();
    final passwordController = useTextEditingController();
    final loginProvider = useMemoized(() => LoginProvider());
    final isLoading = useState(false);
    final isCheckingUser = useState(false);
    final agreementAccepted = useState(true);
    final selectedCountry = useState(_initialCountry());
    final countryOptions = useState(
      CountryInfo.fallbackList.map(CountryDialOption.fromCountryInfo).toList(),
    );
    final hasUserResult = useState<HasUserResponse?>(null);
    final phoneStatusText = useState<String?>(null);
    final debounceRef = useRef<Timer?>(null);

    Future<HasUserResponse?> checkUserStatus() async {
      final phone = phoneController.text.trim();
      final checkingText = context.l10n.t('auth.checkingUser');
      final existsText = context.l10n.t('auth.userExists');
      final notFoundText = context.l10n.t('auth.userNotFound');
      final failedText = context.l10n.t('auth.userCheckFailed');
      if (phone.length < 6) {
        hasUserResult.value = null;
        phoneStatusText.value = null;
        return null;
      }

      isCheckingUser.value = true;
      phoneStatusText.value = checkingText;
      try {
        final result = await loginProvider.hasUser(
          phone: phone,
          areaCode: selectedCountry.value.areaCode,
        );
        hasUserResult.value = result;
        phoneStatusText.value = result.hasUser ? existsText : notFoundText;
        return result;
      } catch (e) {
        hasUserResult.value = null;
        phoneStatusText.value = failedText;
        return null;
      } finally {
        isCheckingUser.value = false;
      }
    }

    useEffect(() {
      var cancelled = false;

      Future<void> loadCountries() async {
        try {
          final supportedCountries = await loginProvider
              .getSupportedCountries();
          if (!cancelled && supportedCountries.isNotEmpty) {
            countryOptions.value = supportedCountries
                .map(CountryDialOption.fromCountryInfo)
                .toList();
          }
        } catch (_) {
          // Keep local fallback when the country endpoint is unavailable.
        }
      }

      unawaited(loadCountries());

      void onPhoneChanged() {
        debounceRef.value?.cancel();
        debounceRef.value = Timer(const Duration(milliseconds: 600), () {
          unawaited(checkUserStatus());
        });
      }

      phoneController.addListener(onPhoneChanged);
      return () {
        cancelled = true;
        debounceRef.value?.cancel();
        phoneController.removeListener(onPhoneChanged);
      };
    }, [phoneController]);

    Future<void> showCountryPicker() async {
      final country = await CountryPickerSheet.show(
        context,
        countries: countryOptions.value,
        selectedCountryCode: selectedCountry.value.countryCode,
      );

      if (country != null && context.mounted) {
        selectedCountry.value = country;
        unawaited(checkUserStatus());
      }
    }

    Future<void> handleLogin() async {
      final phone = phoneController.text.trim();
      final password = passwordController.text.trim();
      final passwordRequiredText = context.l10n.t('auth.passwordRequired');

      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('auth.phoneRequired'))),
        );
        return;
      }

      if (!agreementAccepted.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('auth.agreementRequired'))),
        );
        return;
      }

      final currentHasUser = hasUserResult.value ?? await checkUserStatus();
      if (currentHasUser == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('auth.userCheckFailed'))),
        );
        return;
      }

      final country = selectedCountry.value;
      if (!currentHasUser.hasUser) {
        if (!context.mounted) return;
        context.push(
          '/register?phone=${Uri.encodeQueryComponent(phone)}'
          '&areaCode=${Uri.encodeQueryComponent(country.areaCode)}'
          '&countryCode=${Uri.encodeQueryComponent(country.countryCode)}',
        );
        return;
      }

      if (password.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(passwordRequiredText)));
        return;
      }

      isLoading.value = true;

      try {
        final response = await loginProvider.login(
          account: phone,
          password: password,
          loginType: 5,
          areaCode: country.areaCode,
          countryCode: country.countryCode,
        );

        if (!context.mounted) return;

        if (response.success) {
          if (response.token != null) {
            debugPrint('Token: ${response.token}');
          }

          if (response.data != null) {
            debugPrint('User: ${response.data?.email}');
          }

          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? context.l10n.t('auth.loginFailed'),
              ),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t('auth.loginException', {'error': '$e'}),
            ),
          ),
        );
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: null,
        backgroundColor: AppColors.creamBackground,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppGradients.authBackground,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final topOffset = constraints.maxHeight * 207 / 812;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: topOffset,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _LoginCard(
                        phoneController: phoneController,
                        passwordController: passwordController,
                        selectedCountry: selectedCountry.value,
                        agreementAccepted: agreementAccepted.value,
                        isLoading: isLoading.value,
                        isCheckingUser: isCheckingUser.value,
                        hasUser: hasUserResult.value?.hasUser,
                        phoneStatusText: phoneStatusText.value,
                        onCountryTap: showCountryPicker,
                        onAgreementTap: () {
                          agreementAccepted.value = !agreementAccepted.value;
                        },
                        onClose: () {
                          context.pop();
                        },
                        onLogin: handleLogin,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.phoneController,
    required this.passwordController,
    required this.selectedCountry,
    required this.agreementAccepted,
    required this.isLoading,
    required this.isCheckingUser,
    required this.hasUser,
    required this.phoneStatusText,
    required this.onCountryTap,
    required this.onAgreementTap,
    required this.onClose,
    required this.onLogin,
  });

  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final CountryDialOption selectedCountry;
  final bool agreementAccepted;
  final bool isLoading;
  final bool isCheckingUser;
  final bool? hasUser;
  final String? phoneStatusText;
  final VoidCallback onCountryTap;
  final VoidCallback onAgreementTap;
  final VoidCallback onClose;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 317,
      height: 382,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 317,
            height: 382,
            padding: const EdgeInsets.fromLTRB(20, 51, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: AppRadius.dialogBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(text: context.l10n.t('auth.phoneLabel')),
                const SizedBox(height: 8),
                _PhoneInput(
                  controller: phoneController,
                  selectedCountry: selectedCountry,
                  onCountryTap: onCountryTap,
                ),
                SizedBox(
                  height: 24,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      phoneStatusText ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: hasUser == false
                            ? AppColors.primaryPink
                            : AppColors.textPlaceholder,
                      ),
                    ),
                  ),
                ),
                if (hasUser != false) ...[
                  _FieldLabel(text: context.l10n.t('auth.passwordPrompt')),
                  const SizedBox(height: 8),
                  _PasswordInput(controller: passwordController),
                ] else ...[
                  _RegisterHint(text: context.l10n.t('auth.registerRequired')),
                ],
                const SizedBox(height: 16),
                _AgreementRow(
                  accepted: agreementAccepted,
                  onTap: onAgreementTap,
                ),
                const SizedBox(height: 22),
                _ConfirmButton(
                  isLoading: isLoading || isCheckingUser,
                  label: hasUser == false
                      ? context.l10n.t('auth.register')
                      : context.l10n.t('auth.confirm'),
                  onTap: onLogin,
                ),
              ],
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  AppAssets.lanhuLoginDetailClose,
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 18 / 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  const _PhoneInput({
    required this.controller,
    required this.selectedCountry,
    required this.onCountryTap,
  });

  final TextEditingController controller;
  final CountryDialOption selectedCountry;
  final VoidCallback onCountryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277,
      height: 43,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F4),
        borderRadius: AppRadius.fieldBorder,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 43,
                child: Row(
                  children: [
                    const SizedBox(width: 7),
                    CountryFlagIcon(countryCode: selectedCountry.countryCode),
                    const SizedBox(width: 4),
                    Text(
                      '+${selectedCountry.areaCode}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const _DropdownTriangle(),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 16 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.t('auth.phoneHint'),
                    hintStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 16 / 14,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 111,
            child: GestureDetector(
              key: const ValueKey('country_code_picker'),
              behavior: HitTestBehavior.opaque,
              onTap: onCountryTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownTriangle extends StatelessWidget {
  const _DropdownTriangle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 8),
      painter: _DropdownTrianglePainter(),
    );
  }
}

class _DropdownTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277,
      height: 43,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F4),
        borderRadius: AppRadius.fieldBorder,
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 16 / 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.t('auth.passwordHint'),
          hintStyle: const TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 14,
            height: 16 / 14,
            fontWeight: FontWeight.w400,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

class _RegisterHint extends StatelessWidget {
  const _RegisterHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277,
      height: 51,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF5F7),
        borderRadius: AppRadius.fieldBorder,
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(color: AppColors.primaryPink),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({required this.accepted, required this.onTap});

  final bool accepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const normalStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
      height: 14 / 12,
      fontWeight: FontWeight.w400,
    );
    const linkStyle = TextStyle(
      color: Color(0xFFFF6B6B),
      fontSize: 12,
      height: 14 / 12,
      fontWeight: FontWeight.w400,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 277,
        height: 28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: accepted
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AgreementLinksText(
                normalStyle: normalStyle,
                linkStyle: linkStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 277,
        height: 53,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFF4EAE), Color(0xFFFF5774)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(98)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textInverse,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
      ),
    );
  }
}
