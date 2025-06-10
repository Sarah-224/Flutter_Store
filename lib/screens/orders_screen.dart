import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../models/order.dart' as my_models;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  Future<void> _updateOrderStatus(
    BuildContext context,
    my_models.Order order,
    String newStatus,
  ) async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    await firebaseService.updateOrderStatus(order.id, newStatus);
  }

  Future<void> _generateInvoice(BuildContext context, my_models.Order order) async {
    try {
      final bytes = await PdfService.generateOrderInvoiceBytes(order);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'فاتورة_طلب_${order.id}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء توليد الفاتورة: $e')),
      );
    }
  }

  Widget _buildOrderDetails(my_models.Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('معلومات العميل'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الاسم: ${order.customerName}'),
              Text('رقم الهاتف: ${order.customerPhone}'),
              Text('العنوان: ${order.deliveryAddress}'),
            ],
          ),
        ),
        Divider(),
        ListTile(
          title: Text('المنتجات'),
          subtitle: Column(
            children: order.items.map((item) {
              return ListTile(
                title: Text(item.name),
                subtitle: Text('الكمية: ${item.quantity}'),
                trailing: Text('${item.price * item.quantity} ريال'),
              );
            }).toList(),
          ),
        ),
        Divider(),
        ListTile(
          title: Text('ملخص الطلب'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المجموع: ${order.totalAmount} ريال'),
              Text('رسوم التوصيل: ${order.deliveryFee} ريال'),
              Text(
                'الإجمالي: ${order.totalAmount + order.deliveryFee} ريال',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFFFA8BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: StreamBuilder<List<my_models.Order>>(
          stream: Provider.of<FirebaseService>(context).getOrders(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!;

            if (orders.isEmpty) {
              return const Center(
                child: Text('No orders found.', style: TextStyle(color: Colors.white)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 80),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: ExpansionTile(
                    title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Row(
                      children: [
                        Text('Status: ', style: const TextStyle(fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.status == 'pending'
                                ? Colors.amber
                                : (order.status == 'delivered' || order.status == 'confirmed')
                                    ? Colors.green
                                    : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('| Total: ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildOrderDetails(order),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (order.status == 'pending')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E2DE2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => _updateOrderStatus(
                                context,
                                order,
                                'confirmed',
                              ),
                              child: const Text('Confirm Order', style: TextStyle(color: Colors.white)),
                            ),
                          if (order.status == 'confirmed')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E2DE2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => _updateOrderStatus(
                                context,
                                order,
                                'delivered',
                              ),
                              child: const Text('Mark as Delivered', style: TextStyle(color: Colors.white)),
                            ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFA8BFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => _generateInvoice(context, order),
                            child: const Text('Generate Invoice', style: TextStyle(color: Color(0xFF8E2DE2))),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 