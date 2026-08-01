class UploadParam {
  const UploadParam({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.expiration,
    required this.securityToken,
    required this.endpoint,
    required this.bucket,
    required this.region,
    required this.path,
    required this.domain,
  });

  final String accessKeyId;
  final String accessKeySecret;
  final String expiration;
  final String securityToken;
  final String endpoint;
  final String bucket;
  final String region;
  final String path;
  final String domain;

  factory UploadParam.fromJson(Map<String, dynamic> json) {
    return UploadParam(
      accessKeyId: json['accessKeyId']?.toString() ?? '',
      accessKeySecret: json['accessKeySecret']?.toString() ?? '',
      expiration: json['expiration']?.toString() ?? '',
      securityToken: json['securityToken']?.toString() ?? '',
      endpoint: json['endpoint']?.toString() ?? '',
      bucket: json['bucket']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
    );
  }
}
