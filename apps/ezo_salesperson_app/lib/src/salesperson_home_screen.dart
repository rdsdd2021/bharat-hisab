import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';

class SalespersonHomeScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;
  final StaffMember staff;

  const SalespersonHomeScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
    required this.staff,
  });

  @override
  State<SalespersonHomeScreen> createState() => _SalespersonHomeScreenState();
}

class _SalespersonHomeScreenState extends State<SalespersonHomeScreen> {
  int _navIndex = 0; // 0: Quick Billing, 1: Field Collections, 2: My Shift Settlement

  // Quick Cart State
  final List<InvoiceLineItem> _salesCart = [];
  PartyAccount? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.storeProfile.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Rep: ${widget.staff.fullName} (${widget.staff.role.name})', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
            child: const Text('STAFF MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _buildCurrentBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (idx) => setState(() => _navIndex = idx),
        selectedItemColor: Colors.indigo.shade800,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Quick Bill'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Field Collection'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'My Settlement'),
        ],
      ),
    );
  }

  Widget _buildCurrentBody() {
    switch (_navIndex) {
      case 0:
        return _buildQuickBilling();
      case 1:
        return _buildFieldCollections();
      case 2:
        return _buildShiftSettlement();
      default:
        return const SizedBox();
    }
  }

  Widget _buildQuickBilling() {
    final products = widget.repository.getAllProducts();

    return Column(
      children: [
        // Cart Summary Header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items: ${_salesCart.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'Total: ₹${_salesCart.fold(0.0, (s, i) => s + i.totalAmount).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Punch & Print'),
                onPressed: _salesCart.isNotEmpty ? _handlePunchBill : null,
              ),
            ],
          ),
        ),

        // Product Quick List for Floor/Field Sales
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final p = products[idx];
              return ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('SKU: ${p.skuCode} | Stock: ${p.currentStock.toInt()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${p.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final line = EzoGstTaxEngine.buildLineItem(product: p, quantity: 1);
                          _salesCart.add(line);
                        });
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCollections() {
    final customers = widget.repository.getCustomerParties().where((c) => c.netBalance > 0).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Collect pending Udhaar from ${customers.length} customers via Dynamic UPI QR codes.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final c = customers[idx];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Due: ₹${c.netBalance.toStringAsFixed(2)} | Ph: ${c.phone}'),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Show UPI QR'),
                  onPressed: () => _showCollectionQrDialog(c),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShiftSettlement() {
    // Aggregates shift totals punched by this staff member
    final myInvoices = widget.repository
        .getAllInvoices()
        .where((i) => i.cashierStaffId == widget.staff.id)
        .toList();

    final totalBilled = myInvoices.fold(0.0, (s, i) => s + i.grandTotal);
    final cashCollected = myInvoices
        .where((i) => i.settlementMode == SettlementMode.cash)
        .fold(0.0, (s, i) => s + i.amountReceived);
    final upiCollected = myInvoices
        .where((i) => i.settlementMode == SettlementMode.upiQr)
        .fold(0.0, (s, i) => s + i.amountReceived);
    final udhaarBooked = myInvoices.fold(0.0, (s, i) => s + i.balanceUdhaarDue);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Daily Shift Settlement Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Hand over this physical cash & UPI total to store manager at shift end.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildShiftRow('Bills Punched by Me', '${myInvoices.length} bills'),
                  _buildShiftRow('Total Sales Volume', '₹${totalBilled.toStringAsFixed(2)}', isBold: true),
                  const Divider(),
                  _buildShiftRow('💵 Cash in My Hand (To Submit)', '₹${cashCollected.toStringAsFixed(2)}', color: Colors.green, isBold: true),
                  _buildShiftRow('📱 Direct Store UPI Received', '₹${upiCollected.toStringAsFixed(2)}', color: Colors.blue),
                  _buildShiftRow('📝 Credit/Udhaar Booked', '₹${udhaarBooked.toStringAsFixed(2)}', color: Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: 16)),
        ],
      ),
    );
  }

  void _handlePunchBill() async {
    final invNo = 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final inv = EzoGstTaxEngine.createInvoiceDocument(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: invNo,
      invoiceDate: DateTime.now(),
      storeProfile: widget.storeProfile,
      party: _selectedCustomer,
      lineItems: _salesCart,
      cashier: widget.staff,
    );

    await widget.repository.commitSalesInvoice(inv);

    // Print 58mm Chota receipt over Bluetooth
    final bytes = EscPosThermalEngine.buildInvoiceByteStream(
      invoice: inv,
      storeProfile: widget.storeProfile,
      rollWidth: ThermalRollWidth.chota58mm,
    );
    await ThermalPrinterConnectionManager().printBytes(bytes);

    setState(() {
      _salesCart.clear();
      _selectedCustomer = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill #$invNo punched & printed on 58mm Bluetooth printer!')),
      );
    }
  }

  void _showCollectionQrDialog(PartyAccount customer) {
    final upiUri = UpiQrGenerator.buildUpiPaymentUri(
      merchantUpiId: widget.storeProfile.upiId,
      merchantName: widget.storeProfile.storeName,
      amount: customer.netBalance,
      note: 'Payment by ${customer.name}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Collect ₹${customer.netBalance.toStringAsFixed(2)} - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 160, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(upiUri, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await widget.repository.recordPartyPayment(
                partyId: customer.id,
                amount: customer.netBalance,
                paymentMode: 'upi',
                collectedByStaffId: widget.staff.id,
                collectedByStaffName: widget.staff.fullName,
              );
              setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Payment Received'),
          ),
        ],
      ),
    );
  }
}
