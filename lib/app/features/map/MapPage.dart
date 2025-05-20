import 'package:evently/app/features/about/AboutPage.dart';
import 'package:evently/app/features/home/widgets/EventUI.dart';
import 'package:evently/app/shared/models/models.dart';
import 'package:evently/app/shared/services/go_service_api.dart';
import 'package:flutter/material.dart';
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
  bool? switchValue = false;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  List<Event> _allEvents = [];
  bool isLoading = true;
  final ApiService _apiService = ApiService();

  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(55.751244, 37.618423);
  final List<Marker> _markers = [];


  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() => isLoading = true);
      final events = await _apiService.getEvents();

      setState(() {
        _allEvents = events;
        isLoading = false;
      });

      for (var event in events) {
        final address = event.location;
        if (address.toString().isNotEmpty) {
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


  Future<void> _addMarkerForEvent(String address, Event event) async {
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
              child: GestureDetector(onTap:(){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AboutEventPage(eventId: event.id),
                    ),
                  );
                },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(event.imageUrls[0]),
                      ),
                    ),
                  )
              )
            ),
          );
        });
      }
    } catch (e) {
      print('Ошибка при геокодинге "$address": $e');
    }
  }

  final double minSize = 0.15;
  final double maxSize = 0.7;
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
                          userAgentPackageName: 'com.example.evently',
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
                    return true;
                  },
                  child: DraggableScrollableSheet(
                    controller: _draggableController,
                    initialChildSize: 0.4, // Начальный размер (15% экрана)
                    minChildSize: 0.2, // Минимальный размер
                    maxChildSize:0.8, // Максимальный размер
                    snap: true,
                    snapSizes: [0.2, 0.4, 0.8],

                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Ручка с GestureDetector
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragStart: (_) {},
                              onVerticalDragUpdate: (details) {
                                final newSize = _draggableController.size +
                                    details.primaryDelta! / MediaQuery.of(context).size.height;
                                _draggableController.jumpTo(
                                  newSize.clamp(minSize, maxSize),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            // Список
                            Expanded(
                              child: isLoading
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                  : _allEvents.isEmpty
                                  ? const Center(
                                child: Text(
                                  'Нет событий',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                                  : ListView.builder(
                                controller: scrollController,
                                itemCount: _allEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _allEvents[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xE3FFDDD8),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: EventUIWidget(event: event),
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
            const Text(
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
              activeColor: const Color(0xFF872341),
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