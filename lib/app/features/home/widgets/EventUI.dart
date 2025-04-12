import 'package:evently/app/features/about/AboutPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventUIWidget extends StatelessWidget {
  const EventUIWidget({super.key, required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    // Parse dates and times
    final startDate = DateTime.parse(event['start_date']);
    final formattedDate = '${_weekdayName(startDate.weekday)} ${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')} ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
    final location = event['location'] ?? 'Место не указано';
    final creator = event['creator_id'] as String?;
    final category = event['category_id'] as Map<String, dynamic>?;

    // Get first image if available
    final imageUrl = (event['image_urls'] != null &&
        (event['image_urls'] as List).isNotEmpty)
        ? (event['image_urls'] as List).first
        : 'https://lh6.googleusercontent.com/proxy/E_4xIlD15S0BvqPLy7KgJI9OYdRXU09tynxkqlnKkXIkFAJx59bYIxa1njKOx9O1oDeskDcAoH3GLA';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF872341),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(5.0)
      ),

      height: 136,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AboutEventPage(event: event),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 140,
                // height: 105,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(imageUrl),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event['title'] ?? 'Название мероприятия',
                      maxLines: 3,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF872341),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: Color(0xFF09122C),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      location,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: Color(0xFF5C5B5B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[(weekday - 1) % 7];
  }
}