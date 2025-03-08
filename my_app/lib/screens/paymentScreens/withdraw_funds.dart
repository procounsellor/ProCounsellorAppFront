import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WithdrawFundsPage extends StatefulWidget {
  @override
  _WithdrawFundsPageState createState() => _WithdrawFundsPageState();
}

class _WithdrawFundsPageState extends State<WithdrawFundsPage> {
  final TextEditingController _amountController = TextEditingController();

  Future<void> _withdrawFunds() async {
    double amount = double.parse(_amountController.text);

    final response = await http.post(
      Uri.parse("http://localhost:8080/api/wallet/withdraw"),
      body: {"userName": "counsellorUser", "amount": amount.toString()},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Withdrawal Request Sent")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Withdrawal Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Withdraw Funds")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter Amount"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _withdrawFunds,
              child: Text("Withdraw"),
            ),
          ],
        ),
      ),
    );
  }
}
