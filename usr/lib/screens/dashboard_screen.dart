import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSyncing = false;

  // Placeholder for POS Screen
  Widget _buildPosScreen() {
    return Center(child: Text('POS Screen - Coming Soon'));
  }

  // Placeholder for Orders Screen
  Widget _buildOrdersScreen() {
    return Center(child: Text('Orders History - Coming Soon'));
  }

  // Sync Logic
  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    final api = ApiService();
    final db = DatabaseHelper.instance;

    try {
      // 1. Fetch Products from API
      List<Product> products = await api.fetchProducts();
      
      // 2. Save to Local DB
      await db.insertProducts(products);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Successful: ${products.length} products updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Failed: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildPosScreen(),
      _buildOrdersScreen(),
      Center(child: ElevatedButton(onPressed: _syncData, child: Text('Sync Data Now'))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
