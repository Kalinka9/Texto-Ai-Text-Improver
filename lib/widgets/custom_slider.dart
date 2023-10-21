import 'package:flutter/material.dart';

class CustomSlider extends StatelessWidget {
  final String minCaption;
  final String maxCaption;
  final double value;
  final Color color;
  final Function(double)? onChanged;

  const CustomSlider({
    required this.minCaption,
    required this.maxCaption,
    required this.value,
    required this.color,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SliderTheme(
            data: SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
            child: Slider(
              value: value,
              onChanged: (value) => onChanged!(value),
              activeColor: color,
              inactiveColor: Colors.grey[300],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minCaption,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              Text(
                maxCaption,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
