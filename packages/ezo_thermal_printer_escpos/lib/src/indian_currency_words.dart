class IndianCurrencyWordsFormatter {
  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String format(double amount) {
    if (amount <= 0) return 'Zero Rupees Only';

    final int integerPart = amount.toInt();
    final int decimalPart = ((amount - integerPart) * 100).round();

    final buffer = StringBuffer();
    final words = _convertToWords(integerPart);
    buffer.write(words.trim());
    buffer.write(' Rupees');

    if (decimalPart > 0) {
      buffer.write(' and ');
      buffer.write(_convertToWords(decimalPart).trim());
      buffer.write(' Paise');
    }

    buffer.write(' Only');
    return buffer.toString();
  }

  static String _convertToWords(int n) {
    if (n == 0) return '';
    if (n < 20) return '${_units[n]} ';
    if (n < 100) return '${_tens[n ~/ 10]} ${_units[n % 10]} ';
    if (n < 1000) return '${_units[n ~/ 100]} Hundred ${_convertToWords(n % 100)}';
    if (n < 100000) return '${_convertToWords(n ~/ 1000)}Thousand ${_convertToWords(n % 1000)}';
    if (n < 10000000) return '${_convertToWords(n ~/ 100000)}Lakh ${_convertToWords(n % 100000)}';
    return '${_convertToWords(n ~/ 10000000)}Crore ${_convertToWords(n % 10000000)}';
  }
}
