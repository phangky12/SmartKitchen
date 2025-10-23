import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_inventory_screen.dart';
import 'screens/expiry_date_scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kitchen Assistant',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: HomeScreen(), // This defines the initial screen
      routes: {
        // Remove the '/' route since we're using 'home' property
        '/dashboard': (context) => DashboardScreen(),
        '/add-item': (context) => AddInventoryScreen(),
        '/scan-expiry': (context) => ExpiryDateScannerScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}