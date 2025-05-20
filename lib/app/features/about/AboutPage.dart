import 'package:evently/app/features/about/widgets/CommentUI.dart';
import 'package:evently/app/shared/models/models.dart';
import 'package:evently/app/shared/services/go_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class AboutEventPage extends StatefulWidget {
  const AboutEventPage({super.key, required this.eventId});
  final String eventId;

  static const String routeName = '/aboutEvent';

  @override
  State<AboutEventPage> createState() => _AboutEventPageState();
}

class _AboutEventPageState extends State<AboutEventPage> {

  final TextEditingController _textController = TextEditingController();
  double _rating = 3.0;
  bool isParticipating = false;
  Event? _event;
  Category? _category;
  bool _isLoading = true;
  User? _user;
  List<Review> _reviews = [];
  final ApiService _apiService = ApiService();
  final _focusNode = FocusNode();
  final List<Map<String, dynamic>> comments = [
    {'rating': 5.0, 'comment': 'Отличное событие!'},
    {'rating': 4.5, 'comment': 'Было весело :)'},
    {'rating': 4.0, 'comment': 'Хочу ещё!'},
    // И можно добавлять дальше
  ];
  Future<void> _loadInitialData() async {
    try {
      final event = await _apiService.getEventById(widget.eventId);
      final category = await _apiService.getCategoryById(event.categoryId);
      final user = await _apiService.getUserById(event.creatorId);
      final reviews = await _apiService.getAllReviews(widget.eventId);
      print('Данные получены:'); // Логирование
      print(event.toJson());
      print(category.toJson());
      print(user.toJson());
      print(reviews);

      setState(() {
        _event = event;
        _category = category;
        _user = user;
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке данных: $e'); // Логирование ошибки
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке данных: $e')),
      );
    }
  }

  // Future<void> _submitReview() async {
  //   FocusScope.of(context).unfocus();
  //   final description = _textController.text.trim();
  //
  //   if (description.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Пожалуйста, введите отзыв')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     await
  //
  //     _textController.clear();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Отзыв успешно отправлен!')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Ошибка при отправке отзыва: $e')),
  //     );
  //   }
  // }


  bool isLoadingCreator = false;
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    //_checkParticipationStatus();
  }


  bool isLoading = false;
  // Future<void> _checkParticipationStatus() async {
  //   final userId = _supabase.auth.currentUser?.id;
  //   if (userId == null) return;
  //
  //   setState(() => isLoading = true);
  //
  //   final response = await _supabase
  //       .from('approved_participant')
  //       .select()
  //       .eq('event_id', widget.event.id)
  //       .eq('user_id', userId);
  //
  //   setState(() {
  //     isParticipating = response.isNotEmpty;
  //     isLoading = false;
  //   });
  // }
  //
  // Future<void> _toggleParticipation() async {
  //   final userId = _supabase.auth.currentUser?.id;
  //   if (userId == null) {
  //     // Можно перенаправить на страницу авторизации
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Необходимо авторизоваться')),
  //     );
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     if (isParticipating) {
  //       // Удаляем участие
  //       await _supabase
  //           .from('approved_participant')
  //           .delete()
  //           .eq('event_id', widget.event.id)
  //           .eq('user_id', userId);
  //
  //
  //     } else {
  //       // Добавляем участие
  //       await _supabase.from('approved_participant').insert({
  //         'event_id': widget.event.id,
  //         'user_id': userId
  //       });
  //
  //     }
  //
  //     setState(() {
  //       isParticipating = !isParticipating;
  //       isLoading = false;
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(isParticipating ? 'Вы участвуете!' : 'Участие отменено')),
  //     );
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Ошибка: ${e.toString()}')),
  //     );
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final startDate = _event?.startDate;
    final formattedDate =
    startDate != null ? DateFormat('E dd.MM HH:mm').format(startDate) : 'Дата не указана';

    return Scaffold(
      appBar: AppBar(
        title: Text(_event?.title ?? 'Событие'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_event != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Image.network(
                      _event!.imageUrls.isNotEmpty
                          ? _event!.imageUrls[0]
                          : 'https://via.placeholder.com/300x200.png?text=Нет+изображения',
                      height: 380,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                InfoRow(label: _event?.location ?? 'Место не указано'),
                InfoRow(label: _category?.name ?? 'Категория не указана'),
                InfoRow(label: formattedDate),
                const SizedBox(height: 16),
                Text(
                  _event?.description ?? 'Описание отсутствует',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const CircleAvatar(radius: 32, backgroundColor: Colors.grey),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.nickname ?? 'Неизвестный пользователь',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_user?.email != null)
                  InfoRow(label: _user!.email),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const CircleAvatar(radius: 18, backgroundColor: Colors.brown),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          itemCount: 5,
                          itemSize: 20,
                          allowHalfRating: true,
                          itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
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
                            decoration: const InputDecoration(
                              hintText: 'Напишите отзыв...',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
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
                  itemCount: _reviews.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return CommentUIWidget(
                      rating: review.score,
                      comment: review.description,
                    );
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE17564),
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

