import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/country_picker_sheet.dart';
import '../../party/friends_activity/home_activity_navigation.dart';
import '../tools/profile_tools_widgets.dart';
import 'account_binding_view_model.dart';

class AccountBindingPage extends ConsumerWidget {
  const AccountBindingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final state = ref.watch(accountBindingProvider);
    final model = ref.read(accountBindingProvider.notifier);
    return ProfileToolsScaffold(
      title: context.l10n.t('tools.binding'),
      child: ListView(
        padding: ProfileToolsTheme.padding,
        children: [
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null)
            ProfileToolsError(error: state.error, retry: model.load),
          for (final account in state.accounts.where((a) => a.bound))
            ListTile(
              title: Text(
                account.type == 5
                    ? context.l10n.t('tools.phone')
                    : const {
                            0: 'Google',
                            1: 'Facebook',
                            6: 'Apple',
                            7: 'Google',
                          }[account.type] ??
                          '${account.type}',
              ),
              subtitle: Text(account.account),
              trailing: Text(context.l10n.t('tools.bound')),
            ),
          if (!state.loading && state.error == null) ...[
            Text(
              context.l10n.t(
                state.verifyOld ? 'tools.verifyOld' : 'tools.bindNew',
              ),
              style: ProfileToolsTheme.title,
            ),
            if (state.verifiedOld)
              Text(
                context.l10n.t('tools.oldVerified'),
                style: ProfileToolsTheme.caption,
              ),
            TextButton(
              onPressed: state.busy || state.verifyOld
                  ? null
                  : () async {
                      final country = await CountryPickerSheet.show(
                        context,
                        countries: state.countries
                            .map(CountryDialOption.fromCountryInfo)
                            .toList(),
                        selectedCountryCode:
                            state.countries
                                .where((c) => c.areaCode == state.area)
                                .firstOrNull
                                ?.isoCode ??
                            'SA',
                      );
                      if (context.mounted && country != null) {
                        model.edit(area: country.areaCode);
                      }
                    },
              child: Text('${context.l10n.t('tools.area')}: +${state.area}'),
            ),
            TextFormField(
              key: ValueKey(('phone', state.verifyOld)),
              initialValue: state.phone,
              readOnly: state.verifyOld,
              enabled: !state.busy,
              keyboardType: TextInputType.phone,
              onChanged: (v) => model.edit(phone: v.trim()),
              decoration: InputDecoration(
                labelText: context.l10n.t('tools.phone'),
              ),
            ),
            ProfileToolsTheme.gap,
            TextFormField(
              key: ValueKey(('code', state.verifyOld, state.phone, state.area)),
              enabled: !state.busy,
              keyboardType: TextInputType.number,
              onChanged: (v) => model.edit(code: v.trim()),
              decoration: InputDecoration(
                labelText: context.l10n.t('tools.code'),
              ),
            ),
            TextButton(
              onPressed: state.busy || state.seconds > 0
                  ? null
                  : () async {
                      try {
                        await model.send();
                      } catch (e) {
                        if (context.mounted) profileToolsNotice(context, e);
                      }
                    },
              child: Text(
                context.l10n.t(
                  state.seconds > 0 ? 'tools.resend' : 'tools.sendCode',
                  {'seconds': '${state.seconds}'},
                ),
              ),
            ),
            if (state.seconds == 0)
              TextButton(
                onPressed: state.busy
                    ? null
                    : () async {
                        try {
                          await model.send(type: 2);
                        } catch (e) {
                          if (context.mounted) profileToolsNotice(context, e);
                        }
                      },
                child: Text(context.l10n.t('tools.whatsappCode')),
              ),
            if (!state.verifyOld && state.boundPhone == null)
              TextFormField(
                enabled: !state.busy,
                obscureText: true,
                onChanged: (v) => model.edit(password: v),
                decoration: InputDecoration(
                  labelText: context.l10n.t('tools.password'),
                ),
              ),
            ProfileToolsTheme.gap,
            ElevatedButton(
              onPressed: state.busy
                  ? null
                  : () async {
                      try {
                        final result = await model.submit();
                        if (!context.mounted || result == null) return;
                        profileToolsNotice(
                          context,
                          null,
                          key: result ? 'tools.success' : 'tools.refreshFailed',
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) profileToolsNotice(context, e);
                      }
                    },
              child: state.busy
                  ? const CircularProgressIndicator()
                  : Text(context.l10n.t('tools.confirm')),
            ),
          ],
        ],
      ),
    );
  }
}
