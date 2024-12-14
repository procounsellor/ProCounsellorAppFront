import 'package:flutter/material.dart';

class CallPage extends StatelessWidget {
  final List<String> liveCounsellors;
  final List<String> topRatedCounsellors;

  CallPage({required this.liveCounsellors, required this.topRatedCounsellors});

  @override
  Widget build(BuildContext context) {
    final combinedList = [...liveCounsellors, ...topRatedCounsellors];

    return Scaffold(
      appBar: AppBar(
        title: Text("Call Counsellors"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: combinedList.length,
        itemBuilder: (context, index) {
          final counsellorName = combinedList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(counsellorName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.call, size: 20), // Smaller icon size
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Calling $counsellorName...")),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.videocam, size: 20), // Smaller icon size
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Video calling $counsellorName...")),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
