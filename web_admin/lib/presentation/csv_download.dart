import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Dispara o download de um arquivo de texto no navegador (Flutter Web).
void downloadTextFile(String content, String filename, {String mimeType = 'text/csv'}) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
