import 'dart:async';
import 'weighing_scale_models.dart';

abstract class WeighingScaleDriver {
  Future<bool> connect(String addressOrPort);
  Future<void> disconnect();
  Future<void> zero();
  Future<void> tare();
  bool get isConnected;
  Stream<WeighingScaleReading> get readingStream;
  WeighingScaleReading get latestReading;
}

class VirtualSimulatedWeighingScaleDriver implements WeighingScaleDriver {
  bool _connected = false;
  double _currentWeight = 1.250;
  bool _isStable = true;

  final StreamController<WeighingScaleReading> _streamCtrl =
      StreamController<WeighingScaleReading>.broadcast();

  WeighingScaleReading _latest = WeighingScaleReading.zero();

  VirtualSimulatedWeighingScaleDriver() {
    _updateLatest();
  }

  void _updateLatest() {
    _latest = WeighingScaleReading(
      weightKg: double.parse(_currentWeight.toStringAsFixed(3)),
      rawValue: _currentWeight,
      unit: ScaleWeightUnit.kg,
      isStable: _isStable,
      isTare: false,
      timestamp: DateTime.now(),
      rawData: 'ST,GS,+${_currentWeight.toStringAsFixed(3)}kg',
    );
  }

  @override
  bool get isConnected => _connected;

  @override
  Stream<WeighingScaleReading> get readingStream => _streamCtrl.stream;

  @override
  WeighingScaleReading get latestReading => _latest;

  @override
  Future<bool> connect(String addressOrPort) async {
    _connected = true;
    _updateLatest();
    _streamCtrl.add(_latest);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<void> tare() async {}

  @override
  Future<void> zero() async {
    _currentWeight = 0.0;
    _isStable = true;
    _updateLatest();
    _streamCtrl.add(_latest);
  }

  void setWeight(double weightKg, {bool isStable = true}) {
    _currentWeight = weightKg;
    _isStable = isStable;
    _updateLatest();
    _streamCtrl.add(_latest);
  }

  void dispose() {
    _streamCtrl.close();
  }
}

class WeighingScaleManager {
  static final WeighingScaleManager _instance = WeighingScaleManager._internal();
  factory WeighingScaleManager() => _instance;
  WeighingScaleManager._internal() {
    _subscribeToDriver();
  }

  WeighingScaleDriver _driver = VirtualSimulatedWeighingScaleDriver();
  StreamSubscription<WeighingScaleReading>? _sub;

  final StreamController<WeighingScaleReading> _managerStreamCtrl =
      StreamController<WeighingScaleReading>.broadcast();

  double _manualTareKg = 0.0;
  String? _connectedDeviceName;
  String? _connectedAddress;

  bool get isConnected => _driver.isConnected;
  
  WeighingScaleReading get currentReading {
    final raw = _driver.latestReading;
    final net = (raw.weightKg - _manualTareKg).clamp(0.0, 999.999);
    return raw.copyWith(
      weightKg: double.parse(net.toStringAsFixed(3)),
      isTare: _manualTareKg > 0 || raw.isTare,
    );
  }

  Stream<WeighingScaleReading> get weightStream => _managerStreamCtrl.stream;
  double get manualTareKg => _manualTareKg;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedAddress => _connectedAddress;
  WeighingScaleDriver get currentDriver => _driver;

  void registerTransportDriver(WeighingScaleDriver newDriver) {
    _sub?.cancel();
    _driver = newDriver;
    _manualTareKg = 0.0;
    _subscribeToDriver();
  }

  void _subscribeToDriver() {
    _sub = _driver.readingStream.listen((_) {
      _managerStreamCtrl.add(currentReading);
    });
  }

  Future<bool> connectScale({
    required String addressOrPort,
    String? deviceName,
  }) async {
    final success = await _driver.connect(addressOrPort);
    if (success) {
      _connectedAddress = addressOrPort;
      _connectedDeviceName = deviceName ?? addressOrPort;
      _managerStreamCtrl.add(currentReading);
    }
    return success;
  }

  Future<void> disconnectScale() async {
    await _driver.disconnect();
    _connectedAddress = null;
    _connectedDeviceName = null;
    _managerStreamCtrl.add(currentReading);
  }

  Future<void> zeroScale() async {
    _manualTareKg = 0.0;
    await _driver.zero();
    _managerStreamCtrl.add(currentReading);
  }

  Future<void> tareScale() async {
    _manualTareKg = _driver.latestReading.weightKg;
    await _driver.tare();
    _managerStreamCtrl.add(currentReading);
  }

  void resetTare() {
    _manualTareKg = 0.0;
    _managerStreamCtrl.add(currentReading);
  }

  void reset() {
    _manualTareKg = 0.0;
    _connectedAddress = null;
    _connectedDeviceName = null;
    if (_driver is VirtualSimulatedWeighingScaleDriver) {
      (_driver as VirtualSimulatedWeighingScaleDriver).setWeight(0.0);
    }
    _managerStreamCtrl.add(currentReading);
  }

  void simulateWeight(double weightKg, {bool isStable = true}) {
    if (_driver is VirtualSimulatedWeighingScaleDriver) {
      (_driver as VirtualSimulatedWeighingScaleDriver)
          .setWeight(weightKg, isStable: isStable);
      _managerStreamCtrl.add(currentReading);
    }
  }
}
