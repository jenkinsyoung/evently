import 'package:evently/app/features/about/AboutPage.dart';
import 'package:evently/app/features/edit/EditPage.dart';
import 'package:evently/app/shared/models/models.dart';
import 'package:flutter/material.dart';

class MyEventUIWidget extends StatelessWidget {
  final Event event;

  const MyEventUIWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final String title = event.title;
    final String location = event.location;
    final String imageUrl = (event.imageUrls != null && event.imageUrls.isNotEmpty)
        ? event.imageUrls[0]
        : 'https://via.placeholder.com/150';

    final DateTime startDateTime = event.startDate;

    final String formattedDate;
    if (startDateTime != '') {
      formattedDate = '${_weekdayName(startDateTime.weekday)} ${startDateTime.day.toString().padLeft(2, '0')}.${startDateTime.month.toString().padLeft(2, '0')} ${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
    } else {
      formattedDate = 'Дата не указана';
    }

    final int participantCount = event.participantCount;

    return Container(

      decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF872341),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(5.0),
      ),
      //height: 170,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AboutEventPage(eventId: event.id),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 135,
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
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Color(0xFF872341)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPage(event: event),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Осталось ${event.participantCount - participantCount} мест',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
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
