import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AddFundsPage extends StatefulWidget {
  final String userName;

  AddFundsPage({required this.userName});

  @override
  _AddFundsPageState createState() => _AddFundsPageState();
}

class _AddFundsPageState extends State<AddFundsPage> {
  final TextEditingController _amountController = TextEditingController();
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment Successful: ${response.paymentId}")),
    );
    Navigator.pop(context, true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
    );
  }

  Future<void> _createPaymentOrder() async {
    final amountText = _amountController.text.trim();
    double? amount;

    try {
      amount = double.parse(amountText);
      if (amount <= 0) throw Exception();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiUtils.baseUrl}/api/wallet/add"),
        body: {
          "userName": widget.userName,
          "amount": amount.toString(),
        },
      );

      if (response.statusCode == 200) {
        final order = json.decode(response.body);
        final options = {
          'key':
              'rzp_test_8xOADtg8bQfRYt', // Replace with your actual key in prod
          'amount': (amount * 100).toInt(),
          'currency': 'INR',
          'order_id': order['id'],
          'name': 'ProCounsellor',
          'description': 'Adding Funds',
          'prefill': {
            'contact': '9470988669',
            'email': 'ashu11august@gmail.com',
          },
        };

        Future.delayed(Duration.zero, () => _razorpay.open(options));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create payment order")),
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          "ADD FUNDS",
          style: GoogleFonts.outfit(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Centered Amount Input
              TextField(
                controller: _amountController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.outfit(
                    fontSize: 36, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0), // Center it vertically
                    child: Text(
                      '₹',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: "Enter Amount",
                  hintStyle:
                      GoogleFonts.outfit(fontSize: 24, color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey.shade400, width: 2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _createPaymentOrder,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "PROCEED TO PAY",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
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
