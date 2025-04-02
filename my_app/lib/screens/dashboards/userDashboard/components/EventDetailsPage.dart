import 'package:flutter/material.dart';
import '../model/events.dart';

class EventDetailsPage extends StatelessWidget {
  final Event event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              event.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 100));
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("${event.date} • ${event.time} • ${event.venue}"),
                  const SizedBox(height: 10),
                  Text("Organized by: ${event.organizer}",
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                  const Divider(height: 30),
                  Text(event.article,
                      style: const TextStyle(fontSize: 16, height: 1.5))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
