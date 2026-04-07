import 'package:flutter/material.dart';

Widget verticalWidget({
  required String name,
  required String image,
  required String points,
  required String rank,
  required String level,
  required Color badgeColor,
}) {

  final bool isFirst = rank == '1';
  final bool isSecond = rank == '2';

  final Color rankColor = isFirst
      ? const Color(0xFFFFBF00)   // Gold
      : isSecond
          ? const Color(0xFFB0BEC5) // Silver
          : const Color(0xFFBF7C3A); // Bronze

  final String rankEmoji = isFirst ? '🏆' : isSecond ? '🥈' : '🥉'; //👑

  return Transform.translate(
    offset: Offset(0, isFirst ? -24 : 0),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isFirst ? 130 : 115,
      height: isFirst ? 240 : 215,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFirst
              ? [const Color(0xFFFFFDE7), const Color(0xFFFFF8E1)]
              : [Colors.white, const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: rankColor.withOpacity(isFirst ? 0.8 : 0.4),
          width: isFirst ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(isFirst ? 0.35 : 0.12),
            blurRadius: isFirst ? 28 : 12,
            spreadRadius: isFirst ? 2 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar Stack
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Glow ring behind avatar
                Container(
                  width: isFirst ? 88 : 78,
                  height: isFirst ? 88 : 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        rankColor.withOpacity(0.35),
                        rankColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                // Avatar
                CircleAvatar(
                  radius: isFirst ? 36 : 30,
                  backgroundColor: rankColor,
                  child: CircleAvatar(
                    radius: isFirst ? 33 : 27,
                    backgroundImage: AssetImage(image),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: isFirst ? -30 : -25,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: isFirst ? 22 : 18,
                      backgroundColor: rankColor,
                      child: Text(
                        rankEmoji,
                        style: TextStyle(fontSize: isFirst ? 14 : 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Name
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isFirst ? 15 : 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 3),

            // Level chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Lvl $level",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: rankColor.withOpacity(0.9),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Points
            Text(
              _formatPoints(points),
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: isFirst ? 15 : 13,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 1),
            
            // xp badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, size: 12, color: rankColor),
                const SizedBox(width: 4),
                const Text(
                  "XP",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                )
             ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatPoints(String points) {
  final n = int.tryParse(points) ?? 0;
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return points;
}