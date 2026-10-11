import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/ink_theme.dart';

/// Animated text widget typing out characters one by one with antique cadence.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.durationPerChar = const Duration(milliseconds: 35),
    this.onFinished,
  });

  final String text;
  final TextStyle? style;
  final Duration durationPerChar;
  final VoidCallback? onFinished;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _charIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _charIndex = 0;
      _timer?.cancel();
      _startTyping();
    }
  }

  void _startTyping() {
    if (widget.text.isEmpty) return;
    _timer = Timer.periodic(widget.durationPerChar, (timer) {
      if (_charIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _charIndex++;
          });
        }
      } else {
        timer.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedText = widget.text.substring(0, _charIndex);
    return Text(
      displayedText,
      style: widget.style ?? InkTheme.body,
    );
  }
}
