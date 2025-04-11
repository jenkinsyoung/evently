import 'package:evently/app/features/create/CreatePage.dart';
import 'package:evently/app/features/my_event/widgets/MyEventUI.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:supabase_flutter/supabase_flutter.dart';


class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  static String routeName = 'MyEventsPage';
  static String routePath = '/myEventsPage';

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  DateTime? _selectedDate;
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  bool _userPickedDate = false;

  Future<void> _fetchEvents() async {
    try {
      setState(() => _isLoading = true);

      final now = DateTime.now();
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final startDate = _userPickedDate
          ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
          : DateTime(now.year, now.month, now.day);

      final endDate = _userPickedDate
          ? startDate.add(const Duration(days: 1))
          : startDate.add(const Duration(days: 30));

      final response = await _supabase
          .from('events')
          .select('''
            *,
            creator:users!event_creator_id_fkey(*),
            participants:users!approved_participant(*),
            category_id:category!inner(name)
          ''')
          .eq('creator_id', userId)
          .or('start_date.lte.${endDate.toIso8601String()},end_date.gte.${startDate.toIso8601String()}')
          .order('start_date', ascending: true);

      setState(() {
        _events = response as List<Map<String, dynamic>>;
        _isLoading = false;
        print(_events);
        print(userId);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке событий: $e')),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          // backgroundColor: Colors.white,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePage(),
                ),
              );
            },
            backgroundColor: Color(0xFFE17564),
            elevation: 8,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 33, height: 33),
                        const Text(
                          'Мои мероприятия',
                          style: TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
                        ),
                        badges.Badge(
                          badgeContent: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          //badgeColor: const Color(0xFF0B057F),
                          child: const SizedBox(width: 33, height: 33),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 54,
                    color: Color(0xFFE17564),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sort_rounded, color: Colors.white,),
                          onPressed: () {
                            print('Menu pressed');
                          },
                        ),
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2050),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text(
                            _selectedDate == null
                                ? 'Выбрать дату'
                                : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                            style: const TextStyle(fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 14),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    itemCount: _events.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: MyEventUIWidget(event: event),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
