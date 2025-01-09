import 'package:flutter/material.dart';

class ClaimStepProgressIndicator extends StatefulWidget {
  const ClaimStepProgressIndicator({
    super.key,
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  State<ClaimStepProgressIndicator> createState() =>
      _ClaimStepProgressIndicatorState();
}

class _ClaimStepProgressIndicatorState
    extends State<ClaimStepProgressIndicator> {
  double lastProgress = 0;
  Tween<double> progressIndicatorTween = Tween(begin: 0, end: 0);

  void _updateProgressAnimation(double newProgress) {
    setState(() {
      progressIndicatorTween = Tween<double>(
        begin: lastProgress,
        end: newProgress,
      );
    });
    lastProgress = newProgress;
  }

  void _onStepProgress() {
    final progress = widget.progress;
    _updateProgressAnimation(progress);
  }

  @override
  void didUpdateWidget(covariant ClaimStepProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _onStepProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 12.0,
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        tween: progressIndicatorTween,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFFF2F2F7),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color,
            ),
            minHeight: 6.0,
            borderRadius: BorderRadius.circular(20),
          );
        },
      ),
    );
  }
}
