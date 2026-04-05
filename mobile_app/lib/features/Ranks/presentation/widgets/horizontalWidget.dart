import 'package:flutter/material.dart';

Widget hozrizontalWidget
({
    required String name,
    required String image,
    required String points,
    required String rank,
    required String level,
}) 
{
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9.0),
    child: Card(
      elevation: 6, // shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey, width: 2), // border
        ),
      
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
                "#$rank",
                style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            SizedBox(width: 16),
            
            CircleAvatar(
              radius: 27,
              backgroundImage: AssetImage(image),
            ),

            SizedBox(width: 16),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                
                SizedBox(height: 4),
                Text("Level $level"),
              ],
            ),
            
            Spacer(),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("$points", style: TextStyle(color: Color(0xFF3F6EDC), fontWeight: FontWeight.bold)),
                SizedBox(height: 2,),
                Text('XP')
              ],
            )
          ],
        ),
      ),
    ),
  );
}