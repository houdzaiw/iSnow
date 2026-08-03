import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';

class AgreementLinksText extends StatefulWidget {
  const AgreementLinksText({
    super.key,
    required this.normalStyle,
    required this.linkStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  final TextStyle normalStyle;
  final TextStyle linkStyle;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  State<AgreementLinksText> createState() => _AgreementLinksTextState();
}

class _AgreementLinksTextState extends State<AgreementLinksText> {
  static const _serviceAgreementUrl = 'https://www.simisoul.com/protocol.html';
  static const _privacyPolicyUrl = 'https://www.simisoul.com/policy.html';

  late final TapGestureRecognizer _serviceAgreementRecognizer;
  late final TapGestureRecognizer _privacyPolicyRecognizer;

  @override
  void initState() {
    super.initState();
    _serviceAgreementRecognizer = TapGestureRecognizer()
      ..onTap = () => _openWebView(
        title: context.l10n.t('auth.serviceAgreement'),
        uri: _serviceAgreementUrl,
      );
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openWebView(
        title: context.l10n.t('auth.privacyPolicy'),
        uri: _privacyPolicyUrl,
      );
  }

  @override
  void dispose() {
    _serviceAgreementRecognizer.dispose();
    _privacyPolicyRecognizer.dispose();
    super.dispose();
  }

  void _openWebView({required String title, required String uri}) {
    context.push(
      Uri(
        path: '/web-view',
        queryParameters: {'title': title, 'uri': uri},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      text: TextSpan(
        style: widget.normalStyle,
        children: [
          TextSpan(text: context.l10n.t('auth.agreementPrefix')),
          TextSpan(
            text: context.l10n.t('auth.serviceAgreement'),
            style: widget.linkStyle,
            recognizer: _serviceAgreementRecognizer,
          ),
          TextSpan(text: context.l10n.t('auth.agreementMiddle')),
          TextSpan(
            text: context.l10n.t('auth.privacyPolicy'),
            style: widget.linkStyle,
            recognizer: _privacyPolicyRecognizer,
          ),
        ],
      ),
    );
  }
}
