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
  final _storeNameCtrl = TextEditingController(text: 'Pune Mega Mart & Cafe');
  final _agentNameCtrl = TextEditingController(text: 'Rohan Sharma');
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _pinCtrl = TextEditingController(text: '1234');
  bool _obscurePin = true;
  String? _error;
  String? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    final profiles = widget.repository.getAllProfiles();
    if (profiles.isNotEmpty) {
      _selectedProfileId = profiles.first.id;
      _storeNameCtrl.text = profiles.first.storeName;
    }
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _agentNameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
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
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }

    // Check if store profile exists or create one
    final profiles = widget.repository.getAllProfiles();
    BusinessProfile profile;
    if (_selectedProfileId != null && profiles.any((p) => p.id == _selectedProfileId)) {
      profile = profiles.firstWhere((p) => p.id == _selectedProfileId);
    } else if (profiles.isNotEmpty) {
      profile = profiles.first;
    } else {
      profile = BusinessProfile(
        id: 'store_${DateTime.now().millisecondsSinceEpoch}',
        storeName: _storeNameCtrl.text.trim().isNotEmpty ? _storeNameCtrl.text.trim() : 'Pune Mega Mart & Cafe',
        legalEntityName: _storeNameCtrl.text.trim().isNotEmpty ? _storeNameCtrl.text.trim() : 'Pune Mega Mart LLP',
        gstin: '27AABCE1234F1Z5',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'MG Road, Camp, Pune - 411001',
        phone: phone,
        email: 'billing@punemart.com',
        upiId: 'punemart@icici',
        bankName: 'HDFC Bank',
        accountNumber: '50200012345678',
        ifscCode: 'HDFC0001234',
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

  void _fillDemoCredentials() {
    setState(() {
      _agentNameCtrl.text = 'Rohan Sharma';
      _phoneCtrl.text = '9876543210';
      _pinCtrl.text = '1234';
      _error = null;
    });
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delivery_dining, size: 36, color: Colors.indigo.shade700),
                    ),
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
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (existingProfiles.length > 1) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProfileId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Store Branch',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        items: existingProfiles.map((p) {
                          return DropdownMenuItem(value: p.id, child: Text(p.storeName));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedProfileId = val;
                            final selected = existingProfiles.firstWhere((p) => p.id == val);
                            _storeNameCtrl.text = selected.storeName;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else if (existingProfiles.isEmpty) ...[
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
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '4-Digit Agent PIN',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _fillDemoCredentials,
                        icon: const Icon(Icons.auto_fix_high, size: 14),
                        label: const Text('Fill Demo Credentials', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Start Field Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
