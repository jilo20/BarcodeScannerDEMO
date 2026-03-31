import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../providers/inventory_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer audioPlayer = AudioPlayer();
  final Map<String, Timer> _activeBarcodes = {};
  bool _showSuccessMarker = false;
  Color _overlayColor = Colors.white.withOpacity(0.5);
  double _overlayBorderWidth = 2.0;

  @override
  void dispose() {
    controller.dispose();
    audioPlayer.dispose();
    for (var timer in _activeBarcodes.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      await audioPlayer.play(AssetSource('beep.wav'));
    } catch (e) {
      debugPrint('Error playing beep: $e');
    }
  }


  Future<void> _handleBarcode(String code) async {
    if (_activeBarcodes.containsKey(code)) {
      // Barcode is still in view, reset the exit timer
      _activeBarcodes[code]?.cancel();
      _activeBarcodes[code] = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _activeBarcodes.remove(code);
          });
        }
      });
      return;
    }

    // New barcode detection (not currently "active")
    if (mounted) {
      setState(() {
        _activeBarcodes[code] = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _activeBarcodes.remove(code);
            });
          }
        });
      });
    }

    // Play beep sound
    _playBeep();

    if (mounted) {
      setState(() {
        _showSuccessMarker = true;
        _overlayColor = Colors.green;
        _overlayBorderWidth = 5.0;
      });
      
      // Reset visual feedback after a delay
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showSuccessMarker = false;
            _overlayColor = Colors.white.withOpacity(0.5);
            _overlayBorderWidth = 2.0;
          });
        }
      });

      // Record the scan to the API
      debugPrint('Scanning barcode: "$code"');
      final bool success = await context.read<InventoryProvider>().recordBarcodeScan(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully recorded scan: $code'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final error = context.read<InventoryProvider>().errorMessage ?? 'Failed to record scan';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.off:
                  case TorchState.unavailable:
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue?.trim();
                if (code != null && code.isNotEmpty) {
                  _handleBarcode(code);
                }
              }
            },
          ),
          // Custom overlay to guide the user
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                color: _showSuccessMarker ? Colors.green.withOpacity(0.2) : Colors.transparent,
                border: Border.all(color: _overlayColor, width: _overlayBorderWidth),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _showSuccessMarker 
                ? const Icon(Icons.check_circle, color: Colors.green, size: 80)
                : const SizedBox.shrink(),
            ),
          ),
          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Place the barcode inside the box',
                style: TextStyle(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  final TextEditingController textController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Manual Barcode Entry'),
                      content: TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. MILK-123456789',
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _handleBarcode(value); // Use the same handler for sound/prompt
                            Navigator.pop(context);
                          }
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (textController.text.isNotEmpty) {
                              _handleBarcode(textController.text);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.keyboard),
                label: const Text('Test with Manual Entry'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
