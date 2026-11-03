// Redacted Nady conversation/system preview protocol examples.

final imOrdinaryPreviewSamples =
    <({String type, Map<String, Object?> payload, String expected})>[
      (
        type: 'TextIMMsg',
        payload: {'text': 'Hello\n friend 👋'},
        expected: 'Hello friend 👋',
      ),
      (
        type: 'transferAccounts',
        payload: {'titleEn': 'You received 100 coins'},
        expected: 'You received 100 coins',
      ),
      (
        type: 'SystemComplexIMMsg',
        payload: {
          'textMap': {'en': 'Actual body'},
          'titleMap': {'en': 'Not the ordinary summary'},
        },
        expected: 'Actual body',
      ),
      (
        type: 'InviteAcceptedPrivateComplexMsg',
        payload: {
          'textMap': {'en': 'Your invitation was accepted'},
        },
        expected: 'Your invitation was accepted',
      ),
      (type: 'shareRoom', payload: {}, expected: 'Share Room'),
      (type: 'shareParty', payload: {}, expected: 'Room Party'),
      (type: 'InvitationIMMsg', payload: {}, expected: "What's up"),
      (
        type: 'SystemSendGiftStore',
        payload: {'targetUserId': 10},
        expected: 'Sent you',
      ),
      (
        type: 'SystemSendGiftStore',
        payload: {'targetUserId': '20'},
        expected: 'You sent',
      ),
      (
        type: 'TransferNoticeIMMsg',
        payload: {'digitalCurrency': 1},
        expected: 'Coin Transfer',
      ),
      (
        type: 'TransferNoticeIMMsg',
        payload: {'digitalCurrency': 3},
        expected: 'USD Transfer',
      ),
      (
        type: 'AgentSendsInviteIMMsg',
        payload: {'type': 1},
        expected: 'Invite you to be an agent',
      ),
      (
        type: 'AgentSendsInviteIMMsg',
        payload: {'type': 2},
        expected: 'Invite you to be a host',
      ),
      (
        type: 'ChannelSendsInviteIMMsg',
        payload: {'type': '3'},
        expected: 'Invite you to be a BD',
      ),
      (type: 'shareBanner', payload: {}, expected: 'Message'),
      (type: 'shareOfficial', payload: {}, expected: 'Official Message'),
      (type: 'shareWhatsapp', payload: {}, expected: 'Share WhatsApp'),
    ];
final imSystemPreviewSamples =
    <({String type, Map<String, Object?> payload, String expected})>[
      (
        type: 'purseTransferAccountsImMsg',
        payload: {'title': 'Wallet credited'},
        expected: 'Wallet credited',
      ),
      (
        type: 'transferAccounts',
        payload: {'titleEn': 'Transfer completed'},
        expected: 'Transfer completed',
      ),
      (
        type: 'RewardPackSendIMMsg',
        payload: {'enTitle': 'Welcome reward'},
        expected: 'Welcome reward',
      ),
      (
        type: 'SystemComplexIMMsg',
        payload: {
          'titleMap': {'en': 'System title'},
          'textMap': {'en': 'Not the system summary'},
        },
        expected: 'System title',
      ),
      (
        type: 'Vip',
        payload: {
          'titleMap': {'en': 'VIP renewed'},
        },
        expected: 'VIP renewed',
      ),
      (
        type: 'InviteRelationshipSuccessMsg',
        payload: {
          'titleMap': {'en': 'Friend connected'},
        },
        expected: 'Friend connected',
      ),
      (
        type: 'InviteSuccessRewardMsg',
        payload: {
          'titleMap': {'en': 'Invitation rewarded'},
        },
        expected: 'Invitation rewarded',
      ),
      (
        type: 'InviteActiveMsg',
        payload: {'title': 'Bring your friends'},
        expected: 'Bring your friends',
      ),
      (
        type: 'InviteActiveMsg',
        payload: {'event': 1},
        expected: 'Release Friend Relationship',
      ),
      (
        type: 'InviteActiveMsg',
        payload: {'event': 2},
        expected: 'Activate friends',
      ),
      (
        type: 'InvitationNoticeMsg',
        payload: {'type': 1},
        expected: 'Commented on your post',
      ),
      (
        type: 'InvitationNoticeMsg',
        payload: {'type': 2},
        expected: 'Replied to your post',
      ),
      (type: 'InvitationNoticeMsg', payload: {'type': 3}, expected: '@You'),
      (
        type: 'InvitationNoticeMsg',
        payload: {'type': 4},
        expected: 'Liked your post',
      ),
    ];
