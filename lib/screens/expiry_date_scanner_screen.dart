import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../services/expiry_date_detector.dart';

class ExpiryDateScannerScreen extends StatefulWidget {
  const ExpiryDateScannerScreen({super.key});

  @override
  State<ExpiryDateScannerScreen> createState() => _ExpiryDateScannerScreenState();
}

class _ExpiryDateScannerScreenState extends State<ExpiryDateScannerScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  ExpiryDateDetector _detector = ExpiryDateDetector();
  String? _detectedDate;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    print("Scanner screen initialized");
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print("Initializing camera...");
    
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      print("Camera permission status: $status");
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      print("Found ${_cameras?.length} cameras");
      
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      // Initialize back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      print("Initializing camera controller...");
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      print("Camera controller initialized successfully");
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }

      // Start auto-scanning
      _startAutoScan();
    } catch (e) {
      print("Camera initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  void _startAutoScan() {
  Timer.periodic(const Duration(seconds: 3), (timer) async {
    if (!_isScanning || _isProcessing || !_isCameraInitialized || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_detectedDate != null) {
      timer.cancel();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Use the simplified detector method
      final date = await _detector.detectExpiryDateFromCamera(_controller!);
      
      if (mounted) {
        setState(() {
          _detectedDate = date;
          _isProcessing = false;
        });
      }

      if (date != null) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Expiry date detected: $date')),
          );
          // Wait a moment then return
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context, date);
            }
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print("Error processing image: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Expiry Date'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: _buildCameraPreview(),
      floatingActionButton: _detectedDate != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, _detectedDate);
              },
              label: const Text('Use Detected Date'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CameraPreview(_controller!),
        _buildOverlay(),
        if (_isProcessing)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (_detectedDate != null)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Expiry Date Detected!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _detectedDate!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 300,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt, 
              color: Colors.white, 
              size: 40
            ),
            const SizedBox(height: 8),
            const Text(
              'Aim at expiry date',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Look for "EXP", "Use By", or date formats',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
      });

      final date = await _detector.detectExpiryDateFromImage(pickedFile.path);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _detectedDate = date;
        });
      }

      if (date != null) {
        Navigator.pop(context, date);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No expiry date found in image')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }
}