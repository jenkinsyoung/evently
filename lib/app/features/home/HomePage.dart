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
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  bool _userPickedDate = false;
  String? _selectedCategory;
  List<String> _categories = [];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchCategories();
    _fetchEvents();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _supabase
          .from('category')
          .select('name')
          .order('name', ascending: true);

      setState(() {
        _categories = (response as List).map((e) => e['name'] as String).toList();
        _categories.insert(0, 'Все');
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() => _isLoading = true);
      final now = DateTime.now();

      final query = _supabase
          .from('events')
          .select('''
            *,
            creator:users!event_creator_id_fkey(*),
            participants:users!approved_participant(*),
            category_id:category!inner(name)
          ''')
          .order('start_date', ascending: true);

      final List<dynamic> response = await query;

      setState(() {
        _allEvents = response.cast<Map<String, dynamic>>();
        _filteredEvents = List.from(_allEvents);
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events: $e')),
      );
      print('Error details: $e');
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allEvents);

    // Фильтр по дате
    if (_userPickedDate && _selectedDate != null) {
      final startOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      filtered = filtered.where((event) {
        try {
          final eventDate = DateTime.parse(event['start_date'] as String);
          return eventDate.isAfter(startOfDay) && eventDate.isBefore(endOfDay);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Фильтр по категории
    if (_selectedCategory != null && _selectedCategory != 'Все') {
      filtered = filtered.where((event) {
        return event['category_id']?['name'] == _selectedCategory;
      }).toList();
    }

    setState(() {
      _filteredEvents = filtered;
    });
  }

  Future<void> _showCategoryFilter() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Фильтр по категориям',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF872341),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: _categories.map((category) {
                    return ListTile(
                      title: Text(category),
                      trailing: _selectedCategory == category ||
                          (category == 'Все' && _selectedCategory == null)
                          ? const Icon(Icons.check, color: Color(0xFF872341))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category == 'Все' ? null : category;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF872341),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF872341),
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
        _userPickedDate = true;
      });
      _applyFilters();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedDate = DateTime.now();
      _userPickedDate = false;
      _selectedCategory = null;
    });
    _applyFilters();
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sort_rounded, color: Color(0xFF872341)),
                          onPressed: _showCategoryFilter,
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
                        if (_userPickedDate || _selectedCategory != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF872341)),
                            onPressed: _resetFilters,
                          )
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                if (_userPickedDate || _selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (_userPickedDate)
                          Chip(
                            label: Text(_formattedDate(_selectedDate!)),
                            onDeleted: () {
                              setState(() => _userPickedDate = false);
                              _applyFilters();
                            },
                          ),
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Chip(
                              label: Text(_selectedCategory!),
                              onDeleted: () {
                                setState(() => _selectedCategory = null);
                                _applyFilters();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredEvents.isEmpty
                      ? const Center(child: Text('Нет мероприятий'))
                      : ListView.builder(
                    itemCount: _filteredEvents.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EventUIWidget(
                          event: _filteredEvents[index],
                        ),
                      );
                    },
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
    return '${_weekdayName(date.weekday)} ${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)}';
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
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