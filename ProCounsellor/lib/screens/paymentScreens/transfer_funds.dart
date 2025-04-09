import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_utils.dart';

class TransferFundsPage extends StatefulWidget {
  @override
  _TransferFundsPageState createState() => _TransferFundsPageState();
}

class _TransferFundsPageState extends State<TransferFundsPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _counsellorIdController = TextEditingController();

  Future<void> _transferFunds() async {
    double amount = double.parse(_amountController.text);
    String counsellorId = _counsellorIdController.text;

    final response = await http.post(
      Uri.parse("${ApiUtils.baseUrl}/api/wallet/transfer"),
      body: {"userName": "testUser", "counsellorName": counsellorId, "amount": amount.toString()},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Funds Transferred Successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transfer Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transfer Funds")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _counsellorIdController,
              decoration: InputDecoration(labelText: "Enter Counsellor ID"),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter Amount"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _transferFunds,
              child: Text("Transfer"),
            ),
          ],
        ),
      ),
    );
  }
}