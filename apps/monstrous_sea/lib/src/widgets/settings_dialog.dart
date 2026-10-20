import 'package:flutter/material.dart';

import '../settings/game_settings.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';

/// Modal dialog allowing the user to configure font scaling and legibility settings.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _settings = GameSettings.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: InkTheme.parchmentSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: InkTheme.inkPrimary, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x60000000),
                    blurRadius: 16,
                    offset: Offset(4, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.settings,
                                color: InkTheme.inkPrimary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'SETTINGS & ACCESSIBILITY',
                                  style: InkTheme.titleMedium.copyWith(
                                    fontSize: 20,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: InkTheme.inkSecondary,
                          ),
                          tooltip: 'Close settings',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: InkTheme.inkMuted, thickness: 1.2),
                    const SizedBox(height: 12),

                    // Section 1: Font Scaling
                    Text(
                      'TEXT SIZE / SCALE',
                      style: InkTheme.statLabel.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adjust text magnification across all screens, charts, and chronicle logs.',
                      style: InkTheme.caption.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _scaleOption(
                          label: 'Normal',
                          subtitle: '100%',
                          scale: 1.0,
                          isSelected: (_settings.fontScale - 1.0).abs() < 0.05,
                        ),
                        const SizedBox(width: 8),
                        _scaleOption(
                          label: 'Large',
                          subtitle: '115%',
                          scale: 1.15,
                          isSelected: (_settings.fontScale - 1.15).abs() < 0.05,
                        ),
                        const SizedBox(width: 8),
                        _scaleOption(
                          label: 'Extra Large',
                          subtitle: '130%',
                          scale: 1.30,
                          isSelected: (_settings.fontScale - 1.30).abs() < 0.05,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Font Style / Legibility
                    Text(
                      'FONT STYLE & READABILITY',
                      style: InkTheme.statLabel.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Switch between atmospheric antique typography and clean high-legibility print.',
                      style: InkTheme.caption.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _fontStyleOption(
                          title: 'Atmospheric Ink',
                          subtitle: 'Antique 18th-century print',
                          isHighLegibility: false,
                          isSelected: !_settings.highLegibilityFont,
                        ),
                        const SizedBox(width: 8),
                        _fontStyleOption(
                          title: 'High Legibility',
                          subtitle: 'Clean serif, zero flourishes',
                          isHighLegibility: true,
                          isSelected: _settings.highLegibilityFont,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Live Preview Box
                    Text(
                      'READABILITY PREVIEW',
                      style: InkTheme.statLabel.copyWith(
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentHighlight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: InkTheme.parchmentBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STANDARD FLAGSHIP • 90/90 HP',
                            style: InkTheme.statLabel.copyWith(
                              fontSize: 13,
                              color: InkTheme.goldAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"The leviathan thrashes in the deep swell! Load the broadside cannons and brace for impact!"',
                            style: InkTheme.body.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The Sargasso Drift: Slain Giant Squid • Loot: 25g Doubloons acquired.',
                            style: InkTheme.caption.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _settings.resetDefaults(),
                          child: Text(
                            'Reset to Default',
                            style: InkTheme.statLabel.copyWith(
                              color: InkTheme.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        InkButton(
                          label: 'DONE',
                          isPrimary: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scaleOption({
    required String label,
    required String subtitle,
    required double scale,
    required bool isSelected,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label text size ($subtitle)',
        child: InkWell(
          onTap: () => _settings.setFontScale(scale),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? InkTheme.parchmentHighlight
                  : InkTheme.parchmentDark.withValues(alpha: 0.3),
              border: Border.all(
                color: isSelected ? InkTheme.goldAccent : InkTheme.inkMuted,
                width: isSelected ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: InkTheme.statLabel.copyWith(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? InkTheme.inkPrimary
                        : InkTheme.inkSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: InkTheme.caption.copyWith(
                    fontSize: 12,
                    color: isSelected ? InkTheme.goldAccent : InkTheme.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fontStyleOption({
    required String title,
    required String subtitle,
    required bool isHighLegibility,
    required bool isSelected,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$title font style',
        child: InkWell(
          onTap: () => _settings.setHighLegibilityFont(isHighLegibility),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? InkTheme.parchmentHighlight
                  : InkTheme.parchmentDark.withValues(alpha: 0.3),
              border: Border.all(
                color: isSelected ? InkTheme.goldAccent : InkTheme.inkMuted,
                width: isSelected ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: InkTheme.statLabel.copyWith(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? InkTheme.inkPrimary
                        : InkTheme.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: InkTheme.caption.copyWith(
                    fontSize: 12,
                    color: isSelected ? InkTheme.goldAccent : InkTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
