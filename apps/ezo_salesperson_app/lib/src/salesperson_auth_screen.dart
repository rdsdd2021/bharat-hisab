import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';

class SalespersonAuthScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final Function(BusinessProfile, StaffMember) onAuthenticated;

  const SalespersonAuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  @override
  State<SalespersonAuthScreen> createState() => _SalespersonAuthScreenState();
}

class _SalespersonAuthScreenState extends State<SalespersonAuthScreen> {
  final _storeNameCtrl = TextEditingController(text: 'My Business Store');
  final _agentNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final profiles = widget.repository.getAllProfiles();
    if (profiles.isNotEmpty) {
      _storeNameCtrl.text = profiles.first.storeName;
    }
  }

  void _handleLogin() async {
    final agentName = _agentNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (agentName.isEmpty || phone.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Please enter your Name, Phone Number, and 4-digit PIN.');
      return;
    }

    if (pin.length < 4) {
      setState(() => _error = 'PIN must be 4 digits.');
      return;
    }

    // Check if store profile exists or create one
    final profiles = widget.repository.getAllProfiles();
    BusinessProfile profile;
    if (profiles.isNotEmpty) {
      profile = profiles.first;
    } else {
      profile = BusinessProfile(
        id: 'store_${DateTime.now().millisecondsSinceEpoch}',
        storeName: _storeNameCtrl.text.trim().isNotEmpty ? _storeNameCtrl.text.trim() : 'My Retail Store',
        legalEntityName: _storeNameCtrl.text.trim().isNotEmpty ? _storeNameCtrl.text.trim() : 'My Retail Store',
        gstin: '',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'Market Area',
        phone: phone,
        email: 'store@bharathisab.com',
        upiId: 'store@upi',
        bankName: 'State Bank of India',
        accountNumber: '998877665544',
        ifscCode: 'SBIN0001234',
      );
      await widget.repository.saveProfile(profile);
    }

    // Save staff member
    final staff = StaffMember(
      id: 'staff_field_${DateTime.now().millisecondsSinceEpoch}',
      storeProfileId: profile.id,
      fullName: agentName,
      phone: phone,
      pinCode: pin,
      role: StaffRole.fieldSalesperson,
      canEditPrices: false,
      canDeleteBills: false,
      canViewProfitReports: false,
      canCollectUdhaar: true,
      createdAt: DateTime.now(),
    );
    await widget.repository.saveStaff(staff);

    widget.onAuthenticated(profile, staff);
  }

  @override
  Widget build(BuildContext context) {
    final existingProfiles = widget.repository.getAllProfiles();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.delivery_dining, size: 48, color: Colors.indigo),
                    const SizedBox(height: 12),
                    const Text(
                      'Sales Representative Sign In',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Field Order Booking & Doorstep Udhaar Khata Collection',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (existingProfiles.isEmpty) ...[
                      TextField(
                        controller: _storeNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Merchant / Shop Name',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: _agentNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Salesperson Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '4-Digit Agent PIN',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Start Field Session', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _handleLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
