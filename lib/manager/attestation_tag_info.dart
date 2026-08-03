class AttestationTagInfo {
  final String? tagUrl;
  final String? tagType;
  final int? width;
  final int? height;

  AttestationTagInfo({
    this.tagUrl,
    this.tagType,
    this.width,
    this.height,
  });

  factory AttestationTagInfo.fromJson(Map<String, dynamic> json) =>
      AttestationTagInfo(
        tagUrl: json['tagUrl'] as String?,
        tagType: json['tagType'] as String?,
        width: json['width'] as int?,
        height: json['height'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'tagUrl': tagUrl,
        'tagType': tagType,
        'width': width,
        'height': height,
      };
}

