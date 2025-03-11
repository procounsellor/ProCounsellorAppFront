import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_utils.dart';

class AddFundsPage extends StatefulWidget {
  final String userName;

  AddFundsPage({required this.userName});

  @override
  _AddFundsPageState createState() => _AddFundsPageState();
}

class _AddFundsPageState extends State<AddFundsPage> {
  final TextEditingController _amountController = TextEditingController();
  Razorpay _razorpay = Razorpay();

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Successful: ${response.paymentId}")));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: ${response.message}")));
  }

  Future<void> _createPaymentOrder() async {
    double amount = double.parse(_amountController.text);
    final response = await http.post(
      Uri.parse("${ApiUtils.baseUrl}/api/wallet/add"),
      body: {"userName": widget.userName, "amount": amount.toString()},
    );
    if (response.statusCode == 200) {
      var order = json.decode(response.body);
      var options = {
        'key': 'rzp_test_8xOADtg8bQfRYt',
        'amount': amount * 100,
        'currency': 'INR',
        'order_id': order['id'],
        'name': 'Test User',
        'description': 'Adding Funds',
        'prefill': {'contact': '9470988669', 'email': 'ashu11august@gmail.com'},
      };
      _razorpay.open(options);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create payment order")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Funds")),
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
              onPressed: _createPaymentOrder,
              child: Text("Proceed to Pay"),
            ),
          ],
        ),
      ),
    );
  }
}