import 'package:flutter/foundation.dart';

/// Accessibility and gameplay settings controller for The Monstrous Sea.
class GameSettings extends ChangeNotifier {
  GameSettings._();

  static final GameSettings instance = GameSettings._();

  double _fontScale = 1.15;
  bool _highLegibilityFont = false;

  /// Current text scaling multiplier (1.0 = standard, 1.15 = large, 1.30 = extra large).
  double get fontScale => _fontScale;

  /// When true, renders clean high-contrast serif fonts instead of stylized calligraphic fonts.
  bool get highLegibilityFont => _highLegibilityFont;

  void setFontScale(double scale) {
    if ((_fontScale - scale).abs() < 0.001) return;
    _fontScale = scale;
    notifyListeners();
  }

  void setHighLegibilityFont(bool enabled) {
    if (_highLegibilityFont == enabled) return;
    _highLegibilityFont = enabled;
    notifyListeners();
  }

  void resetDefaults() {
    _fontScale = 1.15;
    _highLegibilityFont = false;
    notifyListeners();
  }
}
