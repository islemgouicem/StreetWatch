import 'package:flutter/material.dart';
import 'package:mobile_app/features/Ranks/presentation/widgets/horizontalWidget.dart';
import 'package:mobile_app/features/Ranks/presentation/widgets/verticalWidget.dart';

class RanksPage extends StatelessWidget {
  const RanksPage({super.key});

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
                //  Main blue background
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

                //  Top-right light circle
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

                //  Bottom-left light blob
                Positioned(
                  bottom: -40,
                  left: -30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle
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
                                   
              // Ranks List
              Padding(
                padding: EdgeInsets.only(top: 120),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 2nd place
                    verticalWidget(
                      name: "David",
                      points: "14044",
                      image: "lounis.png",
                      level: "14",
                      rank: "2",
                      badgeColor: Color(0xFF3F6EDC),
                    ),
                            
                    // 1st place
                    verticalWidget(
                      name: "Maria",
                      points: "14515",
                      image: "lounis.png",
                      level: "10",
                      rank: "1",
                      badgeColor: Colors.amber,
                    ),
                            
                    // 3rd place
                    verticalWidget(
                      name: "Alex",
                      points: "1227447",
                      image: "lounis.png",
                      level: "14",
                      rank: "3",
                      badgeColor: Color(0xFF3F6EDC),
                    ),
                            
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10),
            
          // Text ranks 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            child: Text("All Rankings"),
          ),
            
          // Ranks list
          hozrizontalWidget(
            name: "David",
            points: "14044",
            image: "lounis.png",
            level: "14",
            rank: "2",
          ),

        ],
      ),
    );
  }
}