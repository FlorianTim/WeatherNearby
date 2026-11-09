import 'dart:io';

import 'package:api/api.dart';

Future<void> main() async {
  final server = await serveApi();
  stdout.writeln(
    'API listening on http://${server.address.host}:${server.port}',
  );
}
