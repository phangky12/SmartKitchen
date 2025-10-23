import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Map<String, dynamic>> _items = [];

  void _addNewItem() async {
    final result = await Navigator.pushNamed(context, '/add-item');
    
    if (result != null && mounted) {
      setState(() {
        _items.add(result as Map<String, dynamic>);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
    }
  }

  // Add some sample data for testing
  @override
  void initState() {
    super.initState();
    // Add some sample items
    _items.addAll([
      {
        'name': 'Milk',
        'quantity': '2',
        'unit': 'liters',
        'expiryDate': '25/12/2024',
        'category': 'Dairy',
      },
      {
        'name': 'Eggs',
        'quantity': '12',
        'unit': 'pieces',
        'expiryDate': '30/12/2024',
        'category': 'Dairy',
      },
      {
        'name': 'Bread',
        'quantity': '1',
        'unit': 'loaf',
        'expiryDate': '20/12/2024',
        'category': 'Grains',
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewItem,
            tooltip: 'Add new item',
          ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No items in inventory',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addNewItem,
                    child: const Text('Add Your First Item'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.kitchen, color: Colors.teal),
                    title: Text(
                      item['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['quantity']} ${item['unit']}'),
                        Text('Category: ${item['category']}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                        const SizedBox(height: 2),
                        Text(
                          item['expiryDate'] ?? 'No date',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // You can add edit functionality here later
                    },
                  ),
                );
              },
            ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addNewItem,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}