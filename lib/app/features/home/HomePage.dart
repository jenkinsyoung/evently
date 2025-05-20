import 'package:evently/app/features/home/widgets/EventUI.dart';
import 'package:evently/app/shared/models/models.dart';
import 'package:evently/app/shared/services/go_service_api.dart';
import 'package:flutter/material.dart';

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
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  bool _userPickedDate = false;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final [events, categories] = await Future.wait([
        _apiService.getEvents(),
        _apiService.getCategories(),
      ]);
      final now = DateTime.now();
      setState(() {
        _allEvents = events as List<Event>;
        _filteredEvents = events.where((event) {
          final startDate = event.startDate;
          final endDateString = event.endDate;

          final endDate = endDateString ?? DateTime(startDate.year, startDate.month, startDate.day, 23, 59);

          return endDate.isAfter(now);
        }).toList();
        _categories = categories as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Ошибка загрузки данных: $e');
    }
  }

  void _applyFilters() {
    List<Event> filtered = List.from(_allEvents);

    // Date filter
    if (_userPickedDate && _selectedDate != null) {
      final startOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      filtered = filtered.where((event) {
        return event.startDate.isAfter(startOfDay) &&
            event.startDate.isBefore(endOfDay);
      }).toList();
    }

    // Category filter
    if (_selectedCategoryId != null) {
      filtered = filtered.where((event) {
        return event.categoryId == _selectedCategoryId;
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
                  children: [
                    ListTile(
                      title: const Text('Все категории'),
                      trailing: _selectedCategoryId == null
                          ? const Icon(Icons.check, color: Color(0xFF872341))
                          : null,
                      onTap: () {
                        setState(() => _selectedCategoryId = null);
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    ),
                    ..._categories.map((category) {
                      return ListTile(
                        title: Text(category.name),
                        trailing: _selectedCategoryId == category.id
                            ? const Icon(Icons.check, color: Color(0xFF872341))
                            : null,
                        onTap: () {
                          setState(() => _selectedCategoryId = category.id);
                          _applyFilters();
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
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
      _selectedCategoryId = null;
      _filteredEvents = List.from(_allEvents.where((event) {
        final startDate = event.startDate;
        final endDateString = event.endDate;

        final endDate = endDateString ?? DateTime(startDate.year, startDate.month, startDate.day, 23, 59);

        return endDate.isAfter(DateTime.now());
      }).toList());
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String? _getSelectedCategoryName() {
    if (_selectedCategoryId == null) return null;
    return _categories.firstWhere(
          (cat) => cat.id == _selectedCategoryId,
      orElse: () => Category(id: '', name: ''),
    ).name;
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
                        if (_userPickedDate || _selectedCategoryId != null)
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
                if (_userPickedDate || _selectedCategoryId != null)
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
                        if (_selectedCategoryId != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Chip(
                              label: Text(_getSelectedCategoryName() ?? ''),
                              onDeleted: () {
                                setState(() => _selectedCategoryId = null);
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
                      : RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: ListView.builder(
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