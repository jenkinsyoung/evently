import 'package:evently/app/features/about/AboutPage.dart';
import 'package:evently/app/features/home/widgets/EventUI.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapEventPage extends StatefulWidget {
  const MapEventPage({super.key});

  static String routeName = 'MapEvent';
  static String routePath = '/mapEvent';

  @override
  State<MapEventPage> createState() => _MapEventPageState();
}

class _MapEventPageState extends State<MapEventPage> {
  bool? switchValue = true;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  MapController _mapController = MapController();
  LatLng _initialCenter = LatLng(55.751244, 37.618423); // Москва
  List<Marker> _markers = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() => isLoading = true);
      final query = supabase
          .from('events')
          .select('''
            *,
            creator:users!event_creator_id_fkey(*),
            participants:users!approved_participant(*),
            category_id:category!inner(name)
          ''')
          .order('start_date', ascending: true);

      final List<dynamic> response = await query;
      setState(() {
        events = response.cast<Map<String, dynamic>>();
        isLoading = false;
      });

      for (var event in events) {
        final address = event['location'];
        if (address != null && address.toString().isNotEmpty) {
          await _addMarkerForEvent(address, event);
        }
      }
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _addMarkerForEvent(String address, Map<String, dynamic> event) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _markers.add(
            Marker(
              width: 40,
              height: 40,
              point: latLng,
              child: IconButton(onPressed:(){

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutEventPage(event: event),
                ),
              );}, icon: Icon(Icons.location_pin, color: Colors.red, size: 40))
            ),
          );
        });
      }
    } catch (e) {
      print('Ошибка при геокодинге "$address": $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              // Основной контент (карта)
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _initialCenter,
                        zoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.evently', // Замени на своё
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),
                  ),
                ],
              ),

              // Выдвижная плашка с событиями
              Positioned.fill(
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    // Можно добавить логику при изменении размера плашки
                    return true;
                  },
                  child: DraggableScrollableSheet(
                    controller: _draggableController,
                    initialChildSize: 0.15, // Начальный размер (15% экрана)
                    minChildSize: 0.15, // Минимальный размер
                    maxChildSize: 0.7, // Максимальный размер
                    snap: true,
                    snapSizes: [0.15, 0.4, 0.7],
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFE17564),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Ручка для перетаскивания
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Заголовок
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'События рядом',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Список событий
                            Expanded(
                              child: isLoading
                                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                                  : events.isEmpty
                                  ? Center(
                                child: Text(
                                  'Нет событий',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                                  : ListView.builder(
                                controller: scrollController,
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Color(0xE3FFDDD8),
                                          borderRadius: BorderRadius.circular(5)
                                      ),

                                      child: EventUIWidget(
                                        event: event,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: 46,
      decoration: BoxDecoration(
        color: Color(0xFFE17564),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Искать рядом со мной',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch.adaptive(
              value: switchValue!,
              onChanged: (newValue) {
                setState(() {
                  switchValue = newValue;
                });
              },
              activeColor: Color(0xFF872341),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              inactiveThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}