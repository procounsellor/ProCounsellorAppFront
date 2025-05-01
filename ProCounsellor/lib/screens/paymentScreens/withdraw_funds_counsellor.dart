import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_utils.dart';

class WithdrawFundsCounsellorPage extends StatefulWidget {
  final String userName;

  WithdrawFundsCounsellorPage({required this.userName});

  @override
  _WithdrawFundsCounsellorPageState createState() =>
      _WithdrawFundsCounsellorPageState();
}

class _WithdrawFundsCounsellorPageState
    extends State<WithdrawFundsCounsellorPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _bankDetails;
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    _fetchCounsellorDetails();
  }

  Future<void> _fetchCounsellorDetails() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiUtils.baseUrl}/api/counsellor/${widget.userName}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['bankDetails'] != null) {
          setState(() {
            _bankDetails = data['bankDetails'];
            _walletBalance = (data['walletAmount'] ?? 0).toDouble();
            _isLoading = false;
          });
        } else {
          setState(() {
            _walletBalance = (data['walletAmount'] ?? 0).toDouble();
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No bank details found.")),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch counsellor details.")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _withdrawFunds() async {
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

    if (_walletBalance != null && amount > _walletBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Insufficient wallet balance")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiUtils.baseUrl}/api/wallet/withdraw"),
        body: {
          "userName": widget.userName,
          "amount": amount.toString(),
        },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Withdrawal successful")),
        );
        Navigator.pop(context, true); // Return success
      } else {
        final errorMsg = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: $errorMsg")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Withdraw Funds")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _bankDetails == null
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("No bank details available."),
                      SizedBox(height: 16),
                      Text(
                          "Wallet Balance: ₹${_walletBalance?.toStringAsFixed(2) ?? '0.00'}"),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Withdraw to:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                          "Bank Account: ${_bankDetails!['bankAccountNumber']}"),
                      Text("IFSC Code: ${_bankDetails!['ifscCode']}"),
                      Text("Account Holder: ${_bankDetails!['fullName']}"),
                      SizedBox(height: 16),
                      Text(
                        "Wallet Balance: ₹${_walletBalance?.toStringAsFixed(2) ?? '0.00'}",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: _amountController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Enter Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _withdrawFunds,
                          child: Text("Withdraw"),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
