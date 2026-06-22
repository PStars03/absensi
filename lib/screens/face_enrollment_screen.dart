import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/face_recognition_service.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isBusy = false;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isEnrolled = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkExistingEnrollment();
    _initializeCamera();
  }

  Future<void> _checkExistingEnrollment() async {
    final enrolled = await SupabaseService.hasFaceEnrolled();
    if (mounted) {
      setState(() => _isEnrolled = enrolled);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
      // Start auto detection
      if (!_isEnrolled) {
        _startCapture();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal inisialisasi kamera: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  void _startCapture() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isStreamingImages) return;
    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _isProcessing || _isEnrolled) return;
    _isBusy = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!.description;
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      
      InputImageFormat inputImageFormat = InputImageFormat.nv21;
      if (Platform.isIOS) {
        inputImageFormat = InputImageFormat.bgra8888;
      } else {
        inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
      }

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty && mounted) {
        _isProcessing = true;
        try {
          await _cameraController!.stopImageStream();
        } catch (_) {} // Ignore stop stream errors if already stopped
        await _saveEnrollment(image, faces.first, camera.sensorOrientation);
      }
    } catch (e) {
      // Ignore processing errors
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _saveEnrollment(CameraImage cameraImage, Face face, int rotation) async {
    setState(() => _isProcessing = true);
    try {
      final embedding = await FaceRecognitionService.extractFaceEmbedding(cameraImage, face, rotation);
      if (embedding == null) throw Exception('Gagal mengekstrak fitur wajah');

      // Save as Postgres BYTEA
      await SupabaseService.saveFaceEmbedding(embedding);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isEnrolled = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Wajah Terdaftar!',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Data wajah Anda berhasil disimpan.\nAnda sekarang dapat menggunakan absensi wajah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // pop dialog
                    
                    // Fetch profile to redirect to correct dashboard
                    SupabaseService.getCurrentUserProfile().then((profile) {
                      if (!mounted) return;
                      if (profile == null) {
                        Navigator.of(context).pushReplacementNamed('/login');
                        return;
                      }
                      final role = profile['role'] as String?;
                      if (role == 'admin') {
                        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
                      } else if (role == 'teacher') {
                        Navigator.of(context).pushReplacementNamed('/teacher-dashboard');
                      } else {
                        Navigator.of(context).pushReplacementNamed('/student-dashboard');
                      }
                    });
                  },
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Enrollment Error: $e');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat menyimpan data wajah. Silakan coba lagi. ($e)')),
      );
      // Restart camera stream if failed
      if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
        _startCapture();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Daftarkan Wajah'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEnrolled && !_isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 80),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Wajah Sudah Terdaftar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda dapat menggunakan absensi wajah.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isEnrolled = false);
                    _startCapture();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Daftar Ulang Wajah'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ] else ...[
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isProcessing ? AppColors.warning : AppColors.primaryLight,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isProcessing ? AppColors.warning : AppColors.primaryBlue)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isCameraInitialized
                          ? CameraPreview(_cameraController!)
                          : Container(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_rounded,
                                      color: Colors.white54, size: 64),
                                  SizedBox(height: 8),
                                  Text('Memuat kamera...',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white54,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isProcessing) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Menyimpan data wajah...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Arahkan wajah ke kamera',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistem akan otomatis mendeteksi wajah Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
