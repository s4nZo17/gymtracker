import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../theme.dart';

Future<Color?> showCustomColorDialog({
  required BuildContext context,
  required Color initialColor,
  required String title,
  required String cancelText,
  required String saveText,
  required String invalidHexText,
}) {
  return showDialog<Color>(
    context: context,
    builder: (dialogContext) => _CustomColorDialog(
      initialColor: initialColor,
      title: title,
      cancelText: cancelText,
      saveText: saveText,
      invalidHexText: invalidHexText,
      dialogContext: dialogContext,
    ),
  );
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({
    required this.initialColor,
    required this.title,
    required this.cancelText,
    required this.saveText,
    required this.invalidHexText,
    required this.dialogContext,
  });

  final Color initialColor;
  final String title;
  final String cancelText;
  final String saveText;
  final String invalidHexText;
  final BuildContext dialogContext;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late Color _draft;
  late TextEditingController _hexCtrl;
  bool _invalidHex = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialColor;
    _hexCtrl = TextEditingController(text: colorToHexString(_draft));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      title: Text(widget.title, style: TextStyle(color: kText)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorPicker(
              pickerColor: _draft,
              onColorChanged: (c) {
                setState(() {
                  _draft = c;
                  _invalidHex = false;
                  _hexCtrl.text = colorToHexString(c);
                });
              },
              enableAlpha: false,
              displayThumbColor: true,
              portraitOnly: true,
              labelTypes: const [],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hexCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'HEX',
                hintText: '#RRGGBB',
                errorText: _invalidHex ? widget.invalidHexText : null,
              ),
              onChanged: (value) {
                final parsed = parseHexColor(value);
                setState(() {
                  if (parsed != null) {
                    _draft = parsed;
                    _invalidHex = false;
                  } else {
                    _invalidHex = value.trim().isNotEmpty;
                  }
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(widget.dialogContext).pop(),
          child: Text(widget.cancelText),
        ),
        TextButton(
          onPressed: () {
            final parsed = parseHexColor(_hexCtrl.text);
            if (parsed == null) {
              setState(() => _invalidHex = true);
              return;
            }
            Navigator.of(widget.dialogContext).pop(parsed);
          },
          child: Text(widget.saveText, style: TextStyle(color: kAccent)),
        ),
      ],
    );
  }
}
