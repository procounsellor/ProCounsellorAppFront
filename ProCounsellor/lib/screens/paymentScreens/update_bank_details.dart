import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateBankDetailsPage extends StatefulWidget {
  final String username;

  UpdateBankDetailsPage({required this.username});

  @override
  _UpdateBankDetailsPageState createState() => _UpdateBankDetailsPageState();
}

class _UpdateBankDetailsPageState extends State<UpdateBankDetailsPage> {
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
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.username).get();
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
            .collection('users')
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
      appBar: AppBar(title: Text("Update Bank Details")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _accountController,
                      decoration: InputDecoration(labelText: "Bank Account Number"),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _ifscController,
                      decoration: InputDecoration(labelText: "IFSC Code"),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Full Name"),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateBankDetails,
                      child: Text("Update"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
