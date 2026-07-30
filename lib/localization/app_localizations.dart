import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isChinese => locale.languageCode == 'zh';

  String t(String key, [Map<String, String> values = const {}]) {
    var text =
        (_localizedValues[locale.languageCode] ??
            _localizedValues['en'])![key] ??
        _localizedValues['en']![key] ??
        key;
    values.forEach((name, value) {
      text = text.replaceAll('{$name}', value);
    });
    return text;
  }

  String get calendarLocale => isChinese ? 'zh_CN' : 'en_US';
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'app.language': 'Language',
    'app.english': 'English',
    'app.chinese': 'Chinese',
    'app.currentLanguage': 'Current language',
    'app.save': 'Save',
    'app.cancel': 'Cancel',
    'app.delete': 'Delete',
    'app.report': 'Report',
    'app.block': 'Block',
    'auth.login': 'Log in',
    'auth.register': 'Sign up',
    'auth.emailLabel': 'Email',
    'auth.emailHint': 'Enter email address',
    'auth.accountRequired': 'Please enter email or phone number',
    'auth.passwordLabel': 'Password',
    'auth.passwordHint': 'Enter password',
    'auth.passwordRequired': 'Please enter password',
    'auth.registerEmailLabel': 'Registration email',
    'auth.confirmPasswordLabel': 'Confirm password',
    'auth.confirmPasswordHint': 'Enter password again',
    'auth.loginFailed': 'Login failed',
    'auth.loginException': 'Login error: {error}',
    'home.captureDescription': 'A mood was captured today.',
    'home.captureTitle': 'You caught a good mood today',
    'home.open': 'Open',
    'calendar.noMoodRecords': 'No mood records',
    'calendar.onlyToday': 'You can only post today\'s mood.',
    'publish.selectMood': 'Select mood',
    'publish.writeMood': 'Write mood',
    'publish.moodHint': 'What happened today...',
    'publish.saveSuccess': 'Saved',
    'publish.needContent': 'Enter content or choose an image',
    'publish.needVoice': 'Please record audio',
    'publish.maxImages': 'You can choose up to 4 images',
    'publish.maxImagesAdded': 'You can choose up to 4 images. Added {count}.',
    'publish.noRecordPermission': 'Microphone permission denied',
    'publish.startRecording': 'Tap to start recording',
    'publish.stopRecording': 'Tap to stop recording',
    'content.todayMood': 'This is my mood today',
    'message.title': 'Messages',
    'message.empty': 'No messages',
    'message.me': 'Me',
    'message.contact': 'Contact',
    'message.yesterday': 'Yesterday',
    'message.dialogTitle': 'Notice',
    'message.deleteConversation': 'Delete conversation',
    'chat.title': 'Chat',
    'chat.inputHint': 'Say something...',
    'profile.nickname': 'User nickname',
    'profile.myPosts': 'My posts',
    'profile.privacy': 'Privacy',
    'profile.aboutUs': 'About us',
    'profile.contactUs': 'Contact us',
    'profile.settings': 'Settings',
    'profile.editProfile': 'Edit profile',
    'profile.avatar': 'Avatar',
    'profile.gender': 'Gender',
    'profile.birthday': 'Birthday',
    'profile.chooseGender': 'Choose gender',
    'profile.male': 'Male',
    'profile.female': 'Female',
    'profile.saved': 'Saved',
    'profile.selectedMale': 'Male selected',
    'profile.selectedFemale': 'Female selected',
    'profile.editNickname': 'Edit nickname',
    'profile.nicknameHint': 'Enter nickname',
    'profile.nicknameSaved': 'Nickname saved: {nickname}',
    'profile.nicknameRequired': 'Nickname cannot be empty',
    'profile.nicknameTooLong': 'Nickname cannot exceed 20 characters',
    'profile.nicknameRule': 'Nickname length: 1-20 characters',
    'profile.noPosts': 'No posts',
    'profile.postsLoadFailed': 'Failed to load posts',
    'settings.empty': 'No more settings',
    'about.version': 'Version 1.0.0',
    'about.description':
        'Record your daily emotions and moments, and keep your moods safe.',
    'detail.moodDetail': 'Mood detail',
    'picker.album': 'Choose from album',
    'picker.camera': 'Take photo',
    'picker.albumSelected': 'Album selected',
    'picker.cameraSelected': 'Camera selected',
  },
  'zh': {
    'app.language': '语言',
    'app.english': '英文',
    'app.chinese': '中文',
    'app.currentLanguage': '当前语言',
    'app.save': '保存',
    'app.cancel': '取消',
    'app.delete': '删除',
    'app.report': '举报',
    'app.block': '拉黑',
    'auth.login': '登录',
    'auth.register': '注册',
    'auth.emailLabel': '请输入邮箱',
    'auth.emailHint': '请输入邮箱地址',
    'auth.accountRequired': '请输入邮箱或手机号',
    'auth.passwordLabel': '请输入密码',
    'auth.passwordHint': '请输入密码',
    'auth.passwordRequired': '请输入密码',
    'auth.registerEmailLabel': '请输入注册邮箱',
    'auth.confirmPasswordLabel': '请再次输入密码',
    'auth.confirmPasswordHint': '请再次输入密码',
    'auth.loginFailed': '登录失败',
    'auth.loginException': '登录异常：{error}',
    'home.captureDescription': '这是今天捕捞到的一条心情。',
    'home.captureTitle': '今天也捕捞到一颗好心情',
    'home.open': '打开',
    'calendar.noMoodRecords': '暂无心情记录',
    'calendar.onlyToday': '只能在当天发布心情哦~',
    'publish.selectMood': '选择心情',
    'publish.writeMood': '填写心情',
    'publish.moodHint': '今天发生了什么...',
    'publish.saveSuccess': '保存成功！',
    'publish.needContent': '请输入内容或选择图片',
    'publish.needVoice': '请录制语音',
    'publish.maxImages': '最多只能选择4张图片',
    'publish.maxImagesAdded': '最多只能选择4张图片，已添加{count}张',
    'publish.noRecordPermission': '没有录音权限',
    'publish.startRecording': '点击开始录音',
    'publish.stopRecording': '点击停止录音',
    'content.todayMood': '这是我今天的心情',
    'message.title': '消息',
    'message.empty': '暂无消息',
    'message.me': '我',
    'message.contact': '联系人',
    'message.yesterday': '昨天',
    'message.dialogTitle': '提示',
    'message.deleteConversation': '删除对话',
    'chat.title': '聊天',
    'chat.inputHint': '说点什么...',
    'profile.nickname': '用户昵称',
    'profile.myPosts': '我的帖子',
    'profile.privacy': '用户隐私',
    'profile.aboutUs': '关于我们',
    'profile.contactUs': '联系我们',
    'profile.settings': '设置',
    'profile.editProfile': '编辑资料',
    'profile.avatar': '头像',
    'profile.gender': '性别',
    'profile.birthday': '生日',
    'profile.chooseGender': '选择性别',
    'profile.male': '男',
    'profile.female': '女',
    'profile.saved': '保存成功',
    'profile.selectedMale': '已选择男',
    'profile.selectedFemale': '已选择女',
    'profile.editNickname': '编辑昵称',
    'profile.nicknameHint': '请输入昵称',
    'profile.nicknameSaved': '昵称已保存：{nickname}',
    'profile.nicknameRequired': '昵称不能为空',
    'profile.nicknameTooLong': '昵称不能超过20个字符',
    'profile.nicknameRule': '昵称长度为1-20个字符',
    'profile.noPosts': '暂无帖子',
    'profile.postsLoadFailed': '帖子加载失败',
    'settings.empty': '暂无更多设置',
    'about.version': '版本 1.0.0',
    'about.description': '记录每天的情绪和片刻，把心情好好收藏起来。',
    'detail.moodDetail': '心情详情',
    'picker.album': '从相册选择',
    'picker.camera': '拍照',
    'picker.albumSelected': '已选择相册',
    'picker.cameraSelected': '已选择拍照',
  },
};
