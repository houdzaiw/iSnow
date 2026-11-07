import 'dart:convert';

typedef RoomMentionTarget = ({int uid, String name});

class RoomMentionSegment {
  const RoomMentionSegment(this.text, {this.uid});
  final String text;
  final int? uid;
}

const _start = '</user_nike>';

String encodeRoomMention(String text, RoomMentionTarget? target) {
  if (target == null || target.name.trim().isEmpty || target.uid <= 0) {
    return text;
  }
  return text.replaceFirst(
    '@${target.name}',
    '$_start${jsonEncode({'userNike': target.name, 'userUid': '${target.uid}'})}</user_nike>',
  );
}

List<RoomMentionSegment> decodeRoomMentions(String text) {
  final result = <RoomMentionSegment>[];
  final pattern = RegExp(r'</user_nike>(\{.*?\})</user_nike>', dotAll: true);
  var previous = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > previous) {
      result.add(RoomMentionSegment(text.substring(previous, match.start)));
    }
    try {
      final value = jsonDecode(match.group(1)!);
      final name = value is Map ? value['userNike'] : null;
      final uid = value is Map ? int.tryParse('${value['userUid']}') : null;
      if (name is String && name.trim().isNotEmpty && uid != null && uid > 0) {
        result.add(RoomMentionSegment('@$name', uid: uid));
      }
    } on FormatException {
      // Do not put protocol metadata into the public screen.
    }
    previous = match.end;
  }
  if (previous < text.length) {
    result.add(RoomMentionSegment(text.substring(previous)));
  }
  return result;
}
