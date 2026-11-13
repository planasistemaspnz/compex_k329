import 'package:flutter/material.dart';

/// Seletor de ângulo de rotação da etiqueta no cabeçote térmico
class RotationSelectorWidget extends StatelessWidget {
  final int currentAngle;
  final ValueChanged<int> onAngleChanged;

  const RotationSelectorWidget({
    super.key,
    required this.currentAngle,
    required this.onAngleChanged,
  });

  // 360° é intencionalmente um duplicado visual de 0° (rotação completa), mantido
  // por simetria na fileira de chips — não remover como se fosse um valor espúrio.
  static const List<int> availableAngles = [0, 90, 270, 360];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.rotate_right, size: 20, color: Colors.indigo),
            const SizedBox(width: 8),
            const Text('Rotação:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: availableAngles.map((angle) {
                  final isSelected = currentAngle == angle;
                  return ChoiceChip(
                    label: Text('$angle°', style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onAngleChanged(angle);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
