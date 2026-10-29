import 'dart:convert';

enum ScaleWeightUnit {
  kg('KG'),
  g('G');

  final String label;
  const ScaleWeightUnit(this.label);
}

enum ScaleProtocol {
  continuousAscii('Continuous Stream (ST,GS,...)'),
  simpleEquals('Prefix Equals/Plus (=01.250)'),
  phoenixEssae('Phoenix/Essae (WN001.250KG)'),
  stxEtxToledo('Toledo STX/ETX (...)'),
  polledEnquiry('Polled Query (W\\r\\n)');

  final String displayName;
  const ScaleProtocol(this.displayName);
}

class WeighingScaleReading {
  final double weightKg;
  final double rawValue;
  final ScaleWeightUnit unit;
  final bool isStable;
  final bool isTare;
  final bool isOverload;
  final DateTime timestamp;
  final String rawData;

  const WeighingScaleReading({
    required this.weightKg,
    required this.rawValue,
    this.unit = ScaleWeightUnit.kg,
    this.isStable = true,
    this.isTare = false,
    this.isOverload = false,
    required this.timestamp,
    this.rawData = '',
  });

  static WeighingScaleReading zero() => WeighingScaleReading(
        weightKg: 0.0,
        rawValue: 0.0,
        isStable: true,
        timestamp: DateTime.now(),
        rawData: '0.000',
      );

  String get formattedWeight => '${weightKg.toStringAsFixed(3)} KG';

  WeighingScaleReading copyWith({
    double? weightKg,
    double? rawValue,
    ScaleWeightUnit? unit,
    bool? isStable,
    bool? isTare,
    bool? isOverload,
    DateTime? timestamp,
    String? rawData,
  }) {
    return WeighingScaleReading(
      weightKg: weightKg ?? this.weightKg,
      rawValue: rawValue ?? this.rawValue,
      unit: unit ?? this.unit,
      isStable: isStable ?? this.isStable,
      isTare: isTare ?? this.isTare,
      isOverload: isOverload ?? this.isOverload,
      timestamp: timestamp ?? this.timestamp,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  String toString() =>
      'WeighingScaleReading(weight: ${weightKg.toStringAsFixed(3)} kg, stable: $isStable, tare: $isTare)';
}

class WeighingScaleParser {
  // Regex 1: Standard Indian continuous format: ST,GS,+001.250kg or US,NT,+001.250kg
  static final RegExp _continuousRegex = RegExp(
    r'(ST|US)\s*,\s*(GS|NT)\s*,\s*([+\-]?\d+\.?\d*)\s*(kg|g)',
    caseSensitive: false,
  );

  // Regex 2: Phoenix / Essae format: WN001.250KG or WG001.250KG
  static final RegExp _phoenixRegex = RegExp(
    r'W(N|G)\s*([+\-]?\d+\.?\d*)\s*(KG|G)?',
    caseSensitive: false,
  );

  // Regex 3: Simple equals or plus format: =01.250 or +001.250 or -000.050
  static final RegExp _simpleEqualsRegex = RegExp(
    r'([=+\-])\s*(\d+\.?\d*)\s*(kg|g)?',
    caseSensitive: false,
  );

  // Regex 4: Generic float extractor before kg or g
  static final RegExp _genericWeightRegex = RegExp(
    r'([+\-]?\d+\.?\d*)\s*(kg|g)',
    caseSensitive: false,
  );

  /// Parses raw incoming serial/Bluetooth byte buffer into a structured WeighingScaleReading
  static WeighingScaleReading? parse(String raw) {
    if (raw.trim().isEmpty) return null;

    final trimmed = raw.trim();

    // Check overload
    if (trimmed.toUpperCase().contains('OL') || trimmed.toUpperCase().contains('OVER')) {
      return WeighingScaleReading(
        weightKg: 999.999,
        rawValue: 999.999,
        isStable: false,
        isOverload: true,
        timestamp: DateTime.now(),
        rawData: raw,
      );
    }

    // 1. Try Continuous format (ST,GS,+001.250kg)
    final contMatch = _continuousRegex.firstMatch(trimmed);
    if (contMatch != null) {
      final status = contMatch.group(1)?.toUpperCase() ?? 'ST';
      final mode = contMatch.group(2)?.toUpperCase() ?? 'GS';
      final valStr = contMatch.group(3) ?? '0.0';
      final unitStr = contMatch.group(4)?.toLowerCase() ?? 'kg';

      double rawVal = double.tryParse(valStr) ?? 0.0;
      double normalizedKg = unitStr == 'g' ? rawVal / 1000.0 : rawVal;

      return WeighingScaleReading(
        weightKg: normalizedKg < 0 ? 0.0 : normalizedKg,
        rawValue: rawVal,
        unit: unitStr == 'g' ? ScaleWeightUnit.g : ScaleWeightUnit.kg,
        isStable: status == 'ST',
        isTare: mode == 'NT',
        timestamp: DateTime.now(),
        rawData: raw,
      );
    }

    // 2. Try Phoenix / Essae format (WN001.250KG)
    final phoenixMatch = _phoenixRegex.firstMatch(trimmed);
    if (phoenixMatch != null) {
      final mode = phoenixMatch.group(1)?.toUpperCase() ?? 'N';
      final valStr = phoenixMatch.group(2) ?? '0.0';
      final unitStr = phoenixMatch.group(3)?.toLowerCase() ?? 'kg';

      double rawVal = double.tryParse(valStr) ?? 0.0;
      double normalizedKg = unitStr == 'g' ? rawVal / 1000.0 : rawVal;

      return WeighingScaleReading(
        weightKg: normalizedKg < 0 ? 0.0 : normalizedKg,
        rawValue: rawVal,
        unit: unitStr == 'g' ? ScaleWeightUnit.g : ScaleWeightUnit.kg,
        isStable: true,
        isTare: mode == 'N',
        timestamp: DateTime.now(),
        rawData: raw,
      );
    }

    // 3. Try Toledo STX/ETX format (001.250)
    if (trimmed.contains('\x02') || trimmed.contains('\x03')) {
      final sanitized = trimmed.replaceAll('\x02', '').replaceAll('\x03', '').trim();
      final val = double.tryParse(sanitized);
      if (val != null) {
        return WeighingScaleReading(
          weightKg: val < 0 ? 0.0 : val,
          rawValue: val,
          isStable: true,
          timestamp: DateTime.now(),
          rawData: raw,
        );
      }
    }

    // 4. Try Simple Equals / Plus format (=01.250 or +001.250)
    final simpleMatch = _simpleEqualsRegex.firstMatch(trimmed);
    if (simpleMatch != null) {
      final sign = simpleMatch.group(1);
      final valStr = simpleMatch.group(2) ?? '0.0';
      final unitStr = simpleMatch.group(3)?.toLowerCase() ?? 'kg';

      double val = double.tryParse(valStr) ?? 0.0;
      if (sign == '-') val = -val;
      double normalizedKg = unitStr == 'g' ? val / 1000.0 : val;

      return WeighingScaleReading(
        weightKg: normalizedKg < 0 ? 0.0 : normalizedKg,
        rawValue: val,
        unit: unitStr == 'g' ? ScaleWeightUnit.g : ScaleWeightUnit.kg,
        isStable: true,
        timestamp: DateTime.now(),
        rawData: raw,
      );
    }

    // 5. Generic weight match (1.250kg or 500g)
    final genericMatch = _genericWeightRegex.firstMatch(trimmed);
    if (genericMatch != null) {
      final valStr = genericMatch.group(1) ?? '0.0';
      final unitStr = genericMatch.group(2)?.toLowerCase() ?? 'kg';

      double val = double.tryParse(valStr) ?? 0.0;
      double normalizedKg = unitStr == 'g' ? val / 1000.0 : val;

      return WeighingScaleReading(
        weightKg: normalizedKg < 0 ? 0.0 : normalizedKg,
        rawValue: val,
        unit: unitStr == 'g' ? ScaleWeightUnit.g : ScaleWeightUnit.kg,
        isStable: true,
        timestamp: DateTime.now(),
        rawData: raw,
      );
    }

    // 6. Direct numeric fallback
    final directVal = double.tryParse(trimmed);
    if (directVal != null) {
      return WeighingScaleReading(
        weightKg: directVal < 0 ? 0.0 : directVal,
        rawValue: directVal,
        isStable: true,
        timestamp: DateTime.now(),
        rawData: raw,
      );
    }

    return null;
  }
}
