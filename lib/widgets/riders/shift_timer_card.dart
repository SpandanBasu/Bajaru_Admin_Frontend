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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick every second to refresh the elapsed time display.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _hhmmss(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final allRiders = ref.watch(ridersProvider);

    // Find the earliest shift start among currently-online riders.
    DateTime? shiftStart;
    for (final r in allRiders) {
      if (r.isOnline && r.shiftStartedAt != null) {
        if (shiftStart == null || r.shiftStartedAt!.isBefore(shiftStart)) {
          shiftStart = r.shiftStartedAt;
        }
      }
    }

    final bool shiftActive = shiftStart != null;
    final Duration elapsed =
        shiftActive ? DateTime.now().difference(shiftStart!) : Duration.zero;

    // 6-hour standard shift for progress bar only.
    const shiftDuration = Duration(hours: 6);
    final progressFraction =
        (elapsed.inSeconds / shiftDuration.inSeconds).clamp(0.0, 1.0);

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
          Text(
            shiftActive ? 'Shift In Progress' : 'No Active Shift',
            style: AppTextStyles.captionMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            shiftActive ? _hhmmss(elapsed) : '--:--:--',
            style: AppTextStyles.statValue.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: shiftActive ? progressFraction : 0,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            shiftActive
                ? 'Started at ${_fmtTime(shiftStart!)} · ${_hhmmss(elapsed)} elapsed'
                : 'Waiting for riders to come online',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }
}
