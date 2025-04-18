import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'reset_password.dart';

class SignInScreen extends StatefulWidget
{
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}
class _SignInScreenState extends State<SignInScreen>
{
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  @override
  void dispose()
  {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _handleSignIn() async
  {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(()
    {
      _isLoading = true;
    });
    try
    {
      final result = await ApiService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (result['success'] && result['token'] != null) {
        if (mounted) {
          // Token'ı saklama işlemi burada yapılabilir
          // Örneğin: SharedPreferences ile
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Giriş başarılı!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B7FCE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Stack(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/snowflake.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 180),
                    const Text(
                      'Kullanıcı adı:',
                      style: TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.black),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            isDense: true,
                            isCollapsed: true,
                            constraints: BoxConstraints(
                              maxHeight: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Şifre:',
                      style: TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.black),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 20, right: 50),
                            isDense: true,
                            isCollapsed: true,
                            constraints: const BoxConstraints(
                              maxHeight: 40,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF262161),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Giriş yap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Şifreni mi unuttun? ',
                          style: TextStyle(
                            color: Color(0xFF3A3A3A),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ResetPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Şifreyi sıfırla',
                            style: TextStyle(
                              color: Color(0xFF262161),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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