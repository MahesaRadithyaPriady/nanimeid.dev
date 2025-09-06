import 'package:flutter/material.dart';

class SeekHintsOverlay extends StatelessWidget {
  final bool showLeftHint;
  final bool showRightHint;
  final bool showRightBoost;

  const SeekHintsOverlay({
    super.key,
    required this.showLeftHint,
    required this.showRightHint,
    required this.showRightBoost,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: showLeftHint ? 1.0 : 0.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: showLeftHint ? 1.0 : 0.9,
                        child: Container(
                          margin: const EdgeInsets.only(left: 24),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.replay_10,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '-10s',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: showRightHint ? 1.0 : 0.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: showRightHint ? 1.0 : 0.9,
                        child: Container(
                          margin: const EdgeInsets.only(right: 24),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.forward_10,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '+10s',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: showRightBoost ? 1.0 : 0.0,
                child: Container(
                  margin: const EdgeInsets.only(right: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.flash_on,
                        color: Colors.pinkAccent,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '2x',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
