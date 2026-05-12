import 'package:flutter/material.dart';
import 'package:mobile_app/features/Ranks/presentation/utilities/image_handler.dart';

Widget hozrizontalWidget({
  required String name,
  required String? image,
  required String points,
  required String rank,
  required String level,
}) {

  final int rankNum = int.tryParse(rank) ?? 99;

  final Color rankColor = rankNum == 1
      ? const Color(0xFFFFBF00)
      : rankNum == 2
          ? const Color(0xFFB0BEC5)
          : rankNum == 3
              ? const Color(0xFFBF7C3A)
              : const Color(0xFF3F6EDC);

  final bool isTopThree = rankNum <= 3;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTopThree ? rankColor.withOpacity(0.4) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? rankColor.withOpacity(0.12)
                : Colors.black.withOpacity(0.05),
            blurRadius: isTopThree ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isTopThree
                    ? rankColor.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                isTopThree
                    ? (rankNum == 1 ? '🥇' : rankNum == 2 ? '🥈' : '🥉')
                    : '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isTopThree ? 18 : 13,
                  color: rankColor,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Avatar with colored ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTopThree ? rankColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: ProfileImage(imageUrl: image),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name & Level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "Level $level",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Points section
            Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPoints(points),

                  ),
                  const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F6EDC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 11, color: Color(0xFF3F6EDC)),
                      SizedBox(width: 4),
                      Text(
                        'XP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3F6EDC),
                        ),
                       ),
                    ],
                  ),
                ),
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
