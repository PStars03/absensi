import 'dart:io';

void main() {
  final source = File(r'C:\Users\MARVEL\.gemini\antigravity-ide\brain\f3c21e1f-8f6b-47a4-bea8-4f5618de6cde\media__1782183819745.jpg');
  final destDir = Directory('assets/images');
  if (!destDir.existsSync()) {
    destDir.createSync(recursive: true);
  }
  source.copySync('assets/images/logo.jpg');
  print('Copy successful');
}
