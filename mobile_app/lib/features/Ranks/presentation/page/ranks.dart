import 'package:flutter/material.dart';
import 'package:mobile_app/features/Ranks/presentation/widgets/horizontalWidget.dart';
import 'package:mobile_app/features/Ranks/presentation/widgets/verticalWidget.dart';

class RanksPage extends StatefulWidget {
  const RanksPage({super.key});

  @override
  State<RanksPage> createState() => _RanksPageState();
}

class _RanksPageState extends State<RanksPage> 
with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header and ranks
          Stack(
            children: [
              // Header
              Stack(
                children: [
                  // Main blue background
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F6EDC),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                  ),
                  // Top-right light circle
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Bottom-left light blob
                  Positioned(
                    bottom: -40,
                    left: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Text content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🏆 Leaderboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Top civic heroes this month",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Ranks List with staggered animation
              Padding(
                padding: EdgeInsets.only(top: 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 2nd place - slide from left with delay
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.5, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
                          ),
                        ),
                        child: verticalWidget(
                          name: "David",
                          points: "14044",
                          image: "lounis.png",
                          level: "14",
                          rank: "2",
                          badgeColor: const Color(0xFF3F6EDC),
                        ),
                      ),
                    ),
                    // 1st place - scale and bounce effect
                    ScaleTransition(
                      scale: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
                          ),
                        ),
                        child: verticalWidget(
                          name: "Maria",
                          points: "14515",
                          image: "lounis.png",
                          level: "10",
                          rank: "1",
                          badgeColor: Colors.amber,
                        ),
                      ),
                    ),
                    // 3rd place - slide from right with delay
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.5, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
                          ),
                        ),
                        child: verticalWidget(
                          name: "Alex",
                          points: "1227447",
                          image: "lounis.png",
                          level: "14",
                          rank: "3",
                          badgeColor: const Color(0xFF3F6EDC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Text ranks with fade in
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
              child: Text("All Rankings"),
            ),
          ),
          
          // Ranks list with slide from left animation
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
            )),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
                ),
              ),
              child: hozrizontalWidget(
                name: "David",
                points: "14044",
                image: "lounis.png",
                level: "14",
                rank: "4",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
