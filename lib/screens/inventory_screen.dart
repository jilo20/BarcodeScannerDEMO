import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/package_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch packages when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Inventory'),
        actions: [
          IconButton(
            onPressed: () => context.read<InventoryProvider>().fetchPackages(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventory, child) {
          if (inventory.isLoading && inventory.packages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (inventory.errorMessage != null && inventory.packages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(inventory.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => inventory.fetchPackages(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (inventory.packages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No packages found.\nStart scanning to add events!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => inventory.fetchPackages(),
            child: ListView.builder(
              itemCount: inventory.packages.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final package = inventory.packages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2),
                    ),
                    title: Text(
                      package.trackingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To: ${package.recipientName}'),
                        Text('Status: ${package.currentStatus}', 
                          style: TextStyle(
                            color: _getStatusColor(package.currentStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to package details or events
                      _showPackageDetails(context, package);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'in transit': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showPackageDetails(BuildContext context, Package package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Package Details', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            const SizedBox(height: 16),
            _detailRow('Tracking #', package.trackingNumber),
            _detailRow('Ref Code', package.referenceCode),
            _detailRow('Recipient', package.recipientName),
            _detailRow('Address', package.recipientAddress),
            _detailRow('Phone', package.recipientPhone),
            _detailRow('Description', package.description),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
