import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

class DownloadService {
  static Future<void> downloadImage(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = filename;
      anchor.click();
      web.URL.revokeObjectURL(url);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }
}
