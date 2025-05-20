import 'package:dio/dio.dart';
import 'package:evently/app/shared/models/models.dart';

const url = '91.240.85.209:8080';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio() {
    // Configure default Dio options
    _dio.options.baseUrl = 'http://$url';
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }


  // СОБЫТИЯ

  // Получить все мероприятия
  Future<List<Event>> getEvents() async {
    try {
      final response = await _dio.get('/events/');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['events'] != null && data['events'] is List) {
          return (data['events'] as List)
              .map((event) => Event.fromJson(event))
              .toList();
        } else {
          return [];
        }
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Найти мероприятие по UUID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await _dio.get('/events/$eventId');
      if (response.statusCode == 200) {
        return Event.fromJson(response.data['event']);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Добавление мероприятия
  Future<Event> addEvent(Event event) async {
    try {
      final response = await _dio.post(
        '/events',
        data: event.toJson(),
      );
      if (response.statusCode == 201) {
        return Event.fromJson(response.data);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Обновление мероприятия
  Future<Event> updateEvent(Event event) async {
    try {
      final response = await _dio.put(
        '/events/${event.id}',
        data: event.toJson(),
      );
      if (response.statusCode == 200) {
        return Event.fromJson(response.data);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Удаление мероприятия по UUID
  Future<void> deleteEvent(String id) async {
    try {
      final response = await _dio.delete('/events/$id');
      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Зарегистрироваться на мероприятие

  Future<void> registerToEvent(String id) async {
    try {
      final response = await _dio.post('/events/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Получить всех участников мероприятия

  Future<void> getAllParticipants(String id) async {
    try {
      final response = await _dio.get('/events/$id/participants');

    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // USER

  Future<User> getUserById(String id) async{
    try {
      final response = await _dio.get('/users/$id');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }


  // КАТЕГОРИИ

  // Получить все категории
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories/');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((category) => Category.fromJson(category))
            .toList();
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Добавление категории
  Future<Category> addCategory(Category category) async{
    try {
      final response = await _dio.post(
          '/categories',
          data: category.toJson()
      );
      if (response.statusCode == 201) {
        return Category.fromJson(response.data);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }

  }

  // Получить категорию по ID
  Future<Category> getCategoryById(String categoryId) async {
    try {
      final response = await _dio.get('/categories/$categoryId');
      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Удалить категорию по UUID
  Future<void> deleteCategory(String id) async{
    try {
      final response = await _dio.delete('/categories/$id');
      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Обновление категории
  Future<Category> updateCategory(Category category) async{
    try {
      final response = await _dio.put(
        '/categories/${category.id}',
        data: category.toJson(),
      );
      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ОТЗЫВЫ
  Future<List<Review>> getAllReviews(String eventId) async{
    try {
      final response = await _dio.get(
        '/reviews/$eventId'
      );
      if (response.statusCode == 200) {
        if(response.data != null){
        return (response.data as List)
            .map((review) => Review.fromJson(review))
            .toList();
      } else {
          return [];
        }
      }
      throw _handleError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling
  Exception _handleError(Response response) {
    final statusCode = response.statusCode;
    final errorMessage = response.data['message'] ?? 'Unknown error occurred';
    return Exception('HTTP $statusCode: $errorMessage');
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      return _handleError(e.response!);
    }
    return Exception('Network error: ${e.message}');
  }

  // Add interceptors for logging or auth
  void addInterceptors(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

}