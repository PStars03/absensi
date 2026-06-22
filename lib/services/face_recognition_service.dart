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
      throw Exception('Gagal load model TFLite: $e');
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

      // 4. Konversi ke bentuk 4D List [1, 112, 112, 3] agar aman
      var input = List.generate(1, (i) => List.generate(112, (y) => List.generate(112, (x) => List.filled(3, 0.0))));
      for (int y = 0; y < 112; y++) {
        for (int x = 0; x < 112; x++) {
          final pixel = resizedFace.getPixel(x, y);
          input[0][y][x][0] = (pixel.r - 127.5) / 128.0;
          input[0][y][x][1] = (pixel.g - 127.5) / 128.0;
          input[0][y][x][2] = (pixel.b - 127.5) / 128.0;
        }
      }

      // 5. Run inference
      // Dapatkan dimensi output sesungguhnya dari model (contoh: [1, 192] atau [192])
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      
      Object output;
      if (outputShape.length == 1) {
         output = List.filled(outputShape[0], 0.0);
      } else {
         // asumsi shape = [1, x]
         output = List.generate(1, (i) => List.filled(outputShape[1], 0.0));
      }
      
      _interpreter!.run(input, output);

      // Kembalikan hasil flat list
      if (output is List<double>) {
         return output;
      } else if (output is List<List<double>>) {
         return output[0];
      } else if (output is List && output.isNotEmpty && output[0] is List) {
         return (output[0] as List).cast<double>();
      } else if (output is List) {
         return output.cast<double>();
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting embedding: $e');
      throw Exception('TFLite Error: $e');
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
      if (image.format.group == ImageFormatGroup.nv21 || image.planes.length == 1) {
        return _convertNV21(image);
      }
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

  static img.Image _convertNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image decoded = img.Image(width: width, height: height);
    
    if (image.planes.isEmpty) return decoded;
    
    final yBytes = image.planes[0].bytes;
    final vuBytes = image.planes.length > 1 ? image.planes[1].bytes : yBytes;
    final int vuOffset = image.planes.length > 1 ? 0 : width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = vuOffset + (j >> 1) * width;
      int u = 0;
      int v = 0;
      for (int i = 0; i < width; i++, yp++) {
        if (yp >= yBytes.length) break;
        
        int y = (0xff & yBytes[yp]) - 16;
        if (y < 0) y = 0;
        
        if ((i & 1) == 0 && uvp < vuBytes.length - 1) {
          v = (0xff & vuBytes[uvp++]) - 128;
          u = (0xff & vuBytes[uvp++]) - 128;
        }

        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0) {
          r = 0;
        } else if (r > 262143) {
          r = 262143;
        }
        
        if (g < 0) {
          g = 0;
        } else if (g > 262143) {
          g = 262143;
        }
        
        if (b < 0) {
          b = 0;
        } else if (b > 262143) {
          b = 262143;
        }

        decoded.setPixelRgb(i, j, (r >> 10) & 0xff, (g >> 10) & 0xff, (b >> 10) & 0xff);
      }
    }
    return decoded;
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
