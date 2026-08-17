import 'dart:io';
import 'package:characters/characters.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/member.dart';

/// Generates Marathi (Devanagari) PDFs. Embeds Noto Sans Devanagari so the
/// script renders correctly — the CI workflow downloads the .ttf into assets.
class PdfService {
  static pw.Font? _regular, _bold;

  static const _regUrl =
      'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/mukta/Mukta-Regular.ttf';
  static const _boldUrl =
      'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/mukta/Mukta-Bold.ttf';

  static Future<void> _loadFonts() async {
    if (_regular != null) return;

    // 1) Bundled Tiro Devanagari Marathi font (offline and preferred).
    // This is included in the APK and embedded directly into the PDF.
    try {
      _regular = pw.Font.ttf(
        await rootBundle.load(
          'assets/fonts/TiroDevanagariMarathi-Regular.ttf',
        ),
      );
      // Tiro Marathi regular is used for both weights when a separate bold
      // face is not bundled, preserving Marathi glyph coverage.
      _bold = _regular;
      return;
    } catch (_) {}

    // 2) Existing bundled fonts as a compatibility fallback.
    for (final base in [
      'Mukta-Regular.ttf',
      'NotoSansDevanagari-Regular.ttf',
    ]) {
      try {
        _regular = pw.Font.ttf(
          await rootBundle.load('assets/fonts/$base'),
        );
        final boldName = base.replaceAll('Regular', 'Bold');
        try {
          _bold = pw.Font.ttf(
            await rootBundle.load('assets/fonts/$boldName'),
          );
        } catch (_) {
          _bold = _regular;
        }
        return;
      } catch (_) {}
    }

    // 3) Existing runtime download fallback for older installations/builds.
    try {
      final reg = await http.get(Uri.parse(_regUrl));
      if (reg.statusCode == 200 && reg.bodyBytes.length > 5000) {
        _regular = pw.Font.ttf(ByteData.sublistView(reg.bodyBytes));
        try {
          final bol = await http.get(Uri.parse(_boldUrl));
          _bold = (bol.statusCode == 200 && bol.bodyBytes.length > 5000)
              ? pw.Font.ttf(ByteData.sublistView(bol.bodyBytes))
              : _regular;
        } catch (_) {
          _bold = _regular;
        }
        return;
      }
    } catch (_) {}

    // 4) Last resort for Latin-only text. Marathi should never reach this
    // path in a normal build because the Tiro font is bundled.
    _regular = pw.Font.helvetica();
    _bold = pw.Font.helveticaBold();
  }

  static const _green = PdfColor.fromInt(0xFF14503C);
  static const _marigold = PdfColor.fromInt(0xFFE29429);
  static const _line = PdfColor.fromInt(0xFFE7E1D3);
  static const _muted = PdfColor.fromInt(0xFF6B6A63);

  /// Single member identity card → opens the system print / save-as-PDF sheet.
  static Future<void> memberCard(Member m) async {
    await _loadFonts();
    final theme = pw.ThemeData.withFont(base: _regular, bold: _bold);
    final doc = pw.Document(theme: theme);

    pw.Widget row(String l, String v) => pw.Container(
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line))),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 150,
                child: pw.Text(l,
                    style: const pw.TextStyle(color: _muted, fontSize: 11))),
            pw.Expanded(
                child: pw.Text(v.isEmpty ? '—' : v,
                    style: const pw.TextStyle(fontSize: 12))),
          ]),
        );

    pw.Widget photo() {
      if (m.photoPath != null && File(m.photoPath!).existsSync()) {
        return pw.Container(
          width: 74,
          height: 88,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(6),
            image: pw.DecorationImage(
                image: pw.MemoryImage(File(m.photoPath!).readAsBytesSync()),
                fit: pw.BoxFit.cover),
          ),
        );
      }
      return pw.Container(
        width: 74,
        height: 88,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Text(m.name.isEmpty ? '?' : m.name.characters.first,
            style: pw.TextStyle(fontSize: 30, color: _green)),
      );
    }

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (_) => pw.Container(
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _green, width: 2),
            borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Container(
            color: _green,
            padding: const pw.EdgeInsets.all(14),
            child: pw.Row(children: [
              photo(),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(m.name,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 3),
                      pw.Text('वय ${m.age} वर्षे · ${m.genderLabel}',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 11)),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                            color: _marigold,
                            borderRadius: pw.BorderRadius.circular(20)),
                        child: pw.Text('आजीव सभासद #${m.memberNo}',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
              ),
            ]),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: pw.Column(children: [
              row('मोबाईल नं.', m.mobile),
              row('संपर्क मोबाईल', m.contactMobile),
              row('जन्मतारीख', _fmt(m.dob)),
              row('संपूर्ण पत्ता', m.fullAddress),
              row('शिक्षण', m.education),
              row('व्यवसाय', m.occupation),
              row('समाजकार्याची आवड', m.social ? 'आहे' : 'नाही'),
              row('नोंदणी क्रमांक', m.regNo),
              row('प्रवेश फी', 'रु. ${m.fee}/–'),
              row('पावती क्रमांक', m.receiptNo),
              row('प्रवेश दिनांक', _fmt(m.joinDate)),
              row('आपत्कालीन संपर्क', '${m.emName} · ${m.emMobile}'),
              row('फॅमिली डॉक्टर', m.doctor),
            ]),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
                'माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज · || ज्येष्ठ आम्ही ज्येष्ठच राहू ||',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ),
        ]),
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  /// Full members register as a printable table.
  static Future<void> membersList(List<Member> members, {String title = 'सभासद यादी'}) async {
    await _loadFonts();
    final theme = pw.ThemeData.withFont(base: _regular, bold: _bold);
    final doc = pw.Document(theme: theme);
    final total = members.length;
    final male = members.where((m) => m.gender == 'M').length;
    final fees = members.fold<int>(0, (s, m) => s + m.fee);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text('$title — माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
            'एकूण $total · पुरुष $male · महिला ${total - male} · जमा फी रु. $fees/–',
            style: const pw.TextStyle(fontSize: 11, color: _muted)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: _green),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          headers: ['क्र.', 'नोंदणी', 'नाव', 'पत्ता', 'मोबाईल', 'वय', 'शेरा'],
          data: members
              .map((m) => [
                    m.memberNo,
                    m.regNo,
                    m.name,
                    m.fullAddress,
                    m.mobile,
                    '${m.age}',
                    m.statusRemark,
                  ])
              .toList(),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    final parts = iso.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : iso;
  }
}
