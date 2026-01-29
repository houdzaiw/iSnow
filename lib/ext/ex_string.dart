
extension DateTimeStringExt on String {
  // String formatTimeString({String format = "yyyy.MM.dd HH:mm:ss"}) {
  //   final DateTime? time = DateTime.tryParse(this);
  //   if (time == null) return "";
  //   return DateFormat(format, "en").format(time);
  // }

  int get toInt {
    return int.tryParse(this) ?? 0;
  }

  Map<String, String> get queryParameters {
    return Uri.tryParse(this)?.queryParameters ?? {};
  }
}
