import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

String getTarihSaat() {
  DateTime now = DateTime.now();
  String gun = now.day.toString().padLeft(2, '0');
  String ay = now.month.toString().padLeft(2, '0');
  String yil = now.year.toString();
  String saat = now.hour.toString().padLeft(2, '0');
  String dakika = now.minute.toString().padLeft(2, '0');
  return '$gun-$ay-$yil $saat:$dakika';
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _passwordsMatch = true;
  bool _isValidEmail = true;
  bool _isValidPassword = true; // Şifre uzunluğu kontrolü için yeni değişken
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_checkPasswords);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword); // Şifre değiştiğinde kontrol et
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _checkPasswords() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }

  void _validateEmail() {
    setState(() {
      final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
      _isValidEmail = emailRegex.hasMatch(_emailController.text) || _emailController.text.isEmpty;
    });
  }

  // Şifre uzunluğunu kontrol eden yeni metod
  void _validatePassword() {
    setState(() {
      _isValidPassword = _passwordController.text.length >= 8 || _passwordController.text.isEmpty;
      // Şifre değiştiğinde şifre eşleşmesini de kontrol et
      if (_confirmPasswordController.text.isNotEmpty) {
        _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
      }
    });
  }

  Future<void> _register() async {
    // Form doğrulama
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        !_passwordsMatch ||
        !_isValidEmail ||
        !_isValidPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doğru şekilde doldurun.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        katilmaTarihi: getTarihSaat(),
      );

      if (result['success']) {
        // Kayıt başarılı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          // Login ekranına yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // Kayıt başarısız
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
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF6B7FCE),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: -200,
              right: -200,
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/snowflake.png',
                  width: 800,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 140),
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
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'E-posta:',
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
                          border: !_isValidEmail && _emailController.text.isNotEmpty
                              ? Border.all(color: const Color(0xFFFF0000), width: 1.5)
                              : null,
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => _validateEmail(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                      if (!_isValidEmail && _emailController.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Geçersiz e-posta!',
                            style: TextStyle(
                              color: Color(0xFFFF0000),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
                          border: !_isValidPassword && _passwordController.text.isNotEmpty
                              ? Border.all(color: const Color(0xFFFF0000), width: 1.5)
                              : null,
                        ),
                        child: TextField(
                          obscureText: !_isPasswordVisible,
                          controller: _passwordController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 20, right: 50),
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
                      if (!_isValidPassword && _passwordController.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Şifre en az 8 karakter olmalıdır!',
                            style: TextStyle(
                              color: Color(0xFFFF0000),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Şifreyi onayla:',
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
                          border: !_passwordsMatch && _confirmPasswordController.text.isNotEmpty
                              ? Border.all(color: const Color(0xFFFF0000), width: 1.5)
                              : null,
                        ),
                        child: TextField(
                          obscureText: !_isConfirmPasswordVisible,
                          controller: _confirmPasswordController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 20, right: 50),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      if (!_passwordsMatch && _confirmPasswordController.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Şifreler uyuşmuyor!',
                            style: TextStyle(
                              color: Color(0xFFFF0000),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kayıt ol',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}