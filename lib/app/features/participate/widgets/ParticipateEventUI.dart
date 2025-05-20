import 'package:evently/app/features/about/AboutPage.dart';
import 'package:evently/app/features/home/widgets/EventUI.dart';
import 'package:evently/app/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipateEventUIWidget extends StatelessWidget {
  final Map<String, dynamic> event;

  const ParticipateEventUIWidget({
    super.key,
    required this.event
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // Форматирование даты и времени
    final eventDate = DateTime.parse(event['start_date'] ?? DateTime.now().toString());
    final formattedDate = '${_weekdayName(eventDate.weekday)} ${eventDate.day.toString().padLeft(2, '0')}.${eventDate.month.toString().padLeft(2, '0')} ${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 320,
      height: 136,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AboutEventPage(eventId: event['id']),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: event['image_urls'].first != null
                      ? NetworkImage(event['image_urls'].first as String)
                      : const NetworkImage(
                    'https://lh6.googleusercontent.com/proxy/E_4xIlD15S0BvqPLy7KgJI9OYdRXU09tynxkqlnKkXIkFAJx59bYIxa1njKOx9O1oDeskDcAoH3GLA',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Название мероприятия',
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['location'] ?? 'Место проведения',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _cancelParticipation(context, supabase),
                        child: Text(
                          'Отменить участие',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[(weekday - 1) % 7];
  }

  Future<void> _cancelParticipation(BuildContext context, SupabaseClient supabase) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Удаляем запись о участии из таблицы approved_participant
      await supabase
          .from('approved_participant')
          .delete()
          .eq('event_id', event['id'])
          .eq('user_id', userId);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы отменили участие в мероприятии')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отмене участия: $e')),
      );
    }
  }
}