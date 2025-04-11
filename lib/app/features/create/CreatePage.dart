import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  static String routeName = 'CreatePage';
  static String routePath = '/createPage';

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateEndController = TextEditingController();
  final TextEditingController _timeEndController = TextEditingController();


  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  String? _selectedCategory;
  int _participantCount = 0;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  DateTime? _combinedDateTime;
  DateTime? _combinedEndDateTime;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Запрос разрешений
  Future<bool> _requestPermissions() async {
    // Для Android 13+ используем Permission.photos вместо storage
    final galleryStatus = await Permission.photos.request();
    final cameraStatus = await Permission.camera.request();

    if (galleryStatus.isPermanentlyDenied || cameraStatus.isPermanentlyDenied) {
      // Если пользователь навсегда запретил доступ
      await openAppSettings();
      return false;
    }

    return galleryStatus.isGranted && cameraStatus.isGranted;
  }
  Future<void> _pickImages() async {
    try {
      // Запрашиваем разрешения
      final hasPermission = await _requestPermissions();

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Необходимы разрешения для доступа'))
        );
        return;
      }

      // Теперь можно использовать image_picker
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      // Проверяем доступ к хранилищу
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        throw 'Доступ к галерее не предоставлен';
      }

      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty) {
        if (_selectedImages.length + images.length > 3) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Можно выбрать не более 3 фотографий'))
          );
          return;
        }

        setState(() {
          _selectedImages.addAll(images.map((file) => File(file.path)));
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка платформы: ${e.message}'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}'))
      );
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2050),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);

        // Объединяем дату и время, если время уже выбрано
        if (_selectedTime != null) {
          _combinedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);

        // Объединяем время с датой, если дата уже выбрана
        if (_selectedDate != null) {
          _combinedDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

// Аналогично для конечной даты и времени
  Future<void> _selectEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2050),
    );

    if (pickedDate != null && pickedDate != _selectedEndDate) {
      setState(() {
        _selectedEndDate = pickedDate;
        _dateEndController.text = DateFormat('dd.MM.yyyy').format(pickedDate);

        if (_selectedEndTime != null) {
          _combinedEndDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedEndTime!.hour,
            _selectedEndTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
        _timeEndController.text = picked.format(context);

        if (_selectedEndDate != null) {
          _combinedEndDateTime = DateTime(
            _selectedEndDate!.year,
            _selectedEndDate!.month,
            _selectedEndDate!.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }



  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (final imageFile in _selectedImages) {
      try {
        // Генерируем уникальное имя файла
        final fileExt = path.extension(imageFile.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
        final mimeType = lookupMimeType(imageFile.path);

        // Загружаем файл в Supabase Storage
        final fileBytes = await imageFile.readAsBytes();

        final uploadResponse = await _supabase.storage
            .from('eventimages')
            .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

        // Получаем публичный URL
        final imageUrl = _supabase.storage
            .from('eventimages')
            .getPublicUrl(fileName);

        imageUrls.add(imageUrl);
      } catch (e) {
        print('Ошибка загрузки изображения: $e');
      }
    }
    return imageUrls;
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Добавьте хотя бы одно фото'))
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Укажите дату мероприятия'))
      );
      return;
    }

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // 1. Загружаем изображения
      final imageUrls = await _uploadImages();
      print('Изображения загружены: $imageUrls');

      // 2. Получаем ID категории
      String? categoryId;
      if (_selectedCategory != null) {
        final response = await _supabase
            .from('category')
            .select('id')
            .eq('name', _selectedCategory!)
            .maybeSingle();

        categoryId = response?['id'] as String?;
        print('ID категории: $categoryId');
      }

      // 3. Создаем событие
      final eventData = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'start_date': _combinedDateTime!.toIso8601String(),
        'end_date': _combinedEndDateTime?.toIso8601String(),
        'participant_count': _participantCount,
        'category_id': categoryId,
        'image_urls': imageUrls,
        'created_at': DateTime.now().toIso8601String(),
        'creator_id': _supabase.auth.currentUser?.id,
      };

      print('Данные события: $eventData');

      final response = await _supabase
          .from('events')
          .insert(eventData)
          .select()
          .single();

      print('Событие создано: $response');

      // Успех - закрываем диалог и возвращаемся
      Navigator.of(context).pop(); // Закрываем индикатор
      Navigator.of(context).pop(); // Закрываем страницу

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Мероприятие создано!'))
      );

    } catch (e) {
      Navigator.of(context).pop(); // Закрываем индикатор если открыт
      print('Ошибка создания: $e');

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}'))
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _dateEndController.dispose();
    _timeEndController.dispose();
    _titleFocusNode.dispose();
    _locationFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 30, height: 30),
                        Text(
                          'Создание',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 16),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),

                // Image Picker Section
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.add_photo_alternate, size: 50),
                              onPressed: _pickImages,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: _pickImages,
                        child: Text(
                          _selectedImages.isEmpty
                              ? 'Добавить фото (до 3 шт)'
                              : 'Добавить ещё фото (${3 - _selectedImages.length} осталось)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Section
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Field
                          Padding(
                            padding: const EdgeInsets.only(bottom: 13),
                            child: TextFormField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Название события*',
                                hintStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              style: TextStyle(fontSize: 22),
                            ),
                          ),

                          // Date & Time Selection
                          Text(
                            'Когда начнется событие? *',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Выберите дату',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.calendar_today),
                                      onPressed: () => _selectDate(context),
                                    ),
                                  ),
                                  onTap: () => _selectDate(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _timeController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Выберите время',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.access_time),
                                      onPressed: () => _selectTime(context),
                                    ),
                                  ),
                                  onTap: () => _selectTime(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Когда закончится событие? *',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dateEndController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Выберите дату',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.calendar_today),
                                      onPressed: () => _selectEndDate(context),
                                    ),
                                  ),
                                  onTap: () => _selectEndDate(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _timeEndController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Выберите время',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.access_time),
                                      onPressed: () => _selectEndTime(context),
                                    ),
                                  ),
                                  onTap: () => _selectEndTime(context),
                                ),
                              ),
                            ],
                          ),
                          // Location Field
                          Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 13),
                            child: Text(
                              'Где будет проходить событие? *',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          TextFormField(
                            controller: _locationController,
                            focusNode: _locationFocusNode,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFA3A2A2), width: 1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          // Category Dropdown
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              'С чем связано событие? *',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              hint: Text('Категория события...'),
                              value: _selectedCategory,
                              items: [
                                'Концерт',
                                'Искусство и культура',
                                'Экскурсии и путешествия',
                                'Вечеринки',
                                'Для детей',
                                'Хобби и творчество',
                                'Другие развлечения'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),

                          // Participant Counter
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Количество участников',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Container(
                                  width: 120,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_rounded, size: 16),
                                        onPressed: () {
                                          setState(() {
                                            if (_participantCount > 0) {
                                              _participantCount--;
                                            }
                                          });
                                        },
                                      ),
                                      Text('$_participantCount'),
                                      IconButton(
                                        icon: Icon(Icons.add_rounded, size: 16),
                                        onPressed: () {
                                          setState(() {
                                            _participantCount++;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Description Field
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: TextFormField(
                              controller: _descriptionController,
                              focusNode: _descriptionFocusNode,
                              maxLines: 5,
                              minLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Опишите Ваше мероприятие...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          // Submit Button
                          Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 20),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _createEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  minimumSize: Size(150, 40),
                                ),
                                child: Text('Создать', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}