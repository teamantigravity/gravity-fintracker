import 'package:fintracker/screens/onboard/widgets/currency_pic.dart';
import 'package:fintracker/screens/onboard/widgets/landing.dart';
import 'package:fintracker/screens/onboard/widgets/profile.dart';
import 'package:flutter/material.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LandingPage(onGetStarted: (){
            _pageController.jumpToPage(1);
          },),
          ProfileWidget(onGetStarted: (){
            _pageController.jumpToPage(2);
          },),
          const CurrencyPicWidget()
        ],
      ),
    );
  }
}
