import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Handler buildHandler() {
  final router = Router()
    ..get('/', (Request request) {
      return Response.ok(
        jsonEncode({'service': 'api', 'status': 'ok'}),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
      );
    })
    ..get('/health', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
      );
    })
    ..get('/v1/config', (Request request) {
      return Response.ok(
        jsonEncode({
          'environment': Platform.environment['APP_ENV'] ?? 'dev',
          'apiVersion': 'v1',
        }),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
      );
    });

  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

Future<HttpServer> serveApi({String host = '0.0.0.0', int port = 8080}) {
  return shelf_io.serve(buildHandler(), host, port);
}
