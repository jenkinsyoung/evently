import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF8AACCD),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              _buildHeader(),
              _buildMapContainer(),
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
        color: Color(0xFF8AACCD),
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
                color: Color(0xFF301C0A),
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
              activeColor: Color(0xFFD70D0D),
              activeTrackColor: Color(0xFF391E06),
              inactiveTrackColor: Colors.grey[300],
              inactiveThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    return Expanded(
      child: Stack(
        children: [
          Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
          Align(
            alignment: AlignmentDirectional(0, 1),
            child: Container(
              width: 414.4,
              height: 89.89,
              decoration: BoxDecoration(
                color: Color(0xFF8AACCD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
