import 'package:flutter/material.dart';
import '../common/color.dart';
import '../widgets/onboarding_widget.dart';
import 'Login_Screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int selectpage = 0;
  PageController controller = PageController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      selectpage = controller.page?.round() ?? 0;
      setState(() {});
    });
  }

  List pageList = [
    {
      "image": "assets/images/on_1.png",
      "title": "Track Your Health",
      "subtitle": "Don't worry about your health, we are here to help you",
    },
    {
      "image": "assets/images/on_2.png",
      "title": "Stay Fit",
      "subtitle": "Keep track of your fitness goals and achievements",
    },
    {
      "image": "assets/images/on_3.png",
      "title": "Healthy Eating",
      "subtitle": "Discover healthy recipes and meal plans",
    },
    {
      "image": "assets/images/on_4.png",
      "title": "Mental Wellness",
      "subtitle": "Tools and tips for maintaining mental health",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Tcolors.primaryColor1,
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: pageList.length,
            itemBuilder: (context, index) {
              var pObj = pageList[index] as Map<String, dynamic>;
              return OnboardingWidget(pObj: pObj);
            },
          ),

          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    color: Tcolors.primaryColor2,
                    value: (selectpage + 1) / 4,
                    strokeWidth: 2,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 25,
                  ),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.navigate_next,
                      color: Tcolors.primaryColor2,
                      size: 30,
                    ),
                    onPressed: () {
                      if (selectpage < 3) {
                        selectpage = selectpage + 1;
                        controller.jumpToPage(selectpage);
                        setState(() {});
                      } else {
                        // Navigate to login screen when reaching the last page (Mental Wellness)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
