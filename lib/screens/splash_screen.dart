import 'package:flutter/material.dart';
import '../api_config.dart';
import 'auth_screen.dart';
import 'setup_wizard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _accentGreen = Color(0xFF22C55E);
  static const _bg = Color(0xFF0F172A);

  late final AnimationController _barsController;
  late final AnimationController _textController;
  late final AnimationController _exitController;

  late final List<Animation<double>> _barAnimations;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _exitFade;

  final List<double> _barHeights = [26, 46, 34, 60, 40];

  @override
  void initState() {
    super.initState();

    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Each bar grows with a staggered start, like a chart rendering live.
    _barAnimations = List.generate(_barHeights.length, (i) {
      final start = i * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _barsController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textSlide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _exitFade = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOut,
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _barsController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    await _exitController.forward();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => globalSettings.setupComplete
            ? const AuthScreen()
            : const SetupWizardScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _barsController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _exitFade,
        builder: (context, child) {
          return Opacity(opacity: 1 - _exitFade.value, child: child);
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 90,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_barHeights.length, (i) {
                    return AnimatedBuilder(
                      animation: _barAnimations[i],
                      builder: (context, _) {
                        return Container(
                          width: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: _barHeights[i] * _barAnimations[i].value,
                          decoration: BoxDecoration(
                            color: _accentGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: child,
                    ),
                  );
                },
                child: const Column(
                  children: [
                    Text(
                      'RETAIL ANALYTICS ENGINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Real-time insight for real businesses',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
