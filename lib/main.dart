import 'package:expense_tracker/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'transaction_screen.dart';
import 'profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform =
      MethodChannel('com.example.expense_tracker/notifications');

  String _transactionMessage = 'No transactions yet.';
  int _selectedIndex = 0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _startNotificationListener();
    requestSmsPermission();
    readSmsMessages();
    fetchAndDisplayTransactions();
  }

  void readSmsMessages() async {
    debugPrint("readSmsMessages called");
    final SmsQuery query = SmsQuery();

    final List<SmsMessage> messages = await query.getAllSms;

    // List<SmsQueryKind> kinds = [SmsQueryKind.Inbox, SmsQueryKind.Sent];
    // final List<SmsMessage> messages = await query.querySms(kinds: kinds);

    debugPrint("messages length: ${messages.length}");
    if (messages.isNotEmpty) {
      debugPrint("if");
      for (var message in messages) {
        if (isUpiTransaction(message.body.toString())) {
          // Extract relevant data (amount, transaction ID, etc.)
          setState(() {
            _transactionMessage = message.body.toString();
            storeTransaction(extractTransactionData(_transactionMessage));
            debugPrint(_transactionMessage);
          });
        }
      }
    }
  }

  Map<String, dynamic> extractTransactionData(String messageBody) {
    // Use regex or pattern matching to extract data from message
    RegExp amountPattern = RegExp(r'(\d+(\.\d{1,2})?)');
    RegExp transactionIdPattern = RegExp(r'Transaction ID: (\w+)');

    String? amount = amountPattern.firstMatch(messageBody)?.group(0);
    String? transactionId =
        transactionIdPattern.firstMatch(messageBody)?.group(1);

    return {
      'amount': amount,
      'transactionId': transactionId,
      'message': messageBody,
    };
  }

  bool isUpiTransaction(String messageBody) {
    // Simple keyword check for UPI-related SMS
    return messageBody.contains('credited') || messageBody.contains('debited');
  }

  Future<void> _startNotificationListener() async {
    try {
      await platform.invokeMethod('startNotificationListener');
    } on PlatformException catch (e) {
      debugPrint("e.message: ${e.message}");
    }

    platform.setMethodCallHandler((call) async {
      if (call.method == 'notifyTransaction') {
        String transactionData = call.arguments;
        setState(() {
          _transactionMessage = transactionData;
          debugPrint(_transactionMessage);
        });
      }
    });
  }

  Future<void> requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void storeTransaction(Map<String, dynamic> transactionData) async {
    await DatabaseHelper.instance.insertTransaction(transactionData);
  }

  Future<List<Map<String, dynamic>>> fetchAndDisplayTransactions() async {
    List<Map<String, dynamic>> dbtransactions =
        await DatabaseHelper.instance.getTransactions();
    transactions = dbtransactions;
    return dbtransactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TransactionScreen(
            transactions: transactions,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
