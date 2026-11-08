import '../../model/server_response.dart';

List<Map<String, dynamic>> homeResponseRows(Object? response) {
  final server = NadyServerResponse<Object?>.fromJson(
    response is Map ? Map<String, dynamic>.from(response) : const {},
    (v) => v,
  );
  if (!server.isSuccess) throw server.toException();
  Object? data = server.data;
  // Nady responses may wrap a collection in data/list.
  for (int depth = 0; depth < 4 && data is Map; depth++) {
    data = data['list'] ?? data['data'];
  }
  if (data == null) return const [];
  if (data is! List) {
    throw const NadyApiException(message: 'Invalid list response');
  }
  return data
      .whereType<Map>()
      .map((v) => Map<String, dynamic>.from(v))
      .toList();
}
