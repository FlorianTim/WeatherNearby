import 'dart:async';
import 'dart:convert';

import 'package:api/api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

FutureOr<Response> _call(String path) {
  final handler = buildHandler();
  return handler(Request('GET', Uri.parse('http://localhost$path')));
}

void main() {
  test('health endpoint returns ok', () async {
    final response = await _call('/health');
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['status'], 'ok');
  });
}
