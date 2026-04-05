import 'package:flutter/material.dart';

Widget verticalWidget
({
    required String name,
    required String image,
    required String points,
    required String rank,
    required String level,
    required Color badgeColor,
}) 
{
  return Transform.translate(
    offset: Offset(0, rank == '1' ? -15 : 0), 
    child: Container(
      width: 120,
      height:  225,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
           Radius.circular(30),
        ),
        border: Border.all(
        color: rank=='1' ? badgeColor : Colors.grey,
        width: 2,          
        ),
        boxShadow: [
            BoxShadow(
              color: Colors.grey, 
              blurRadius: rank=='1' ? 50 : 0, 
              spreadRadius: rank=='1' ? 3 : 0, 
            ),
        ],
      ),
      
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Avatar with border
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: rank == '1'
                      ? badgeColor
                      : rank == '2'
                          ? Colors.grey
                          : Colors.orange,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(image),
                  ),
                ),
              ),
    
              Positioned(
                top: -15, 
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white, // border effect
                  ),
                  child: CircleAvatar(
                    radius: rank == '1' ? 20 : 17,
                    backgroundColor: rank == '1'
                        ? badgeColor
                        : rank == '2'
                            ? Colors.grey
                            : Colors.orange,
                    child: Text(
                      rank == '1' ? '🏆' : rank,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    
          Text(
            name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
    
          SizedBox(height: 4),
          
          Text(
            "Level $level",
            style: TextStyle(),
          ),
    
          SizedBox(height: 4),
    
          Text(
            "$points",
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
          ),
    
          SizedBox(height: 3),
    
          Text(
            "Xp",
            style: TextStyle(),
          ),
        ],
      ),
    ),
  );
}
