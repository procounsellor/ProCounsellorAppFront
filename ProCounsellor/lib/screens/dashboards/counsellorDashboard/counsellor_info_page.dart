import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CounsellorInfoPage extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const CounsellorInfoPage({Key? key, required this.profileData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely convert all fields to String
    final String organisation =
        profileData["organisationName"]?.toString() ?? "Not provided";
    final String experience =
        profileData["experience"]?.toString() ?? "Not provided";
    final String state =
        profileData["stateOfCounsellor"]?.toString() ?? "Not provided";
    final String expertise =
        profileData["expertise"]?.toString() ?? "Not provided";
    final String rate =
        profileData["ratePerYear"]?.toString() ?? "Not provided";

    String languagesKnown;
    try {
      final raw = profileData["languagesKnow"];
      if (raw is List) {
        languagesKnown = raw.map((e) => e.toString()).join(", ");
      } else if (raw is String) {
        languagesKnown = raw;
      } else {
        languagesKnown = "Not provided";
      }
    } catch (e) {
      languagesKnown = "Not provided";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "MY INFO",
          style: GoogleFonts.outfit(
            // 👈 or any font like Roboto, Lato, Poppins
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black, // since background is white
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  buildItem("ORGANISATION", organisation),
                  buildItem("EXPERIENCE", experience),
                  buildItem("STATE", state),
                  buildItem("EXPERTISE", expertise),
                  buildItem("RATE PER YEAR", rate),
                  buildItem("LANGUAGES KNOWN", languagesKnown),
                ],
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          left: 16,
                          right: 16,
                          top: 20,
                        ),
                        child: RequestEditModal(profileData: profileData),
                      );
                    },
                  );
                },
                icon: Icon(Icons.edit_note),
                label: Text("Request Edit"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[700],
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestEditModal extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const RequestEditModal({super.key, required this.profileData});

  @override
  State<RequestEditModal> createState() => _RequestEditModalState();
}

class _RequestEditModalState extends State<RequestEditModal> {
  late TextEditingController organisationController;
  late TextEditingController experienceController;
  late TextEditingController stateController;
  late TextEditingController expertiseController;
  late TextEditingController rateController;
  late TextEditingController languagesController;

  @override
  void initState() {
    super.initState();

    // Safe extraction
    final dynamic rawLanguages = widget.profileData['languagesKnow'];
    String languagesText = '';
    if (rawLanguages is List) {
      languagesText = rawLanguages.map((e) => e.toString()).join(', ');
    } else if (rawLanguages is String) {
      languagesText = rawLanguages;
    }

    organisationController = TextEditingController(
        text: widget.profileData['organisationName']?.toString() ?? '');
    experienceController = TextEditingController(
        text: widget.profileData['experience']?.toString() ?? '');
    stateController = TextEditingController(
        text: widget.profileData['stateOfCounsellor']?.toString() ?? '');
    expertiseController = TextEditingController(
        text: widget.profileData['expertise']?.toString() ?? '');
    rateController = TextEditingController(
        text: widget.profileData['ratePerYear']?.toString() ?? '');
    languagesController = TextEditingController(text: languagesText);
  }

  @override
  void dispose() {
    organisationController.dispose();
    experienceController.dispose();
    stateController.dispose();
    expertiseController.dispose();
    rateController.dispose();
    languagesController.dispose();
    super.dispose();
  }

  void _sendRequest() async {
    // TODO: Connect to your API
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit request submitted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text("Edit Info",
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 20),
          buildTextField("Organisation", organisationController),
          buildTextField("Experience", experienceController),
          buildTextField("State", stateController),
          buildTextField("Expertise", expertiseController),
          buildTextField("Rate Per Year", rateController),
          buildTextField("Languages Known", languagesController),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendRequest,
              child: Text("SEND REQUEST"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(letterSpacing: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
