import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/gondola_label_model.dart';
import '../services/label_renderer_service.dart';

class LabelPreviewWidget extends StatefulWidget {
  final GondolaLabelModel model;

  const LabelPreviewWidget({super.key, required this.model});

  @override
  State<LabelPreviewWidget> createState() => _LabelPreviewWidgetState();
}

class _LabelPreviewWidgetState extends State<LabelPreviewWidget> {
  ui.Image? _previewImage;
  bool _isLoading = false;
  bool _hasError = false;
  bool _pendingRerender = false;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  @override
  void didUpdateWidget(covariant LabelPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    // Uma renderização já está em andamento: marca que o modelo mudou de novo
    // e precisa de uma nova renderização assim que a atual terminar, em vez de
    // simplesmente descartar esta requisição (o que deixaria a preview desatualizada).
    if (_isLoading) {
      _pendingRerender = true;
      return;
    }
    setState(() => _isLoading = true);

    try {
      final img = await LabelRendererService.renderLabelImage(widget.model, isPreview: true);
      if (mounted) {
        setState(() {
          _previewImage = img;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Falha ao gerar preview da etiqueta: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }

    if (_pendingRerender) {
      _pendingRerender = false;
      _generatePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int rot = widget.model.rotationAngle;
    final int widthDots = (rot == 90 || rot == 270) ? widget.model.shelfHeightDots : widget.model.lengthDots;
    final int heightDots = (rot == 90 || rot == 270) ? widget.model.lengthDots : widget.model.shelfHeightDots;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.indigo),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Preview ($rot°)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${widget.model.lengthMm}x${widget.model.shelfHeightMm}mm (${widthDots}x${heightDots}d)',
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 220),
              alignment: Alignment.center,
              child: _isLoading && _previewImage == null
                  ? const CircularProgressIndicator()
                  : _previewImage != null
                      ? RawImage(
                          image: _previewImage,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        )
                      : _hasError
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey[500]),
                                const SizedBox(height: 4),
                                Text('Falha ao gerar preview', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            )
                          : const Text('Carregando preview...'),
            ),
          ],
        ),
      ),
    );
  }
}
