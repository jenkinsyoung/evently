import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profilePage';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Получаем ID текущего пользователя
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Загружаем данные пользователя из таблицы 'users'
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _userData = response;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $error')),
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

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
              (Route<dynamic> route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выходе: $error')),
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isLoading && _userData == null)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(child: Text('Ошибка: $_error')),
                )
              else
                Column(
                  children: [
                    _buildProfileSection(),
                    _buildContactsSection(),
                    _buildLogoutButton(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isLoading ? null : _signOut,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            'Выйти из аккаунта',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: 40,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //Container(width: 30, height: 40, color: Colors.grey[200]),
          Text(
            'Профиль',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          // badges.Badge(
          //   badgeContent: const Text(
          //     '1',
          //     style: TextStyle(color: Colors.white),
          //   ),
          //   showBadge: true,
          //   position: badges.BadgePosition.topEnd(),
          //   child: Container(
          //     width: 30,
          //     height: 30,
          //     color: const Color(0xFFBA4A19),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final nickname = _userData?['nickname'] ?? 'Никнейм';
    final age = _userData?['age'] ?? '20';
    final city = _userData?['city'] ?? 'Москва';

    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: 189,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 62,
            backgroundColor: Color(0xFF872341),
            // Добавьте загрузку аватарки, если она есть в вашей базе данных
            // backgroundImage: _userData?['avatar_url'] != null
            //   ? NetworkImage(_userData!['avatar_url'])
            //   : null,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$nickname',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.black87),
                      Text(
                        city,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: GestureDetector(
                    onTap: () {
                      // Реализация редактирования профиля
                    },
                    child: const Text(
                      'Редактировать',
                      style: TextStyle(fontSize: 16, color: Color(0xFF872341)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsSection() {
    final email = _userData?['email'] ?? _supabase.auth.currentUser?.email ?? 'example@example.com';
    // final phone = _userData?['phone'] ?? '+7 999 999-99-99';
    // final username = _userData?['username'] ?? '@loloneme';

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(color: const Color(0xE3FFB7AC)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Контакты',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              // _ContactRow(contact: username),
              // _ContactRow(contact: phone),
              _ContactRow(contact: email),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: const Color(0xFF4C3535))
        ),
        const SizedBox(width: 10),
        Text(
          contact,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}