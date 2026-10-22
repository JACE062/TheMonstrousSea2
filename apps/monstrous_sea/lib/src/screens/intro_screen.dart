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
      'For as long as anyone remembers, your family has been bound to the Sea... '
      '\nTales tell of a long-ago captain who faced certain doom in the middle of a devastating storm. '
      '\nThe captain made a desperate plea: whatever damage the ship suffered, let it return to shore. '
      '\nIt seems a deal was struck, as the ship did indeed return from the voyage, but with nary a soul on board. '
      '\nEver since, when its captain meets a watery end, '
      'the Bloodbound Ship returns for an heir to take the helm once more.\n\n'
      'You would refuse to venture out, but the Salt-Sickness has begun to wither away at your bones, '
      'as it did to every chosen heir before you. '
      '\nYou know, deep down, that something is calling you out to Sea, and you cannot ignore it '
      'any more than your ancestors could. '
      '\n\nYou know that there are great beasts and ancient, foul leviathans that await you in that Monstrous Sea, '
      'but you have no choice but to take up your burden and calling. You can only hope that maybe, '
      'just maybe, you’ll finally be the one to make it back alive.'
      '\nHunt them. Find the source of the curse. Bring your family peace.';

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
      bottomNavigationBar: ColoredBox(
        color: InkTheme.parchmentBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              heightFactor: 1,
              child: AnimatedOpacity(
                opacity: _canProceed ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 500),
                child: InkButton(
                  label: 'EMBARK UPON THE HUNT',
                  isPrimary: true,
                  onPressed: widget.onStart,
                ),
              ),
            ),
          ),
        ),
      ),
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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'THE MONSTROUS SEA',
                      style: InkTheme.titleLarge.copyWith(
                        fontSize: MediaQuery.sizeOf(context).width < 600
                            ? 30
                            : 42,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— AN 18TH-CENTURY NAVAL ROGUELITE —',
                      style: InkTheme.subtitle.copyWith(letterSpacing: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: EdgeInsets.all(
                        MediaQuery.sizeOf(context).width < 600 ? 16 : 20,
                      ),
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
