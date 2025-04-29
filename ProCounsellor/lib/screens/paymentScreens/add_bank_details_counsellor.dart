import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'update_bank_details_counsellor.dart';
import 'package:google_fonts/google_fonts.dart';

class AddBankDetailsCounsellorPage extends StatefulWidget {
  final String username;

  AddBankDetailsCounsellorPage({required this.username});

  @override
  _AddBankDetailsCounsellorPageState createState() =>
      _AddBankDetailsCounsellorPageState();
}

class _AddBankDetailsCounsellorPageState
    extends State<AddBankDetailsCounsellorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  bool _isLoading = true;
  bool _hasBankDetails = false;
  Map<String, dynamic>? _bankDetails;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  Future<void> _fetchBankDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('counsellors')
          .doc(widget.username)
          .get();

      final data = doc.data();

      if (doc.exists &&
          data != null &&
          data.containsKey('bankDetails') &&
          data['bankDetails'] != null) {
        setState(() {
          _bankDetails = Map<String, dynamic>.from(data['bankDetails']);
          _hasBankDetails = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching bank details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitBankDetails() async {
    if (_formKey.currentState!.validate()) {
      final bankDetails = {
        'bankAccountNumber': _accountNumberController.text.trim(),
        'ifscCode': _ifscCodeController.text.trim(),
        'fullName': _fullNameController.text.trim(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('counsellors')
            .doc(widget.username)
            .update({'bankDetails': bankDetails});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bank details updated successfully!")),
        );

        setState(() {
          _bankDetails = bankDetails;
          _hasBankDetails = true;
        });
      } catch (e) {
        print("Error updating bank details: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update bank details")),
        );
      }
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     appBar: AppBar(title: Text("Bank Details")),
  //     body: _isLoading
  //         ? Center(child: CircularProgressIndicator())
  //         : _hasBankDetails && _bankDetails != null
  //             ? Padding(
  //                 padding: EdgeInsets.all(16.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       "Bank Account Number: ${_bankDetails?['bankAccountNumber'] ?? 'N/A'}",
  //                       style: TextStyle(fontSize: 16),
  //                     ),
  //                     SizedBox(height: 8),
  //                     Text(
  //                       "IFSC Code: ${_bankDetails?['ifscCode'] ?? 'N/A'}",
  //                       style: TextStyle(fontSize: 16),
  //                     ),
  //                     SizedBox(height: 8),
  //                     Text(
  //                       "Full Name: ${_bankDetails?['fullName'] ?? 'N/A'}",
  //                       style: TextStyle(fontSize: 16),
  //                     ),
  //                     SizedBox(height: 24),
  //                     ElevatedButton(
  //                       onPressed: () {
  //                         Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder: (context) => UpdateBankDetailsCounsellorPage(username: widget.username),
  //                           ),
  //                         );
  //                       },
  //                       child: Text("Update Bank Details"),
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.blue,
  //                         foregroundColor: Colors.white,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               )
  //             : Padding(
  //                 padding: EdgeInsets.all(16.0),
  //                 child: Form(
  //                   key: _formKey,
  //                   child: Column(
  //                     children: [
  //                       TextFormField(
  //                         controller: _accountNumberController,
  //                         decoration: InputDecoration(labelText: "Bank Account Number"),
  //                         keyboardType: TextInputType.number,
  //                         validator: (value) => value == null || value.isEmpty ? "Enter account number" : null,
  //                       ),
  //                       SizedBox(height: 16),
  //                       TextFormField(
  //                         controller: _ifscCodeController,
  //                         decoration: InputDecoration(labelText: "IFSC Code"),
  //                         validator: (value) => value == null || value.isEmpty ? "Enter IFSC code" : null,
  //                       ),
  //                       SizedBox(height: 16),
  //                       TextFormField(
  //                         controller: _fullNameController,
  //                         decoration: InputDecoration(labelText: "Full Name"),
  //                         validator: (value) => value == null || value.isEmpty ? "Enter full name" : null,
  //                       ),
  //                       SizedBox(height: 24),
  //                       ElevatedButton(
  //                         onPressed: _submitBankDetails,
  //                         child: Text("Submit"),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Bank Details",
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity, // 🔥 Full width
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: _hasBankDetails && _bankDetails != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow("Bank Account Number",
                                      _bankDetails?['bankAccountNumber']),
                                  _buildDetailRow(
                                      "IFSC Code", _bankDetails?['ifscCode']),
                                  _buildDetailRow(
                                      "Full Name", _bankDetails?['fullName']),
                                ],
                              )
                            : Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildInputField(
                                      controller: _accountNumberController,
                                      label: "Bank Account Number",
                                      icon: Icons.account_balance,
                                      keyboardType: TextInputType.number,
                                    ),
                                    SizedBox(height: 20),
                                    _buildInputField(
                                      controller: _ifscCodeController,
                                      label: "IFSC Code",
                                      icon: Icons.code,
                                    ),
                                    SizedBox(height: 20),
                                    _buildInputField(
                                      controller: _fullNameController,
                                      label: "Full Name",
                                      icon: Icons.person,
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _hasBankDetails
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UpdateBankDetailsCounsellorPage(
                                          username: widget.username),
                                ),
                              );
                            }
                          : _submitBankDetails,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _hasBankDetails
                                  ? "UPDATE BANK DETAILS"
                                  : "SUBMIT BANK DETAILS",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.7,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: Colors.grey[700]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.isEmpty ? "Enter $label" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      style: GoogleFonts.outfit(fontSize: 16),
    );
  }
}
