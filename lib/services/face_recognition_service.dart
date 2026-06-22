import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
      _isInitialized = true;
      debugPrint('Face Recognition Model Loaded Successfully.');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  static void close() {
    _interpreter?.close();
    _isInitialized = false;
  }

  /// Mengekstrak embedding wajah dari CameraImage dan Bounding Box Face
  static Future<List<double>?> extractFaceEmbedding(CameraImage cameraImage, Face face, int rotation) async {
    if (!_isInitialized || _interpreter == null) {
      await init();
      if (!_isInitialized) return null;
    }

    try {
      // 1. Convert CameraImage to img.Image
      img.Image? decodedImage = _convertCameraImage(cameraImage);
      if (decodedImage == null) return null;

      // Putar gambar sesuai orientasi kamera agar cocok dengan BoundingBox MLKit
      if (rotation == 90) {
        decodedImage = img.copyRotate(decodedImage, angle: 90);
      } else if (rotation == 180) {
        decodedImage = img.copyRotate(decodedImage, angle: 180);
      } else if (rotation == 270) {
        decodedImage = img.copyRotate(decodedImage, angle: 270);
      }

      // 2. Crop face from the image
      final rect = face.boundingBox;
      
      // Hitung batas crop agar tidak keluar dari gambar (handle padding dll)
      int x = max(0, rect.left.toInt());
      int y = max(0, rect.top.toInt());
      int w = min(decodedImage.width - x, rect.width.toInt());
      int h = min(decodedImage.height - y, rect.height.toInt());
      
      img.Image croppedFace = img.copyCrop(decodedImage, x: x, y: y, width: w, height: h);

      // 3. Resize ke ukuran 112x112 sesuai input MobileFaceNet
      img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      // 4. Konversi ke bentuk matriks RGB float32 [-1, 1]
      // MobileFaceNet input shape: [1, 112, 112, 3]
      var input = List.generate(1, (i) => 
        List.generate(112, (y) => 
          List.generate(112, (x) {
            final pixel = resizedFace.getPixel(x, y);
            return [
              (pixel.r - 127.5) / 128.0,
              (pixel.g - 127.5) / 128.0,
              (pixel.b - 127.5) / 128.0
            ];
          })
        )
      );

      // 5. Run inference
      // Output shape untuk MobileFaceNet: [1, 192]
      var output = List.generate(1, (i) => List.filled(192, 0.0));
      _interpreter!.run(input, output);

      return output[0];
    } catch (e) {
      debugPrint('Error extracting embedding: $e');
      return null;
    }
  }

  /// Menghitung jarak (Euclidean Distance) antara dua embedding wajah
  /// Biasanya threshold yang baik adalah di bawah 1.0 atau 1.2 untuk MobileFaceNet
  static double computeDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  // --- Helper: Konversi CameraImage ke package:image ---
  static img.Image? _convertCameraImage(CameraImage image) {
    if (Platform.isAndroid) {
      return _convertYUV420(image);
    } else if (Platform.isIOS) {
      return _convertBGRA8888(image);
    }
    return null;
  }

  static img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _convertYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    final img.Image decoded = img.Image(width: width, height: height);
    
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final int index = y * yPlane.bytesPerRow + x;

        // Cegah OutOfBounds (RangeError) pada beberapa jenis layar HP
        if (index >= yPlane.bytes.length || uvIndex >= uPlane.bytes.length || uvIndex >= vPlane.bytes.length) {
          continue;
        }

        final yp = yPlane.bytes[index];
        final up = uPlane.bytes[uvIndex];
        final vp = vPlane.bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round();
        int b = (yp + up * 1814 / 1024 - 227).round();

        decoded.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
      }
    }
    return decoded;
  }
}
