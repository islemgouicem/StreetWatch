import 'package:flutter/material.dart';

class PulsingMarker extends StatefulWidget {
    final String severity;

  const PulsingMarker({super.key, required this.severity});
  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ripple ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:  (widget.severity == 'low')? Colors.green
                        : (widget.severity == 'medium')? Colors.orange
                        : (widget.severity == 'high')? Colors.red
                        : Colors.grey,
                        border: Border.all(
                        color:  (widget.severity == 'low')? Colors.green
                          : (widget.severity == 'medium')? Colors.orange
                          : (widget.severity == 'high')? Colors.red
                          : Colors.grey,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Your original icon
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color:  (widget.severity == 'low')? Colors.green
              : (widget.severity == 'medium')? Colors.orange
              : (widget.severity == 'high')? Colors.red
              : Colors.grey,
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 50,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}