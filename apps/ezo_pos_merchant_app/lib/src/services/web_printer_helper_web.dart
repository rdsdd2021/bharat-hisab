// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Universal Web Thermal Receipt Printer Handler
/// Generates a standardized Blob HTML document with exact 58mm/80mm continuous roll styling,
/// launches the printable view, and invokes browser system print.
void triggerWebPrintReceipt({
  required String asciiReceipt,
  required String invoiceNumber,
  required int rollWidthMm,
}) {
  final widthCss = rollWidthMm == 58 ? '48mm' : '72mm';
  final pageCss = rollWidthMm == 58 ? '58mm' : '80mm';

  final safeText = asciiReceipt
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Receipt #$invoiceNumber</title>
  <style>
    @page {
      size: $pageCss auto;
      margin: 0;
    }
    html, body {
      margin: 0;
      padding: 0;
      background-color: #fff;
    }
    body {
      font-family: 'Courier New', Courier, monospace;
      width: $widthCss;
      margin: 2mm auto;
      font-size: 11.5px;
      line-height: 1.25;
      color: #000;
    }
    pre {
      font-family: inherit;
      font-size: inherit;
      white-space: pre-wrap;
      word-wrap: break-word;
      margin: 0;
      padding: 0;
    }
    @media screen {
      body {
        padding: 10px;
        border: 1px dashed #ccc;
      }
    }
  </style>
</head>
<body>
  <pre>$safeText</pre>
  <script>
    window.onload = function() {
      setTimeout(function() {
        window.focus();
        window.print();
      }, 250);
    };
  </script>
</body>
</html>
''';

  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank', 'width=450,height=650');
  
  // Clean up the object URL after 60 seconds
  Timer(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(url);
  });
}
