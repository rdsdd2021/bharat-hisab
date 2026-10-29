import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import 'package:ezo_pos_merchant_app/src/controllers/pos_billing_controller.dart';
import 'package:ezo_pos_merchant_app/src/services/android_weighing_scale_driver.dart';
import 'package:ezo_pos_merchant_app/src/widgets/weighing_scale_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Electronic Weighing Scale Parser Tests', () {
    test('Parses standard Indian continuous ASCII stream format (ST,GS,+001.250kg)', () {
      final reading = WeighingScaleParser.parse('ST,GS,+001.250kg\r\n');
      expect(reading, isNotNull);
      expect(reading!.weightKg, 1.250);
      expect(reading.isStable, isTrue);
      expect(reading.isTare, isFalse);
      expect(reading.isOverload, isFalse);
    });

    test('Parses unstable stream format (US,GS,+000.500kg)', () {
      final reading = WeighingScaleParser.parse('US,GS,+000.500kg\r\n');
      expect(reading, isNotNull);
      expect(reading!.weightKg, 0.500);
      expect(reading.isStable, isFalse);
    });

    test('Parses net tare stream format (ST,NT,+002.100kg)', () {
      final reading = WeighingScaleParser.parse('ST,NT,+002.100kg\r\n');
      expect(reading, isNotNull);
      expect(reading!.weightKg, 2.100);
      expect(reading.isTare, isTrue);
    });

    test('Normalizes grams mode to kilograms (ST,GS,+00750g)', () {
      final reading = WeighingScaleParser.parse('ST,GS,+00750g\r\n');
      expect(reading, isNotNull);
      expect(reading!.weightKg, 0.750);
      expect(reading.unit, ScaleWeightUnit.g);
    });

    test('Parses Phoenix / Essae format (WN003.500KG)', () {
      final reading = WeighingScaleParser.parse('WN003.500KG\r\n');
      expect(reading, isNotNull);
      expect(reading!.weightKg, 3.500);
      expect(reading.isTare, isTrue);
    });

    test('Parses prefix equals format (=01.450)', () {
      final reading = WeighingScaleParser.parse('=01.450\r');
      expect(reading, isNotNull);
      expect(reading!.weightKg, 1.450);
    });

    test('Detects scale overload status (OL)', () {
      final reading = WeighingScaleParser.parse('+OL.OOOkg\r\n');
      expect(reading, isNotNull);
      expect(reading!.isOverload, isTrue);
      expect(reading.isStable, isFalse);
    });
  });

  group('Weighing Scale Manager & Transport Driver Tests', () {
    test('Simulated driver connects, streams weight, tares, and zeroes', () async {
      final manager = WeighingScaleManager();
      manager.reset();
      final driver = VirtualSimulatedWeighingScaleDriver();
      manager.registerTransportDriver(driver);

      final connected = await manager.connectScale(addressOrPort: 'VIRTUAL_01', deviceName: 'Virtual Scale');
      expect(connected, isTrue);
      expect(manager.isConnected, isTrue);

      driver.setWeight(2.500);
      expect(manager.currentReading.weightKg, 2.500);

      // Test tare
      await manager.tareScale();
      expect(manager.currentReading.weightKg, 0.0);
      expect(manager.manualTareKg, 2.500);

      // Add more weight (bowl + fruit: 3.500 kg total - 2.500 kg tare = 1.000 kg net)
      driver.setWeight(3.500);
      expect(manager.currentReading.weightKg, 1.000);

      // Test zero
      await manager.zeroScale();
      expect(manager.currentReading.weightKg, 0.0);
      expect(manager.manualTareKg, 0.0);

      await manager.disconnectScale();
      expect(manager.isConnected, isFalse);
    });
  });

  group('PosBillingController Weighing Scale Integration', () {
    late LocalDatabase db;
    late EzoOfflineRepository repo;

    const sampleProfile = BusinessProfile(
      id: 'store_kirana_scale',
      storeName: 'Bharat Super Store',
      legalEntityName: 'Bharat Retail Pvt Ltd',
      gstin: '27AABCT1234F1Z5',
      stateCode: '27',
      stateName: 'Maharashtra',
      address: 'Market Yard, Pune',
      phone: '9876543210',
      email: 'contact@bharatretail.in',
      upiId: 'retail@upi',
      industryVertical: IndustryVertical.kiranaGrocery,
    );

    const looseSugar = ProductItem(
      id: 'prod_loose_sugar',
      name: 'Loose Premium Sugar (Madhur)',
      skuCode: 'SUGAR-LOOSE-01',
      unit: ItemUnit.kg,
      mrp: 45.0,
      sellingPrice: 42.0,
      gstPercent: 5.0,
    );

    setUp(() async {
      db = LocalDatabase();
      await db.initialize();
      repo = EzoOfflineRepository(db: db);
      await repo.saveProfile(sampleProfile);
      await repo.upsertProduct(looseSugar);
      WeighingScaleManager().reset();
    });

    test('Applies live scale weight to loose cart item quantity', () async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: sampleProfile,
      );

      // 1. Add loose sugar to cart with default 1 qty
      controller.addProductToCart(looseSugar);
      expect(controller.cartLines.length, 1);
      expect(controller.cartLines.first.quantity, 1.0);

      // 2. Set scale pan weight to 2.450 KG
      controller.setSimulatedScaleWeight(2.450);
      expect(controller.liveScaleWeightKg, 2.450);

      // 3. Apply scale weight to cart line 0
      final applied = controller.applyScaleWeightToCartLine(0);
      expect(applied, isTrue);

      // 4. Verify quantity is now exactly 2.450 KG
      expect(controller.cartLines.first.quantity, 2.450);

      // 5. Total amount is 2.450 × ₹42 = ₹102.90
      expect(controller.cartLines.first.totalAmount, closeTo(102.90, 0.01));
    });
  });

  group('WeighingScaleModal UI & Interactive Controls', () {
    testWidgets('WeighingScaleModal renders electronic bezel, tare, zero, and presets', (tester) async {
      final manager = WeighingScaleManager();
      manager.reset();
      final driver = VirtualSimulatedWeighingScaleDriver();
      manager.registerTransportDriver(driver);
      driver.setWeight(1.250);

      double? appliedWeight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeighingScaleModal(
              targetItemName: 'Basmati Rice',
              onWeightApplied: (wt) {
                appliedWeight = wt;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and digital readout
      expect(find.text('Electronic Weighing Scale'), findsOneWidget);
      expect(find.text('1.250'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);
      expect(find.text('ZERO SCALE'), findsOneWidget);
      expect(find.text('TARE BOWL'), findsOneWidget);

      // Switch to Simulator tab
      await tester.tap(find.text('Simulator'));
      await tester.pumpAndSettle();

      // Tap preset chip '500g'
      expect(find.text('500g'), findsOneWidget);
      await tester.tap(find.text('500g'));
      await tester.pumpAndSettle();

      // Verify readout updated to 0.500
      expect(find.text('0.500'), findsOneWidget);

      // Tap ZERO SCALE
      await tester.tap(find.text('ZERO SCALE'));
      await tester.pumpAndSettle();

      expect(find.text('0.000'), findsOneWidget);

      // Set weight back to 1.500 KG using preset
      await tester.tap(find.text('1.500 KG'));
      await tester.pumpAndSettle();

      // Tap "Apply 1.500 KG to Basmati Rice"
      final applyButton = find.textContaining('Apply 1.500 KG to "Basmati Rice"');
      expect(applyButton, findsOneWidget);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(appliedWeight, 1.500);
    });
  });
}
