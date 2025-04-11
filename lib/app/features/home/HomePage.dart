import 'package:evently/app/features/home/widgets/EventUI.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _selectedDate;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  bool _userPickedDate = false;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() => _isLoading = true);

      final now = DateTime.now();
      final startDate = _userPickedDate
          ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
          : DateTime(now.year, now.month, now.day); // <- это 00:00:00

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
          .or('start_date.lte.${endDate.toIso8601String()},end_date.gte.${startDate.toIso8601String()}')
          .order('start_date', ascending: true);

      setState(() {
        _events = response as List<Map<String, dynamic>>;
        _isLoading = false;
        print(_events);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events: $e')),
      );
    }
  }



  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF872341), // Цвет заголовка и кнопок
              onPrimary: Colors.white, // Цвет текста в заголовке
              surface: Colors.white70, // Фон календаря
              onSurface: Colors.black, // Цвет текста дней
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF872341), // Цвет текста кнопок "ОК" и "ОТМЕНА"
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _userPickedDate = true; // пользователь сам выбрал дату
      });
      await _fetchEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.white70,
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sort_rounded, color: Color(0xFF872341),),
                          onPressed: () {
                            print('Menu pressed');
                          },
                        ),
                        InkWell(
                          onTap: _pickDate,
                          child: Text(
                            _formattedDate(_selectedDate ?? DateTime.now()),
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Color(0xFF872341),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (_events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No events for this date'),
                        )
                      else
                        ..._events.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EventUIWidget(
                            event: event,
                          ),
                        )).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  String _formattedDate(DateTime date) {
    // Можно заменить на intl package или другой форматтер
    return '${_weekdayName(date.weekday)} ${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)}';
  }

  String _weekdayName(int weekday) {
    const weekdays = [
      'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'
    ];
    return weekdays[(weekday - 1) % 7];
  }

  String _monthName(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[month - 1];
  }
}