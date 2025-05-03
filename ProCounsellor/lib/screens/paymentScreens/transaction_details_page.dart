import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsPage({required this.transaction});

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction['type'] == 'credit';

    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction Details", style: GoogleFonts.outfit()),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${isCredit ? '+' : '-'} ₹${transaction['amount']}",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Type: ${transaction['type'].toString().toUpperCase()}",
              style: GoogleFonts.outfit(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Description: ${transaction['description'] ?? 'N/A'}",
              style: GoogleFonts.outfit(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Time: ${_formatTimestamp(transaction['timestamp'])}",
              style: GoogleFonts.outfit(fontSize: 16),
            ),
            if (transaction['referenceId'] != null) ...[
              SizedBox(height: 8),
              Text(
                "Reference ID: ${transaction['referenceId']}",
                style: GoogleFonts.outfit(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
