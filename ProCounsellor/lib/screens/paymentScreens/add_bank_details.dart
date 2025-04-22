import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddBankDetailsPage extends StatefulWidget {
  final String username;

  AddBankDetailsPage({required this.username});

  @override
  _AddBankDetailsPageState createState() => _AddBankDetailsPageState();
}

class _AddBankDetailsPageState extends State<AddBankDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
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
          .collection('users')
          .doc(widget.username)
          .get();

      final data = doc.data();

      if (doc.exists && data != null && data.containsKey('bankDetails') && data['bankDetails'] != null) {
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
            .collection('users')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bank Details")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasBankDetails && _bankDetails != null
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bank Account Number: ${_bankDetails?['bankAccountNumber'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "IFSC Code: ${_bankDetails?['ifscCode'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Full Name: ${_bankDetails?['fullName'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _accountNumberController,
                          decoration: InputDecoration(labelText: "Bank Account Number"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value == null || value.isEmpty ? "Enter account number" : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _ifscCodeController,
                          decoration: InputDecoration(labelText: "IFSC Code"),
                          validator: (value) => value == null || value.isEmpty ? "Enter IFSC code" : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(labelText: "Full Name"),
                          validator: (value) => value == null || value.isEmpty ? "Enter full name" : null,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitBankDetails,
                          child: Text("Submit"),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
