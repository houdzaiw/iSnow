import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../tools/profile_tools_widgets.dart';
import 'store_repository.dart';

class StoreRecipientState {
  const StoreRecipientState({
    this.input = '',
    this.user,
    this.loading = false,
    this.error,
  });
  final String input;
  final UserData? user;
  final bool loading;
  final Object? error;
}

final storeRecipientProvider =
    StateNotifierProvider.autoDispose<StoreRecipientModel, StoreRecipientState>(
      (ref) => StoreRecipientModel(ref.watch(storeRepositoryProvider)),
    );

class StoreRecipientModel extends StateNotifier<StoreRecipientState> {
  StoreRecipientModel(this.repo) : super(const StoreRecipientState());
  final StoreRepository repo;
  int _revision = 0;
  bool _alive = true;
  @override
  void dispose() {
    _alive = false;
    _revision++;
    super.dispose();
  }

  void change(String input) {
    _revision++;
    state = StoreRecipientState(input: input);
  }

  Future<void> search() async {
    if (state.loading) return;
    final revision = ++_revision, input = state.input;
    state = StoreRecipientState(input: input, loading: true);
    try {
      final user = await repo.recipient(input);
      if (_alive && revision == _revision) {
        state = StoreRecipientState(input: input, user: user);
      }
    } catch (e) {
      if (_alive && revision == _revision) {
        state = StoreRecipientState(input: input, error: e);
      }
    }
  }
}

class StoreRecipientSheet extends ConsumerWidget {
  const StoreRecipientSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeRecipientProvider);
    final model = ref.read(storeRecipientProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: ProfileToolsTheme.padding,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.t('tools.send'),
                  style: ProfileToolsTheme.title,
                ),
                ProfileToolsTheme.gap,
                TextField(
                  key: const ValueKey('store-recipient-input'),
                  onChanged: model.change,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('tools.recipient'),
                  ),
                ),
                TextButton(
                  onPressed: state.loading ? null : model.search,
                  child: Text(context.l10n.t('tools.search')),
                ),
                if (state.loading) const CircularProgressIndicator(),
                if (state.error != null)
                  ProfileToolsError(error: state.error, retry: model.search),
                if (state.user case final user?) ...[
                  MembershipImage(
                    user.avatar ?? '',
                    size: ProfileToolsTheme.badge,
                  ),
                  Text(
                    '${user.nick ?? ''} · ${user.userNo ?? user.uid}',
                    style: ProfileToolsTheme.body,
                  ),
                ],
                ProfileToolsTheme.gap,
                ElevatedButton(
                  onPressed: state.user == null || state.loading
                      ? null
                      : () => Navigator.pop(context, state.user),
                  child: Text(context.l10n.t('tools.confirm')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
