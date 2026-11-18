import 'package:flutter/material.dart';

import 'external_actions.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: InkWell(
      onTap: () => launchCourierLink(
        context,
        Uri.parse('https://www.openstreetmap.org/copyright'),
        'OpenStreetMap contributors',
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          '\u00A9 OpenStreetMap contributors',
          style: TextStyle(color: Color(0xFF18181B), fontSize: 11),
        ),
      ),
    ),
  );
}
