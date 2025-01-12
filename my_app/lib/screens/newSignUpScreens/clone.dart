import 'package:flutter/material.dart';

class GetUserDetailsStep2Test extends StatefulWidget {
  @override
  _GetUserDetailsStep2TestState createState() =>
      _GetUserDetailsStep2TestState();
}

class _GetUserDetailsStep2TestState extends State<GetUserDetailsStep2Test> {
  final List<Map<String, String>> allowedStates = [
    {'name': 'KARNATAKA', 'image': 'assets/images/karnataka.jpg'},
    {'name': 'MAHARASHTRA', 'image': 'assets/images/maharashtra.png'},
    {'name': 'TAMILNADU', 'image': 'assets/images/tamilnadu.png'},
    {'name': 'OTHERS', 'image': 'assets/images/india.png'}
  ];

  // Simulated user data for testing
  final List<String> selectedStates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background set to white
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Text(
                  "Select Interested States",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Heading color set to black
                  ),
                ),
              ),
              SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                shrinkWrap:
                    true, // Prevent GridView from taking infinite height
                physics: NeverScrollableScrollPhysics(), // Grid doesn't scroll
                children: allowedStates.map((state) {
                  final isSelected = selectedStates.contains(state['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedStates.remove(state['name']);
                        } else {
                          selectedStates.add(state['name']!);
                        }
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              state['image']!,
                              fit: BoxFit
                                  .cover, // Ensures the image fills the card
                              width: MediaQuery.sizeOf(context).width / 2 -
                                  50, // Fills the horizontal space
                              height: MediaQuery.sizeOf(context).width / 2 - 61,
                            ),
                          ),
                        ),
                        SizedBox(height: 8), // Space between card and text
                        Text(
                          state['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green : Colors.black,
                          ),
                        ),
                        SizedBox(height: 20), // Extra spacing below each item
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Submit button color set to green
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Mock submission action
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Submitted States"),
                        content: Text(
                            "You have selected: ${selectedStates.join(', ')}"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
