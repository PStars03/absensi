import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/face_recognition_service.dart';

class FaceScanScreen extends StatefulWidget {
  final String type; // 'masuk' or 'pulang'
  final String scheduleId;

  const FaceScanScreen({
    super.key, 
    this.type = 'masuk',
    required this.scheduleId,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> with SingleTickerProviderStateMixin {
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

  // Step tracking
  int _currentStep = 0;
  String _statusMessage = 'Arahkan wajah ke kamera';

  // GPS
  Position? _currentPosition;
  bool _gpsValid = false;
  String? _gpsError;

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

    _initializeCamera();
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

      setState(() {
        _isCameraInitialized = true;
        _currentStep = 1;
      });
      
      _startCapture();
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
    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _currentStep > 1) return;
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

      if (faces.isNotEmpty && mounted && _currentStep == 1) {
        _isProcessing = true;
        try {
          await _cameraController!.stopImageStream();
        } catch (_) {}
        
        setState(() {
          _statusMessage = 'Wajah terdeteksi. Memverifikasi...';
        });

        // Ekstrak embedding wajah dari kamera
        final liveEmbedding = await FaceRecognitionService.extractFaceEmbedding(image, faces.first, camera.sensorOrientation);
        if (liveEmbedding == null) {
          setState(() {
            _statusMessage = 'Gagal memproses wajah. Coba lagi.';
            _currentStep = 1;
          });
          _startCapture();
          return;
        }

        // Ambil embedding yang tersimpan di DB

        final student = await SupabaseService.getStudentProfile();
        final savedEmbeddingHex = student?['face_embedding'] as String?;
        final savedEmbedding = SupabaseService.decodeFaceEmbedding(savedEmbeddingHex);

        if (savedEmbedding == null || savedEmbedding.isEmpty) {
          setState(() {
            _statusMessage = 'Data wajah belum terdaftar!';
            _currentStep = 1;
          });
          return;
        }

        // Hitung jarak (Euclidean Distance)
        final distance = FaceRecognitionService.computeDistance(liveEmbedding, savedEmbedding);
        debugPrint('Face Distance: $distance');

        if (distance > 1.0) { // Threshold toleransi kemiripan
          setState(() {
            _statusMessage = 'Wajah tidak cocok! ($distance)';
            _currentStep = 1;
          });
          // Restart kamera setelah delay sebentar
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _currentStep == 1) _startCapture();
          });
          return;
        }

        setState(() {
          _currentStep = 2;
          _statusMessage = 'Wajah terverifikasi! Memeriksa lokasi GPS...';
        });
        await _validateGPS();
      }
    } catch (e) {
      debugPrint('Error in face scan: $e');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _validateGPS() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'Layanan lokasi tidak aktif. Aktifkan GPS Anda.';
          _statusMessage = _gpsError!;
          _currentStep = 4;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Izin lokasi ditolak.';
            _statusMessage = _gpsError!;
            _currentStep = 4;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = 'Izin lokasi ditolak permanen. Ubah di pengaturan.';
          _statusMessage = _gpsError!;
          _currentStep = 4;
        });
        return;
      }

      // Get current position (optimized for speed)
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null && DateTime.now().difference(position.timestamp).inMinutes < 2) {
        _currentPosition = position;
      } else {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      }

      // Check against attendance locations from database
      final locations = await SupabaseService.getAttendanceLocations();
      
      if (locations.isEmpty) {
        _gpsValid = true;
      } else {
        for (final loc in locations) {
          final distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble(),
          );
          
          final radius = (loc['radius_meters'] as num).toDouble();
          if (distance <= radius) {
            _gpsValid = true;
            break;
          }
        }
      }

      if (!mounted) return;

      if (_gpsValid) {
        setState(() {
          _currentStep = 3;
          _statusMessage = 'Lokasi valid! Menyimpan absensi...';
        });
        await _recordAttendance();
      } else {
        setState(() {
          _gpsError = 'Anda berada di luar jangkauan area sekolah.';
          _statusMessage = _gpsError!;
          _currentStep = 4; // Error step
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsError = 'Gagal memverifikasi lokasi: $e';
        _statusMessage = _gpsError!;
        _currentStep = 4;
      });
    }
  }

  void _restartCamera() {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      _startCapture();
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Future<void> _recordAttendance() async {
    try {
      if (widget.type == 'masuk') {
        await SupabaseService.checkIn(
          widget.scheduleId,
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
          faceVerified: true,
        );
      } else {
        await SupabaseService.checkOut(widget.scheduleId);
      }

      if (!mounted) return;
      setState(() {
        _currentStep = 4;
        _statusMessage = 'Absensi berhasil!';
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
              Text(
                'Absensi ${widget.type == 'masuk' ? 'Masuk' : 'Pulang'} Berhasil!',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tercatat pada ${TimeOfDay.now().format(ctx)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '📍 GPS Verified',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.success,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Kembali'),
                ),
              ),
            ],
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStep = 4;
        _statusMessage = 'Gagal mencatat absensi. $e';
        _gpsError = 'Terjadi kesalahan saat menyimpan data.';
      });
    }
  }

  Color get _borderColor {
    switch (_currentStep) {
      case 2: return const Color(0xFFF59E0B); // GPS check
      case 3: return AppColors.success;       // Done
      default: return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('Absensi ${widget.type == 'masuk' ? 'Masuk' : 'Pulang'}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera Preview
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _borderColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _borderColor.withValues(alpha: 0.3),
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
            const SizedBox(height: 32),

            // Status Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: _gpsError != null && _currentStep == 1
                      ? AppColors.error
                      : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_currentStep > 1 && _currentStep < 4)
              const CircularProgressIndicator(),

            if (_currentStep == 4)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                    _gpsError = null;
                    _statusMessage = 'Arahkan wajah Anda ke dalam lingkaran';
                  });
                  _restartCamera();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
