import 'package:flutter/material.dart';

Widget showDetails(BuildContext context) {
  return Container(
    padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
    decoration: BoxDecoration(
      color: Colors.blueGrey[50],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // don't take full screen height
      children: [
        // Top info row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'lounis.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 10),

            // Description
            Expanded( // prevents overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Damaged Sign',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Low',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Algiers, Algeria'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 16),
                      Text('Algiers, Algeria'),
                    ],
                  ),
                ],
              ),
            ),

            // Close button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,           
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(30, 30),
                maximumSize: const Size(30, 30),
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Status and reporter cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                child: Column(
                  children: const [
                    Text('Reported by', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Lounis Kre', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                child: Column(
                  children: const [
                    Text('Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Verified', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    ),
  );
}