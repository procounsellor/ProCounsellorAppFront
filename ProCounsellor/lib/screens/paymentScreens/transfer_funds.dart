import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_utils.dart';

class TransferFundsPage extends StatefulWidget {
  final String userId;
  final String counsellorId;
  final double amount; // Pre-fetched amount

  TransferFundsPage({
    required this.userId,
    required this.counsellorId,
    required this.amount,
  });

  @override
  _TransferFundsPageState createState() => _TransferFundsPageState();
}

class _TransferFundsPageState extends State<TransferFundsPage> {
  bool _isLoading = false;

  Future<void> _transferFunds() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiUtils.baseUrl}/api/wallet/transfer"),
        body: {
          "userName": widget.userId,
          "counsellorName": widget.counsellorId,
          "amount": widget.amount.toString(),
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Funds transferred successfully")),
        );
       Navigator.pop(context, true); // ✅ Notify caller with success
      } else {
        final errorMsg = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: $errorMsg")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong. Try again.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Confirm Transfer")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User ID: ${widget.userId}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Counsellor ID: ${widget.counsellorId}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Amount: ₹${widget.amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _transferFunds,
                      child: Text("Confirm & Transfer"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
