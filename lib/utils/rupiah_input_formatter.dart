import 'package:flutter/services.dart';

/// InputFormatter untuk menampilkan pemisah ribuan ala Indonesia (titik) pada input angka.
/// Contoh: "1000000" -> "1.000.000". Dipakai bersama prefixText: 'Rp '.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hanya izinkan digit, abaikan karakter lain
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format menjadi ribuan bertitik
    final formatted = _formatThousands(digitsOnly);

    // Hitung offset caret yang baru dari belakang agar terasa natural
    int selectionIndexFromEnd = newValue.text.length - newValue.selection.end;
    final newText = formatted;
    int newSelection = newText.length - selectionIndexFromEnd;
    if (newSelection < 0) newSelection = 0;
    if (newSelection > newText.length) newSelection = newText.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelection),
    );
  }

  String _formatThousands(String input) {
    if (input.isEmpty) return '';
    // Hilangkan nol di depan berlebih (kecuali input hanya "0")
    input = input.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buffer = StringBuffer();

    // Balik string untuk memudahkan grouping per 3 dari belakang
    final reversed = input.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      buffer.write(reversed[i]);
      if ((i + 1) % 3 == 0 && (i + 1) != reversed.length) {
        buffer.write('.');
      }
    }

    // Balik lagi ke urutan normal
    return buffer.toString().split('').reversed.join();
  }
}