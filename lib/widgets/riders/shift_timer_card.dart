import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/riders/providers/riders_provider.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class ShiftTimerCard extends ConsumerStatefulWidget {
  const ShiftTimerCard({super.key});

  @override
  ConsumerState<ShiftTimerCard> createState() => _ShiftTimerCardState();
}

class _ShiftTimerCardState extends ConsumerState<ShiftTimerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(shiftElapsedSecondsProvider.notifier).state++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = ref.watch(shiftElapsedSecondsProvider);
    const shiftDuration = 6 * 3600; // 6-hour shift
    final remaining = (shiftDuration - elapsed).clamp(0, shiftDuration);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF9A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shift Timer',
              style:
                  AppTextStyles.captionMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: AppDimensions.xs),
          Text(
            _format(remaining),
            style: AppTextStyles.statValue.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: remaining / shiftDuration,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            '${_format(elapsed)} elapsed',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
