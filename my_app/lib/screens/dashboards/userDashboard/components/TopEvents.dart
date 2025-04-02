// 📄 EventCarousel Widget
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/events.dart';
import 'EventDetailsPage.dart';

class EventCarousel extends StatefulWidget {
  const EventCarousel({Key? key}) : super(key: key);

  @override
  _EventCarouselState createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  List<Event> events = [];
  bool isLoading = true;
  final String cacheKey = "top_events_cache";

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/top_trending_events.json');
      List<dynamic> data = json.decode(jsonString);

      List<Event> fetchedEvents =
          data.map<Event>((item) => Event.fromJson(item)).toList();

      // Cache the JSON
      await prefs.setString(
        cacheKey,
        json.encode(fetchedEvents.map((e) => e.toJson()).toList()),
      );

      if (!mounted) return; // 🚨 Prevent setState on disposed widget

      setState(() {
        events = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading events: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : CarouselSlider(
            options: CarouselOptions(
              height: 200,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              enableInfiniteScroll: true,
            ),
            items: events.map((event) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage(event.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
  }
}
