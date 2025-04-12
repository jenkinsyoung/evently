import 'package:evently/app/features/participate/widgets/ParticipateEventUI.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipateEventPage extends StatefulWidget {
  const ParticipateEventPage({super.key});

  static String routeName = 'ParticipateEventPage';
  static String routePath = '/participateEventPage';

  @override
  State<ParticipateEventPage> createState() => _ParticipateEventPageState();
}

class _ParticipateEventPageState extends State<ParticipateEventPage> {
  DateTime selectedDate = DateTime.now();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allParticipatingEvents = []; // Все мероприятия
  List<Map<String, dynamic>> _filteredEvents = []; // Отфильтрованные мероприятия
  bool isLoading = true;
  bool isFilteredByDate = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipatingEvents();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await supabase
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

  Future<void> _fetchParticipatingEvents() async {
    try {
      setState(() => isLoading = true);

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Получаем ID мероприятий, в которых участвует пользователь
      final participationResponse = await supabase
          .from('approved_participant')
          .select('event_id')
          .eq('user_id', userId);

      if (participationResponse.isEmpty) {
        setState(() {
          _allParticipatingEvents = [];
          _filteredEvents = [];
          isLoading = false;
        });
        return;
      }

      final eventIds = participationResponse.map((e) => e['event_id'] as String).toList();

      // Получаем полную информацию о мероприятиях
      final eventsResponse = await supabase
          .from('events')
          .select('''
            *,
            category_id:category!inner(name)
          ''')
          .inFilter('id', eventIds);

      setState(() {
        _allParticipatingEvents = List<Map<String, dynamic>>.from(eventsResponse);
        _filteredEvents = List.from(_allParticipatingEvents);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки мероприятий: $e')),
      );
    }
  }

  void _filterEvents() {
    List<Map<String, dynamic>> filtered = List.from(_allParticipatingEvents);

    // Фильтр по категории
    if (_selectedCategory != null && _selectedCategory != 'Все') {
      filtered = filtered.where((event) {
        return event['category_id']?['name'] == _selectedCategory;
      }).toList();
    }

    // Фильтр по дате
    if (isFilteredByDate) {
      final selectedDateFormatted = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      filtered = filtered.where((event) {
        try {
          final eventDateStr = event['start_date'] as String?;
          if (eventDateStr == null) return false;

          final eventDate = DateTime.parse(eventDateStr);
          final eventDateFormatted = DateTime(eventDate.year, eventDate.month, eventDate.day);

          return eventDateFormatted == selectedDateFormatted;
        } catch (e) {
          print('Ошибка при фильтрации события: $e');
          return false;
        }
      }).toList();
    }

    setState(() {
      _filteredEvents = filtered;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isFilteredByDate = true;
      });
      _filterEvents();
    }
  }

  void _resetFilters() {
    setState(() {
      isFilteredByDate = false;
      _selectedCategory = null;
      selectedDate = DateTime.now();
    });
    _filterEvents();
  }

  Future<void> _showCategoryFilter() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(16),
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
                    shrinkWrap: true,
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
                          _filterEvents();
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (isFilteredByDate || _selectedCategory != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    if (isFilteredByDate || _selectedCategory != null)
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text(
                          'Сбросить фильтры',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    if (_selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: Text(_selectedCategory!),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _filterEvents();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEvents.isEmpty
                    ? Center(
                  child: Text(
                    isFilteredByDate || _selectedCategory != null
                        ? 'Нет мероприятий по выбранным фильтрам'
                        : 'Вы не участвуете ни в одном мероприятии',
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  itemCount: _filteredEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => ParticipateEventUIWidget(
                    event: _filteredEvents[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showCategoryFilter,
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Text(
              _formattedDate(selectedDate),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
              ),
            ),
          ),
          const Icon(
            Icons.location_on,
            color: Colors.black,
            size: 24,
          ),
        ],
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