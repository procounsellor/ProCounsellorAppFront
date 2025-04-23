import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String username;

  TransactionHistoryPage({required this.username});

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  static const String USERS_COLLECTION = 'users';
  static const String COUNSELLORS_COLLECTION = 'counsellors';

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
  try {
    DocumentSnapshot docSnapshot;

    // Step 1: Check users collection
    docSnapshot = await FirebaseFirestore.instance
        .collection(USERS_COLLECTION)
        .doc(widget.username)
        .get();

    // Step 2: If not found, check counsellors collection
    if (!docSnapshot.exists) {
      docSnapshot = await FirebaseFirestore.instance
          .collection(COUNSELLORS_COLLECTION)
          .doc(widget.username)
          .get();

      if (!docSnapshot.exists) {
        throw Exception("User or Counsellor not found");
      }
    }

    final data = docSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('transactions')) {
      List<dynamic> transactionsRaw = data['transactions'];

      List<Map<String, dynamic>> transactions = transactionsRaw
          .map((txn) => Map<String, dynamic>.from(txn))
          .toList();

      transactions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      return transactions;
    } else {
      return []; // No transactions field
    }
  } catch (e) {
    print("Error fetching transactions: $e");
    return [];
  }
}


  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Transaction History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading transactions"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No transactions found"));
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final txn = transactions[index];
              final isCredit = txn['type'] == 'credit';

              return ListTile(
                leading: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
                title: Text(
                  "${isCredit ? '+' : '-'} ₹${txn['amount'].toString()}",
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(txn['description'] ?? 'No Description'),
                trailing: Text(
                  _formatTimestamp(txn['timestamp']),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
