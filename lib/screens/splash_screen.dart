import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget
{
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
{
  @override
  void initState()
  {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async
  {
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;

    final token = ApiService.getToken();
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          token != null ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child)
        {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: const Color(0xFFD4EBFF),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Lottie.asset(
            'assets/animations/splash.json',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
} 