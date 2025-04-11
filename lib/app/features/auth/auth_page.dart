import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _authAction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final AuthResponse response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw AuthException('Registration failed');
        }

        // Дополнительная проверка создания профиля
        await _verifyUserProfile(supabase, response.user!.id, email);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyUserProfile(SupabaseClient supabase, String userId, String email) async {
    try {
      // Проверяем наличие профиля (даем время триггеру сработать)
      await Future.delayed(const Duration(seconds: 1));

      final profile = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        // Если триггер не сработал, создаем вручную
        await supabase.from('users').upsert({
          'id': userId,
          'email': email,
          'nickname': 'user_${userId.substring(0, 8)}',
        });
      }
    } catch (e) {
      debugPrint('Profile verification error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SafeArea(child: SizedBox(
              height: 80,
                child: Center(
                    child: Text(_isLogin
                        ? 'Вход в аккаунт'
                        : 'Регистрация',
                    style: const TextStyle(
                      color: Color(0xFF872341),
                      fontSize: 24,
                    ),
                    )
                )
            )
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    cursorColor: Color(0xFF872341),
                    style: const TextStyle(color: Color(0xFF09122C)),
                    decoration: const InputDecoration(labelText: 'Почта',
                      labelStyle: TextStyle(color: Color(0xFF872341)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF872341)), // Граница когда поле не в фокусе
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF872341)), // Граница когда поле в фокусе
                      ),
                    ),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите почту, пожалуйста';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    cursorColor: Color(0xFF872341),
                    style: const TextStyle(color: Color(0xFF09122C)),
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Пароль',
                      labelStyle: TextStyle(color: Color(0xFF872341)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF872341)), // Граница когда поле не в фокусе
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF872341)), // Граница когда поле в фокусе
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль, пожалуйста';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен иметь не менее 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 360,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authAction,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isLogin ? 'Войти' : 'Зарегистрироваться', style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16
                      ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF872341),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Нет аккаунта? Зарегистрироваться'
                          : 'Уже есть аккаунт? Войти',
                      style: const TextStyle(
                          color: Color(0xFF872341),
                          fontSize: 12
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}