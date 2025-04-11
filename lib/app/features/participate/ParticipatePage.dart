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
  List<Map<String, dynamic>> participatingEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParticipatingEvents();
  }

  Future<void> _fetchParticipatingEvents() async {
    try {
      setState(() => isLoading = true);

      // Получаем ID текущего пользователя
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Запрашиваем мероприятия, в которых пользователь является участником
      final response = await supabase
          .from('approved_participant')
          .select('event_id')
          .eq('user_id', userId);

      if (response.isEmpty) {
        setState(() {
          participatingEvents = [];
          isLoading = false;
        });
        return;
      }

      // Получаем ID всех мероприятий, где пользователь участник
      final eventIds = response.map((e) => e['event_id'] as String).toList();

      // Запрашиваем полную информацию об этих мероприятиях
      final eventsResponse = await supabase
          .from('events')
          .select()
          .inFilter('id', eventIds);

      setState(() {
        participatingEvents = List<Map<String, dynamic>>.from(eventsResponse);
        isLoading = false;
        print(participatingEvents);
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки мероприятий: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : participatingEvents.isEmpty
                    ? const Center(child: Text('Вы не участвуете ни в одном мероприятии'))
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      itemCount: participatingEvents.length,
                      separatorBuilder: (_, __) =>  const SizedBox(height: 10),
                      itemBuilder: (context, index) => ParticipateEventUIWidget(
                        event: participatingEvents[index],
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
            onPressed: () {
              print('Menu pressed');
            },
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
      });
      // Можно добавить фильтрацию мероприятий по дате
      // _filterEventsByDate(picked);
    }
  }

  String _formattedDate(DateTime date) {
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