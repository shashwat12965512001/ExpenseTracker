import 'package:flutter/material.dart';

class TransactionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  // Constructor to accept transactions as a parameter
  const TransactionScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactions.isEmpty
          ? const Center(
              child: Text(
                'No Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('₹${transactions[index]['amount']}'),
                    ),
                    title: Text(transactions[index]['description']),
                    subtitle: Text(transactions[index]['date']),
                  ),
                );
              },
            ),
    );
  }
}
