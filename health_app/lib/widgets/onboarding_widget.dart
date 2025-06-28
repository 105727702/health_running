import 'package:flutter/material.dart';

class OnboardingWidget extends StatelessWidget {
  final Map<String, dynamic> pObj;
  const OnboardingWidget({super.key, required this.pObj});

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return SizedBox(
      width: media.width,
      height: media.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            "${pObj['image']}",
            width: media.width,
            fit: BoxFit.fitWidth,
          ),

          SizedBox(height: media.width * 0.1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "${pObj['title']}",
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "${pObj['subtitle']}",
              style: TextStyle(
                fontSize: 24,
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
