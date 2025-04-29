import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateBankDetailsCounsellorPage extends StatefulWidget {
  final String username;

  UpdateBankDetailsCounsellorPage({required this.username});

  @override
  _UpdateBankDetailsCounsellorPageState createState() =>
      _UpdateBankDetailsCounsellorPageState();
}

class _UpdateBankDetailsCounsellorPageState
    extends State<UpdateBankDetailsCounsellorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('counsellors')
        .doc(widget.username)
        .get();
    final data = doc.data();

    if (data != null && data['bankDetails'] != null) {
      final bank = Map<String, dynamic>.from(data['bankDetails']);
      _accountController.text = bank['bankAccountNumber'] ?? '';
      _ifscController.text = bank['ifscCode'] ?? '';
      _nameController.text = bank['fullName'] ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateBankDetails() async {
    if (_formKey.currentState!.validate()) {
      final newDetails = {
        'bankAccountNumber': _accountController.text.trim(),
        'ifscCode': _ifscController.text.trim(),
        'fullName': _nameController.text.trim(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('counsellors')
            .doc(widget.username)
            .update({'bankDetails': newDetails});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bank details updated successfully.")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Update Bank Details",
            style: GoogleFonts.outfit(color: Colors.black)),
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
                    width: double.infinity,
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: _accountController,
                                label: "Bank Account Number",
                                icon: Icons.account_balance,
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: 20),
                              _buildInputField(
                                controller: _ifscController,
                                label: "IFSC Code",
                                icon: Icons.code,
                              ),
                              SizedBox(height: 20),
                              _buildInputField(
                                controller: _nameController,
                                label: "Full Name",
                                icon: Icons.person,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateBankDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.greenAccent[700], // Green accent background
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "UPDATE",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
