import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_l10n_vernacular/ezo_l10n_vernacular.dart';

void main() {
  group('Vernacular Localization Tests', () {
    test('Resolves keys across all 10 supported Indian languages', () {
      final languages = [
        RegionalLanguage.en,
        RegionalLanguage.hi,
        RegionalLanguage.bn,
        RegionalLanguage.mr,
        RegionalLanguage.gu,
        RegionalLanguage.te,
        RegionalLanguage.ta,
        RegionalLanguage.kn,
        RegionalLanguage.ml,
        RegionalLanguage.pa,
      ];

      for (final lang in languages) {
        final posBilling = VernacularStrings.get('posBilling', language: lang);
        final grandTotal = VernacularStrings.get('grandTotal', language: lang);
        final youSaved = VernacularStrings.get('youSaved', language: lang);

        expect(posBilling.isNotEmpty, isTrue);
        expect(grandTotal.isNotEmpty, isTrue);
        expect(youSaved.isNotEmpty, isTrue);
      }

      // Check specific regional scripts
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.hi), equals('बिलिंग और पीओएस'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.bn), equals('বিলিং এবং পিওএস'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.mr), equals('बिलिंग आणि पीओएस'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.gu), equals('બિલિંગ અને પીઓએસ'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.te), equals('బిల్లింగ్ & పిఓఎస్'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.ta), equals('பில்லிங் மற்றும் பிஓஎஸ்'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.kn), equals('ಬಿಲ್ಲಿಂಗ್ ಮತ್ತು ಪಿಒಎಸ್'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.ml), equals('ബില്ലിംഗും പിഒഎസും'));
      expect(VernacularStrings.get('posBilling', language: RegionalLanguage.pa), equals('ਬਿਲਿੰਗ ਅਤੇ ਪੀਓਐਸ'));
    });

    test('LocaleController emits events on language change without restarting', () async {
      final controller = LocaleController();
      controller.setLanguage(RegionalLanguage.en);

      expect(controller.tr('grandTotal'), equals('Grand Total'));

      RegionalLanguage? updatedLang;
      final sub = controller.onLanguageChanged.listen((l) {
        updatedLang = l;
      });

      controller.setLanguage(RegionalLanguage.hi);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(updatedLang, equals(RegionalLanguage.hi));
      expect(controller.tr('grandTotal'), equals('कुल बिल राशि'));

      await sub.cancel();
    });
  });
}
