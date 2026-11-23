import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/cas_mascot_view.dart';
import '../../shared/widgets/casama_button.dart';

enum RouletteMode { randomHousemate, justForMe }

class ChoreRouletteScreen extends ConsumerStatefulWidget {
  const ChoreRouletteScreen({super.key});

  @override
  ConsumerState<ChoreRouletteScreen> createState() =>
      _ChoreRouletteScreenState();
}

class _ChoreRouletteScreenState extends ConsumerState<ChoreRouletteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  RouletteMode _rouletteMode = RouletteMode.randomHousemate;

  final List<_ChoreItem> _chores = [
    _ChoreItem('Take Out Trash', Icons.delete_outline, const Color(0xFF80CBC4)),
    _ChoreItem(
      'Grocery Run',
      Icons.shopping_cart_outlined,
      const Color(0xFFFF8A65),
    ),
    _ChoreItem(
      'Sweep Living Room',
      Icons.cleaning_services_outlined,
      const Color(0xFFFFD54F),
    ),
    _ChoreItem(
      'Mop Kitchen Floor',
      Icons.water_drop_outlined,
      const Color(0xFF64B5F6),
    ),
    _ChoreItem(
      'Clean Bathroom',
      Icons.bathtub_outlined,
      const Color(0xFFBA68C8),
    ),
    _ChoreItem(
      'Wipe Counters',
      Icons.countertops_outlined,
      const Color(0xFF4DB6AC),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    setState(() => _isSpinning = true);

    final random = Random();
    final extraSpins = 5 + random.nextInt(4); // 5 to 8 full revolutions
    final targetSegment = random.nextInt(_chores.length);
    final segmentAngle = (2 * pi) / _chores.length;

    // The arrow is at top (-pi / 2). Calculate ending angle so target lands under arrow
    final targetAngle =
        (extraSpins * 2 * pi) +
        (targetSegment * segmentAngle) +
        (segmentAngle / 2);

    _animation =
        Tween<double>(
            begin: _currentAngle,
            end: _currentAngle + targetAngle,
          ).animate(
            CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOutCubic,
            ),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _currentAngle = (_currentAngle + targetAngle) % (2 * pi);
              setState(() => _isSpinning = false);
              _showResultDialog(_chores[targetSegment]);
            }
          });

    _animController.forward(from: 0);
  }

  void _showResultDialog(_ChoreItem chore) {
    final repo = ref.read(repositoryProvider);
    final isSolo = _rouletteMode == RouletteMode.justForMe;

    final String assignedPerson;
    if (isSolo) {
      assignedPerson = repo.currentUser.displayName.isNotEmpty
          ? repo.currentUser.displayName
          : 'You';
    } else {
      final roommates = repo.members;
      assignedPerson =
          roommates[Random().nextInt(roommates.length)].profile.displayName;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedXl),
          backgroundColor: context.surfaceColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CasMascotView(
                pose: CasPose.roulette,
                width: 130,
                height: 130,
              ),
              const SizedBox(height: 12),
              Text(
                isSolo
                    ? 'Your Personal Challenge! 🎯'
                    : 'The Wheel Has Spoken! 🎯',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? CasamaColors.darkSurface
                      : const Color(0xFFFFECE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      chore.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.primaryCoral,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSolo
                          ? 'Assigned to: You (Solo Mode)'
                          : 'Assigned to: $assignedPerson',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isSolo
                    ? 'Tackle this chore to keep your dorm clean and earn Kasama points!'
                    : 'Fair, friendly, and decided by Casama!',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              CasamaButton(
                label: isSolo ? 'Add to My Tasks' : 'Add to Maintenance Tasks',
                onPressed: () {
                  repo.addTask(
                    title: chore.title,
                    category: TaskCategory.diy,
                    urgency: TaskUrgency.medium,
                    assigneeName: assignedPerson,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSolo
                            ? 'Added "${chore.title}" to your tasks!'
                            : 'Added "${chore.title}" assigned to $assignedPerson',
                      ),
                      backgroundColor: CasamaColors.midnightNavy,
                    ),
                  );
                },
                height: 44,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final angle = _isSpinning ? _animation.value : _currentAngle;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Chore Roulette'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: CasamaSpacing.xs),

            // Mode Selector Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSpinning
                          ? null
                          : () => setState(
                              () =>
                                  _rouletteMode = RouletteMode.randomHousemate,
                            ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _rouletteMode == RouletteMode.randomHousemate
                              ? CasamaColors.midnightNavy
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 16,
                              color:
                                  _rouletteMode == RouletteMode.randomHousemate
                                  ? Colors.white
                                  : context.textSecondaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Random Dormmate',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    _rouletteMode ==
                                        RouletteMode.randomHousemate
                                    ? Colors.white
                                    : context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSpinning
                          ? null
                          : () => setState(
                              () => _rouletteMode = RouletteMode.justForMe,
                            ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _rouletteMode == RouletteMode.justForMe
                              ? CasamaColors.primaryCoral
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: _rouletteMode == RouletteMode.justForMe
                                  ? Colors.white
                                  : context.textSecondaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Just For Me',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _rouletteMode == RouletteMode.justForMe
                                    ? Colors.white
                                    : context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              _rouletteMode == RouletteMode.randomHousemate
                  ? "Let's settle who does what fairly! 👥"
                  : "Can't decide what to do? Spin for yourself! 👤",
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),

            // Spinning Wheel Assembly
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow / Ring
                  Container(
                    width: 310,
                    height: 310,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: CasamaColors.midnightNavy.withValues(
                            alpha: context.isDark ? 0.3 : 0.08,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),

                  // Rotated Canvas
                  Transform.rotate(
                    angle: angle,
                    child: CustomPaint(
                      size: const Size(290, 290),
                      painter: _RouletteWheelPainter(chores: _chores),
                    ),
                  ),

                  // Top Pointer
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: CasamaColors.midnightNavy,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Central Spin Button (Matching Screen 10)
                  GestureDetector(
                    onTap: _isSpinning ? null : _spin,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: _isSpinning
                            ? CasamaColors.dustyBlue
                            : CasamaColors.primaryCoral,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: CasamaColors.primaryCoral.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isSpinning ? '...' : 'Spin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Good luck Banner (Screen 10)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE8),
                borderRadius: CasamaSpacing.roundedPill,
              ),
              child: Text(
                _rouletteMode == RouletteMode.justForMe
                    ? 'Ready to get things done? Spin away! 🚀'
                    : 'Good luck, Kasama! Let\'s see who\'s up! 🎉',
                style: const TextStyle(
                  color: CasamaColors.primaryCoral,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ChoreItem {
  final String title;
  final IconData icon;
  final Color color;

  _ChoreItem(this.title, this.icon, this.color);
}

class _RouletteWheelPainter extends CustomPainter {
  final List<_ChoreItem> chores;

  _RouletteWheelPainter({required this.chores});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / chores.length;

    for (int i = 0; i < chores.length; i++) {
      final startAngle = i * sweepAngle;
      final paint = Paint()
        ..color = chores[i].color
        ..style = PaintingStyle.fill;

      // Slice
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Slice border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Icon in slice
      final iconAngle = startAngle + (sweepAngle / 2);
      final iconDist = radius * 0.65;
      final iconX = center.dx + iconDist * cos(iconAngle);
      final iconY = center.dy + iconDist * sin(iconAngle);

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(chores[i].icon.codePoint),
          style: TextStyle(
            fontSize: 24,
            fontFamily: chores[i].icon.fontFamily,
            package: chores[i].icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(iconX, iconY);
      canvas.rotate(iconAngle + (pi / 2));
      iconPainter.paint(
        canvas,
        Offset(-iconPainter.width / 2, -iconPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
