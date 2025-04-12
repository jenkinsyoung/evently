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
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  bool _userPickedDate = false;
  String? _selectedCategory;
  List<String> _categories = [];

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
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('events')
          .select('''
            *,
            creator:users!event_creator_id_fkey(*),
            participants:users!approved_participant(*),
            category_id:category!inner(name)
          ''')
          .eq('creator_id', userId)
          .order('start_date', ascending: true);

      setState(() {
        _allEvents = response as List<Map<String, dynamic>>;
        _filteredEvents = List.from(_allEvents);
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке событий: $e')),
      );
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
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePage(),
                ),
              );
            },
            backgroundColor: const Color(0xFFE17564),
            elevation: 8,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
          body: SafeArea(
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
                        child: const SizedBox(width: 33, height: 33),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 54,
                  color: const Color(0xFFE17564),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sort_rounded, color: Colors.white),
                        onPressed: _showCategoryFilter,
                      ),
                      InkWell(
                        onTap: _pickDate,
                        child: Text(
                          _selectedDate == null
                              ? 'Выбрать дату'
                              : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_userPickedDate || _selectedCategory != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _resetFilters,
                        )
                      else
                        const SizedBox(width: 30),
                    ],
                  ),
                ),
                if (_userPickedDate || _selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (_userPickedDate)
                          Chip(
                            label: Text('${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'),
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
                      ? Center(
                    child: Text(
                      _userPickedDate || _selectedCategory != null
                          ? 'Нет мероприятий по выбранным фильтрам'
                          : 'У вас нет мероприятий',
                    ),
                  )
                      : ListView.builder(
                    itemCount: _filteredEvents.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: MyEventUIWidget(event: event),
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
}