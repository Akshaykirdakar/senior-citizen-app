import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/member.dart';

/// Exports members to a real .xlsx file and opens the share sheet.
class ExcelService {
  static Future<void> export(List<Member> members, {String filename = 'सभासद-यादी'}) async {
    final excel = Excel.createExcel();
    final sheet = excel['सभासद'];
    excel.setDefaultSheet('सभासद');

    const headers = [
      'क्र.', 'सभासद क्र.', 'नाव', 'लिंग', 'वय', 'मोबाईल', 'संपर्क मोबाईल',
      'एरिया', 'गाव', 'तालुका', 'जिल्हा', 'जन्मतारीख', 'शिक्षण', 'व्यवसाय',
      'प्रवेश फी', 'पावती क्र.', 'प्रवेश दिनांक', 'समाजकार्य',
      'आपत्कालीन नाव', 'आपत्कालीन मोबाईल', 'फॅमिली डॉक्टर',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < members.length; i++) {
      final m = members[i];
      sheet.appendRow(<CellValue?>[
        TextCellValue('${i + 1}'),
        TextCellValue(m.memberNo),
        TextCellValue(m.name),
        TextCellValue(m.genderLabel),
        TextCellValue('${m.age}'),
        TextCellValue(m.mobile),
        TextCellValue(m.contactMobile),
        TextCellValue(m.area),
        TextCellValue(m.village),
        TextCellValue(m.taluka),
        TextCellValue(m.district),
        TextCellValue(m.dob),
        TextCellValue(m.education),
        TextCellValue(m.occupation),
        TextCellValue('${m.fee}'),
        TextCellValue(m.receiptNo),
        TextCellValue(m.joinDate),
        TextCellValue(m.social ? 'आहे' : 'नाही'),
        TextCellValue(m.emName),
        TextCellValue(m.emMobile),
        TextCellValue(m.doctor),
      ]);
    }

    // remove the auto-created default sheet if separate
    if (excel.sheets.keys.contains('Sheet1') && excel.sheets.length > 1) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$filename.xlsx';
    File(path).writeAsBytesSync(bytes);
    await Share.shareXFiles([XFile(path)], text: 'सभासद यादी — माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज');
  }
}
