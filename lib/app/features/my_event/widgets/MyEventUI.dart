import 'package:evently/app/features/about/AboutPage.dart';
import 'package:evently/app/features/edit/EditPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyEventUIWidget extends StatelessWidget {
  final Map<String, dynamic> event;

  const MyEventUIWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final String title = event['title'] ?? 'Без названия';
    final String location = event['location'] ?? 'Место не указано';
    final String imageUrl = (event['image_urls'] != null && event['image_urls'].isNotEmpty)
        ? event['image_urls'][0]
        : 'https://via.placeholder.com/150';

    final DateTime? startDateTime =
    event['start_date'] != null ? DateTime.tryParse(event['start_date']) : null;

    final String formattedDate = startDateTime != null
        ? DateFormat('E dd.MM HH:mm').format(startDateTime)
        : 'Дата не указана';

    final int participantCount = event['partisipants']?.length ?? 0;;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF872341),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(5.0)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 105,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(imageUrl),
                  ),
                  borderRadius: BorderRadius.circular(10),
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
                      'Осталось ${event['participant_count'] - participantCount} мест',
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
}
