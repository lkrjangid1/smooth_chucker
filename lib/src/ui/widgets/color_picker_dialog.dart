import 'package:flutter/material.dart';

/// Dialog for picking a color
class ColorPickerDialog extends StatefulWidget {
  /// Dialog title
  final String title;

  /// Initial color
  final Color initialColor;

  /// Callback when a color is selected
  final Function(Color) onColorSelected;

  /// Constructor
  const ColorPickerDialog({
    super.key,
    required this.title,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display the current selected color
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // Material design color palette
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorOption(Colors.red),
                _buildColorOption(Colors.pink),
                _buildColorOption(Colors.purple),
                _buildColorOption(Colors.deepPurple),
                _buildColorOption(Colors.indigo),
                _buildColorOption(Colors.blue),
                _buildColorOption(Colors.lightBlue),
                _buildColorOption(Colors.cyan),
                _buildColorOption(Colors.teal),
                _buildColorOption(Colors.green),
                _buildColorOption(Colors.lightGreen),
                _buildColorOption(Colors.lime),
                _buildColorOption(Colors.yellow),
                _buildColorOption(Colors.amber),
                _buildColorOption(Colors.orange),
                _buildColorOption(Colors.deepOrange),
                _buildColorOption(Colors.brown),
                _buildColorOption(Colors.grey),
                _buildColorOption(Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onColorSelected(_selectedColor);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  /// Build a color option button
  Widget _buildColorOption(MaterialColor color) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: _selectedColor == color
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
