import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/painters/animated_wave_painter.dart';
import '../widgets/painters/compass_rose_painter.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/typewriter_text.dart';

/// Atmospheric prologue screen welcoming the player into the cartographic world.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _canProceed = false;

  static const String _prologueText =
      'Your bloodline is bound to a ship that will not stay sunk. '
      'When one captain falls, the Bloodbound Ship returns for an heir.\n\n'
      'Beyond the Siren Shoals, three Titans guard the path to the Abyssal Font: '
      'the Kraken, the World Serpent, and the Ancient Leviathan.\n\n'
      'Hunt them. Break the curse. Bring your family home.';

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      body: Stack(
        children: [
          // Background animated wave lines
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) => CustomPaint(
              painter: AnimatedWavePainter(progress: _waveController.value),
              size: Size.infinite,
            ),
          ),
          // Compass rose in background center
          Center(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: const CompassRosePainter(),
                size: const Size(260, 260),
              ),
            ),
          ),
          // Main layout
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'THE MONSTROUS SEA',
                      style: InkTheme.titleLarge.copyWith(fontSize: 42),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— AN 18TH CENTURY NAVAL ROGUELIKE —',
                      style: InkTheme.subtitle.copyWith(letterSpacing: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentSurface.withValues(
                          alpha: 0.85,
                        ),
                        border: Border.all(
                          color: InkTheme.inkMuted,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TypewriterText(
                        text: _prologueText,
                        style: InkTheme.body.copyWith(fontSize: 18),
                        durationPerChar: const Duration(milliseconds: 12),
                        onFinished: () {
                          if (mounted) {
                            setState(() {
                              _canProceed = true;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 36),
                    AnimatedOpacity(
                      opacity: _canProceed ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 500),
                      child: InkButton(
                        label: 'EMBARK UPON THE HUNT',
                        isPrimary: true,
                        onPressed: widget.onStart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
