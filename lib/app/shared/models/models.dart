import 'dart:ffi';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String creatorId;
  final String location;
  final String categoryId;
  final int participantCount;
  final List<String> imageUrls;
  final DateTime? createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.creatorId,
    required this.location,
    required this.categoryId,
    required this.participantCount,
    required this.imageUrls,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id'] ?? json['id'] ?? '', // учитываем оба варианта
      title: json['event_title'] ?? json['event_title'] ?? '', // учитываем оба варианта
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      creatorId: json['creator']['user_id'] ?? '',
      location: json['location'] ?? '',
      categoryId: json['category']['category_id'] ?? '',
      participantCount: json['participants'] ?? json['participant_count'] ?? 0,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': id,
      'event_title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'creator':{
        'user_id': creatorId
      },
      'location': location,
      'category': {
        'category_id': categoryId
      },
      'participant_count': participantCount,
      'image_urls': imageUrls,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}



class Category{
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id'] ?? '',
      name: json['category_name'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': id,
      'category_name': name
    };
  }
}


class Review{
  final String id;
  final String description;
  final double score;
  final String userId;
  final String eventId;

  Review({
    required this.id,
    required this.description,
    required this.score,
    required this.userId,
    required this.eventId
  });

  factory Review.fromJson(Map<String, dynamic> json){
    return Review(
      id: json['review_id'] ?? '',
      description: json['description'] ?? '',
      score: json['score'] ?? 0.0,
      userId: json['user']['user_id'] ?? '',
      eventId: json['event']['event_id'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': id,
      'event': {
        'event_id': eventId,
      },
      'user': {
        'user_id': userId,
      },
      'description': description,
      'score': score
    };
  }

}


class User{
  final String userId;
  final String email;
  final String password;
  final String nickname;
  final String phone;

  User({
    required this.userId,
    required this.email,
    required this.password,
    required this.nickname,
    required this.phone
  });

  factory User.fromJson(Map<String, dynamic> json){
    return User(
        userId: json['user_id'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        nickname: json['nickname'] ?? '',
        phone: json['phone'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'password': password,
      'nickname': nickname,
      'phone': phone
    };
  }

}