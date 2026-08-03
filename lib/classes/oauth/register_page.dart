import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_localizations.dart';
import '../../model/country_info.dart';
import '../../model/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/agreement_links_text.dart';
import '../../widgets/country_picker_sheet.dart';
import 'provider/login_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.initialPhone,
    this.initialAreaCode,
    this.initialCountryCode,
    this.enableCountryCodeLookup = true,
  });

  final String? initialPhone;
  final String? initialAreaCode;
  final String? initialCountryCode;
  final bool enableCountryCodeLookup;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const int _codeCountdownSeconds = 120;

  final LoginProvider _loginProvider = LoginProvider();
  late final TextEditingController _phoneController;
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Timer? _countdownTimer;
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isQueryingCountryCode = false;
  bool _agreementAccepted = true;
  int _resendSeconds = 0;

  late CountryDialOption _selectedCountry;
  final List<CountryDialOption> _countryOptions = CountryInfo.fallbackList
      .map(CountryDialOption.fromCountryInfo)
      .toList();

  String get _phone => _phoneController.text.trim();
  String get _smsCode => _smsController.text.trim();
  String get _password => _passwordController.text.trim();
  String get _confirmPassword => _confirmPasswordController.text.trim();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _selectedCountry = _initialCountry();
    if (widget.enableCountryCodeLookup) {
      unawaited(_refreshCountryDialCode(showError: false));
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _smsController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  CountryDialOption _initialCountry() {
    final initialIsoCode = widget.initialCountryCode?.trim().toUpperCase();
    final fallbackCountry = CountryInfo.fallbackList.firstWhere(
      (country) => country.isoCode.toUpperCase() == initialIsoCode,
      orElse: () => CountryInfo.saudiArabia,
    );
    final areaCode = widget.initialAreaCode?.trim();
    return CountryDialOption.fromCountryInfo(
      fallbackCountry,
    ).copyWith(areaCode: areaCode?.isNotEmpty == true ? areaCode : null);
  }

  Future<void> _refreshCountryDialCode({required bool showError}) async {
    final countryCode = _selectedCountry.countryCode;
    setState(() => _isQueryingCountryCode = true);
    try {
      final dialCode = await _loginProvider.queryCountryDialCode(countryCode);
      if (!mounted || countryCode != _selectedCountry.countryCode) return;
      setState(() {
        _selectedCountry = _selectedCountry.copyWith(areaCode: dialCode);
      });
    } catch (_) {
      if (!mounted || !showError) return;
      _showMessage(context.l10n.t('auth.countryCodeLoadFailed'));
    } finally {
      if (mounted) {
        setState(() => _isQueryingCountryCode = false);
      }
    }
  }

  Future<void> _showCountryPicker() async {
    final country = await CountryPickerSheet.show(
      context,
      countries: _countryOptions,
      selectedCountryCode: _selectedCountry.countryCode,
    );

    if (country == null || !mounted) return;
    setState(() => _selectedCountry = country);
    await _refreshCountryDialCode(showError: true);
  }

  Future<void> _sendSmsCode() async {
    if (_resendSeconds > 0 || _isSendingCode) return;
    if (!_validatePhoneAndAgreement()) return;

    setState(() => _isSendingCode = true);
    try {
      await _loginProvider.sendSms(
        phoneNumber: _phone,
        areaCode: _selectedCountry.areaCode,
        purpose: 1,
        type: 1,
      );
      if (!mounted) return;
      _showMessage(context.l10n.t('auth.smsSent'));
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendSeconds = _codeCountdownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds -= 1);
    });
  }

  Future<void> _submitRegister() async {
    if (!_validatePhoneAndAgreement()) return;
    if (_smsCode.isEmpty) {
      _showMessage(context.l10n.t('auth.smsRequired'));
      return;
    }
    if (_password.length < 6 || _password.length > 20) {
      _showMessage(context.l10n.t('auth.passwordLength'));
      return;
    }
    if (_password != _confirmPassword) {
      _showMessage(context.l10n.t('auth.passwordMismatch'));
      return;
    }

    setState(() => _isLoading = true);
    final registerFailedText = context.l10n.t('auth.registerFailed');
    try {
      final response = await _loginProvider.registerWithSmsPassword(
        phone: _phone,
        password: _password,
        smsCode: _smsCode,
        areaCode: _selectedCountry.areaCode,
        countryCode: _selectedCountry.countryCode,
      );

      if (!response.success || response.uid == null) {
        _showMessage(response.message ?? registerFailedText);
        return;
      }

      if (response.status == NadyLoginStatus.needPassword) {
        await _loginProvider.setPassword(
          phoneNumber: _phone,
          password: _password,
          areaCode: _selectedCountry.areaCode,
        );
      }

      if (response.status == NadyLoginStatus.incompleteInformation ||
          response.status == NadyLoginStatus.needPassword) {
        await _loginProvider.completeUser(
          uid: response.uid!,
          nick: 'iSnow User',
          avatar: '',
          gender: 0,
          birth: '',
          countryCode: _selectedCountry.countryCode,
        );
      }

      if (!mounted) return;
      _showMessage(context.l10n.t('auth.registerSuccess'));
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validatePhoneAndAgreement() {
    if (_phone.isEmpty) {
      _showMessage(context.l10n.t('auth.phoneRequired'));
      return false;
    }
    if (!_agreementAccepted) {
      _showMessage(context.l10n.t('auth.agreementRequired'));
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
              final topOffset = constraints.maxHeight * 118 / 812;
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
                      child: _RegisterCard(
                        phoneController: _phoneController,
                        smsController: _smsController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        selectedCountry: _selectedCountry,
                        agreementAccepted: _agreementAccepted,
                        isLoading: _isLoading,
                        isSendingCode: _isSendingCode,
                        isQueryingCountryCode: _isQueryingCountryCode,
                        resendSeconds: _resendSeconds,
                        onCountryTap: _showCountryPicker,
                        onSendCode: _sendSmsCode,
                        onAgreementTap: () {
                          setState(() {
                            _agreementAccepted = !_agreementAccepted;
                          });
                        },
                        onClose: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        onSubmit: _submitRegister,
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.phoneController,
    required this.smsController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedCountry,
    required this.agreementAccepted,
    required this.isLoading,
    required this.isSendingCode,
    required this.isQueryingCountryCode,
    required this.resendSeconds,
    required this.onCountryTap,
    required this.onSendCode,
    required this.onAgreementTap,
    required this.onClose,
    required this.onSubmit,
  });

  final TextEditingController phoneController;
  final TextEditingController smsController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final CountryDialOption selectedCountry;
  final bool agreementAccepted;
  final bool isLoading;
  final bool isSendingCode;
  final bool isQueryingCountryCode;
  final int resendSeconds;
  final VoidCallback onCountryTap;
  final VoidCallback onSendCode;
  final VoidCallback onAgreementTap;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 322,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 322,
            padding: const EdgeInsets.fromLTRB(21, 42, 21, 28),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: AppRadius.dialogBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.t('auth.register'),
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                _FieldLabel(text: context.l10n.t('auth.phoneNumberLabel')),
                const SizedBox(height: 8),
                _PhoneField(
                  controller: phoneController,
                  country: selectedCountry,
                  isQueryingCountryCode: isQueryingCountryCode,
                  onCountryTap: onCountryTap,
                ),
                const SizedBox(height: 14),
                _FieldLabel(text: context.l10n.t('auth.smsCode')),
                const SizedBox(height: 8),
                _SmsCodeField(
                  controller: smsController,
                  isSendingCode: isSendingCode,
                  resendSeconds: resendSeconds,
                  onSendCode: onSendCode,
                ),
                const SizedBox(height: 14),
                _FieldLabel(text: context.l10n.t('auth.passwordLabel')),
                const SizedBox(height: 8),
                _RegisterTextField(
                  key: const ValueKey('register_password_field'),
                  controller: passwordController,
                  hintText: context.l10n.t('auth.passwordHint'),
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                _FieldLabel(text: context.l10n.t('auth.confirmPasswordLabel')),
                const SizedBox(height: 8),
                _RegisterTextField(
                  key: const ValueKey('register_confirm_password_field'),
                  controller: confirmPasswordController,
                  hintText: context.l10n.t('auth.confirmPasswordHint'),
                  obscureText: true,
                ),
                const SizedBox(height: 18),
                _AgreementRow(
                  accepted: agreementAccepted,
                  onTap: onAgreementTap,
                ),
                const SizedBox(height: 25),
                _SubmitButton(isLoading: isLoading, onTap: onSubmit),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Image.asset(
                AppAssets.lanhuLoginDetailClose,
                width: 38,
                height: 38,
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
      style: AppTextStyles.bodyStrongSmall.copyWith(fontSize: 15, height: 1.2),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.country,
    required this.isQueryingCountryCode,
    required this.onCountryTap,
  });

  final TextEditingController controller;
  final CountryDialOption country;
  final bool isQueryingCountryCode;
  final VoidCallback onCountryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      decoration: const BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: AppRadius.fieldBorder,
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('register_country_code_picker'),
            behavior: HitTestBehavior.opaque,
            onTap: onCountryTap,
            child: SizedBox(
              width: 108,
              height: 43,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CountryFlagIcon(
                    countryCode: country.countryCode,
                    width: 24,
                    height: 24,
                    circular: true,
                  ),
                  const SizedBox(width: 6),
                  isQueryingCountryCode
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : Text(
                          '+${country.areaCode}',
                          style: AppTextStyles.bodyStrongSmall,
                        ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 22, color: AppColors.neutralLight),
          Expanded(
            child: TextField(
              key: const ValueKey('register_phone_field'),
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodyStrongSmall,
              decoration: InputDecoration(
                hintText: context.l10n.t('auth.phoneHint'),
                hintStyle: AppTextStyles.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsCodeField extends StatelessWidget {
  const _SmsCodeField({
    required this.controller,
    required this.isSendingCode,
    required this.resendSeconds,
    required this.onSendCode,
  });

  final TextEditingController controller;
  final bool isSendingCode;
  final int resendSeconds;
  final VoidCallback onSendCode;

  @override
  Widget build(BuildContext context) {
    final disabled = isSendingCode || resendSeconds > 0;
    final buttonText = resendSeconds > 0
        ? context.l10n.t('auth.resendIn', {'seconds': '$resendSeconds'})
        : context.l10n.t('auth.sendSms');

    return Container(
      height: 43,
      decoration: const BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: AppRadius.fieldBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('register_sms_field'),
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodyStrongSmall,
              decoration: InputDecoration(
                hintText: context.l10n.t('auth.smsCodeHint'),
                hintStyle: AppTextStyles.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: GestureDetector(
              key: const ValueKey('register_send_code_button'),
              behavior: HitTestBehavior.opaque,
              onTap: disabled ? null : onSendCode,
              child: Container(
                width: 88,
                height: 33,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: disabled
                      ? AppColors.neutralLight
                      : AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: isSendingCode
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textInverse,
                        ),
                      )
                    : Text(
                        buttonText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrongSmall.copyWith(
                          color: disabled
                              ? AppColors.textTertiary
                              : AppColors.textInverse,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTextField extends StatelessWidget {
  const _RegisterTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: AppTextStyles.bodyStrongSmall,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.hint,
          filled: true,
          fillColor: AppColors.fieldBackground,
          border: OutlineInputBorder(
            borderRadius: AppRadius.fieldBorder,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.fieldBorder,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.fieldBorder,
            borderSide: const BorderSide(
              color: AppColors.primaryPink,
              width: 1.4,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
        ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: accepted ? AppColors.primaryPink : AppColors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: accepted
                    ? AppColors.primaryPink
                    : AppColors.textPlaceholder,
                width: 1.4,
              ),
            ),
            child: accepted
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.textInverse,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AgreementLinksText(
              normalStyle: AppTextStyles.caption.copyWith(height: 1.35),
              linkStyle: AppTextStyles.caption.copyWith(
                height: 1.35,
                color: AppColors.primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('register_submit_button'),
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 280,
        height: 53,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primaryPink,
          borderRadius: AppRadius.pillBorder,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textInverse,
                ),
              )
            : Text(
                context.l10n.t('auth.register'),
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
      ),
    );
  }
}
