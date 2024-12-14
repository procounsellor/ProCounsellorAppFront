import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final List<String> liveCounsellors;
  final List<String> topRatedCounsellors;

  ChatPage({required this.liveCounsellors, required this.topRatedCounsellors});

  @override
  Widget build(BuildContext context) {
    final combinedList = [...liveCounsellors, ...topRatedCounsellors];

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with Counsellors"),
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
              trailing: IconButton(
                icon: Icon(Icons.chat),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Chatting with $counsellorName...")),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
