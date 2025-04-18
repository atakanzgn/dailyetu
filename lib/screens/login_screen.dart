import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'signin_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color _primaryColor = Color(0xFF6B7FCE);
  static const Color _backgroundColor = Color(0xFFD4EBFF);
  static const Color _textColor = Color(0xFF262161);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: _backgroundColor,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    'ETU Daily',
                    style: TextStyle(
                      fontSize: 36,
                      fontFamily: 'PlaywriteAUSA',
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Merhaba',
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'PlaywriteAUSA',
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(95),
                  ),
                ),
                child: Stack(
                  children: [
                    OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Transform.translate(
                        offset: const Offset(0, 100),
                        child: Opacity(
                          opacity: 0.05,
                          child: Image.asset(
                            'assets/images/snowflake.png',
                            width: 800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      right: 30,
                      bottom: 40,
                      child: Column(
                        children: [
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google_logo.png',
                                        height: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Google ile girin',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF707070), width: 1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignInScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: const Center(
                                  child: Text(
                                    'Giriş yap',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Hesabınız yok mu? ',
                                style: TextStyle(
                                  color: Color(0xFF707070),
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Kayıt olun',
                                  style: TextStyle(
                                    color: _textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 