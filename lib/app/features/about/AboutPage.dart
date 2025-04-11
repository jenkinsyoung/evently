import 'package:evently/app/features/about/widgets/CommentUI.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AboutEventPage extends StatefulWidget {
  const AboutEventPage({super.key, required this.event});
  final Map<String, dynamic> event;


  static const String routeName = '/aboutEvent';

  @override
  State<AboutEventPage> createState() => _AboutEventPageState();
}

class _AboutEventPageState extends State<AboutEventPage> {

  final TextEditingController _textController = TextEditingController();
  double _rating = 3.0;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool isParticipating = false;


  final _focusNode = FocusNode();
  final List<Map<String, dynamic>> comments = [
    {'rating': 5.0, 'comment': 'Отличное событие!'},
    {'rating': 4.5, 'comment': 'Было весело :)'},
    {'rating': 4.0, 'comment': 'Хочу ещё!'},
    // И можно добавлять дальше
  ];

  Future<void> _submitReview() async {
    FocusScope.of(context).unfocus();
    final description = _textController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите отзыв')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('reviews').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'event_id': widget.event['id'],
        'description': description,
        'score': _rating.round(),
      });

      _textController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Отзыв успешно отправлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке отзыва: $e')),
      );
    }
  }

  Map<String, dynamic>? creatorDetails;
  bool isLoadingCreator = false;
  @override
  void initState() {
    super.initState();
    _fetchCreatorDetails();
    _checkParticipationStatus();
  }

  Future<void> _fetchCreatorDetails() async {
    if (widget.event['creator_id'] == null) return;

    setState(() {
      isLoadingCreator = true;
    });

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', widget.event['creator_id'])
          .maybeSingle();

      setState(() {
        creatorDetails = response;
        print(creatorDetails);
      });
    } catch (e) {
      print('Error fetching creator details: $e');
    } finally {
      setState(() {
        isLoadingCreator = false;
      });
    }
  }
  bool isLoading = false;
  Future<void> _checkParticipationStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => isLoading = true);

    final response = await _supabase
        .from('approved_participant')
        .select()
        .eq('event_id', widget.event['id'])
        .eq('user_id', userId);

    setState(() {
      isParticipating = response.isNotEmpty;
      isLoading = false;
    });
  }

  Future<void> _toggleParticipation() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      // Можно перенаправить на страницу авторизации
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо авторизоваться')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isParticipating) {
        // Удаляем участие
        await _supabase
            .from('approved_participant')
            .delete()
            .eq('event_id', widget.event['id'])
            .eq('user_id', userId);


      } else {
        // Добавляем участие
        await _supabase.from('approved_participant').insert({
          'event_id': widget.event['id'],
          'user_id': userId
        });

      }

      setState(() {
        isParticipating = !isParticipating;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isParticipating ? 'Вы участвуете!' : 'Участие отменено')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.parse(widget.event['start_date']);
    final formattedDate = DateFormat('E dd.MM HH:mm').format(startDate);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['title'] ?? 'Событие'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Image.network(
                    widget.event['image_urls']?.isNotEmpty == true
                        ? widget.event['image_urls'][0]
                        : 'https://via.placeholder.com/300x200.png?text=Нет+изображения',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                //InfoRow(label: widget.event['category_id']?['name'] ?? 'Категория не указана'),
                InfoRow(label: formattedDate),
                const SizedBox(height: 16),
                Text(
                  widget.event['description'] ?? 'Описание отсутствует',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(radius: 32, backgroundColor: Colors.grey),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(creatorDetails?['nickname'] ?? widget.event['creator']?['nickname'] ?? 'Неизвестный пользователь', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text("Инфоцыганка", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(label: creatorDetails?['email'] ?? widget.event['creator']?['email'] ?? 'Email не указан',),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const CircleAvatar(radius: 18, backgroundColor: Colors.brown),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBar.builder(
                          initialRating: 3,
                          minRating: 1,
                          direction: Axis.horizontal,
                          itemCount: 5,
                          itemSize: 20,
                          allowHalfRating: true,
                          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                        ),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Напишите отзыв...',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                            onSubmitted: (value) => _submitReview(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Отзывы", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.builder(
                  itemCount: comments.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentUIWidget(
                      rating: comment['rating'],
                      comment: comment['comment'],
                    );
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          // Кнопка "Я иду!" всегда внизу экрана
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: isLoading ? null : _toggleParticipation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE17564),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isParticipating ? "Отменить участие" : "Я иду!",
                  style: const TextStyle(color: Colors.white),
                ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  const InfoRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

