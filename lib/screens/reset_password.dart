import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showCodeInput = false;
  bool _showNewPasswordInput = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _resetToken;
  bool _passwordsMatch = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adınızı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showCodeInput = false; // Reset state
    });

    try {
      
      final result = await ApiService.requestPasswordReset(_usernameController.text);

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
          _showCodeInput = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Onay kodu e-posta adresinize gönderildi'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        String errorMessage = result['message'] ?? 'Bilinmeyen bir hata oluştu';
        if (errorMessage.contains('bulunamadı')) {
          errorMessage = 'Bu kullanıcı adına sahip bir hesap bulunamadı';
        } else if (errorMessage.contains('yanıt alınamadı')) {
          errorMessage = 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
        }
        
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Hata oluştu: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir bağlantı hatası oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen onay kodunu girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.verifyResetCode(
        _usernameController.text,
        _codeController.text,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _resetToken = result['token'];
            _showNewPasswordInput = true;
          });
        } else {
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

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yeni şifrenizi girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordsMatch = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler eşleşmiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.resetPassword(
        _resetToken!,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        if (result['success']) {
          Navigator.pop(context);
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
      backgroundColor: _primaryColor,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Şifremi Unuttum',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _showNewPasswordInput
                          ? 'Yeni şifrenizi girin'
                          : _showCodeInput
                              ? 'E-posta adresinize gönderilen 6 haneli kodu girin'
                              : 'Şifrenizi sıfırlamak için kullanıcı adınızı girin.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!_showCodeInput && !_showNewPasswordInput) ...[
                      const Text(
                        'Kullanıcı adı:',
                        style: TextStyle(
                          color: Colors.white,
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
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                              isDense: true,
                            ),
                            style: TextStyle(color: _primaryColor),
                          ),
                        ),
                      ),
                    ],
                    if (_showCodeInput && !_showNewPasswordInput) ...[
                      const Text(
                        'Onay Kodu:',
                        style: TextStyle(
                          color: Colors.white,
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
                            controller: _codeController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                              hintText: '6 haneli kodu girin',
                              isDense: true,
                            ),
                            style: TextStyle(color: _primaryColor),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          ),
                        ),
                      ),
                    ],
                    if (_showNewPasswordInput) ...[
                      const Text(
                        'Yeni Şifre:',
                        style: TextStyle(
                          color: Colors.white,
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
                          controller: _newPasswordController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 20, right: 50),
                            hintText: 'Yeni şifrenizi girin',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isNewPasswordVisible = !_isNewPasswordVisible;
                                });
                              },
                            ),
                          ),
                          style: TextStyle(color: _primaryColor),
                          obscureText: !_isNewPasswordVisible,
                          textAlignVertical: TextAlignVertical.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Yeni Şifreyi Onayla:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: !_passwordsMatch ? Border.all(color: Colors.red, width: 1.5) : null,
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 20, right: 50),
                            hintText: 'Yeni şifrenizi tekrar girin',
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
                          style: TextStyle(color: _primaryColor),
                          obscureText: !_isConfirmPasswordVisible,
                          onChanged: (value) {
                            setState(() {
                              _passwordsMatch = value == _newPasswordController.text;
                            });
                          },
                          textAlignVertical: TextAlignVertical.center,
                        ),
                      ),
                      if (!_passwordsMatch)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Şifreler eşleşmiyor!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _showNewPasswordInput
                                ? _resetPassword
                                : _showCodeInput
                                    ? _verifyCode
                                    : _requestReset,
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
                            : Text(
                                _showNewPasswordInput
                                    ? 'Şifreyi Güncelle'
                                    : _showCodeInput
                                        ? 'Kodu Doğrula'
                                        : 'Şifreyi Sıfırla',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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