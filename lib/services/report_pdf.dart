import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/member.dart';

/// Renders the members list with Flutter's own text engine (perfect Marathi
/// conjunct shaping), captures each page as an image at a FIXED large canvas
/// size, and assembles the images into a PDF. Because the canvas size is fixed
/// (not the phone width), the table columns stay wide and words don't break.
class ReportPdf {
  static const _green = Color(0xFF14503C);
  static const _line = Color(0xFFB9B9B9);
  static const _ink = Color(0xFF22201B);
  static const _muted = Color(0xFF6B6A63);

  static const double _canvasW = 1600;
  static const double _canvasH = 1130; // A4-landscape aspect ~1.414
  static const int _rowsPerPage = 12;

  static Future<void> membersList(List<Member> members,
      {String title = 'सभासद यादी'}) async {
    final total = members.length;
    final male = members.where((m) => m.gender == 'M').length;
    final fees = members.fold<int>(0, (s, m) => s + m.fee);
    final summary =
        'एकूण $total · पुरुष $male · महिला ${total - male} · जमा फी रु. $fees/–';

    final pages = <List<Member>>[];
    if (members.isEmpty) {
      pages.add(<Member>[]);
    } else {
      for (var i = 0; i < members.length; i += _rowsPerPage) {
        final end = (i + _rowsPerPage) > members.length
            ? members.length
            : i + _rowsPerPage;
        pages.add(members.sublist(i, end));
      }
    }

    final controller = ScreenshotController();
    final images = <Uint8List>[];
    for (var p = 0; p < pages.length; p++) {
      final bytes = await controller.captureFromWidget(
        _pageWidget(title, summary, pages[p], p + 1, pages.length),
        pixelRatio: 1.6,
        targetSize: const Size(_canvasW, _canvasH),
        delay: const Duration(milliseconds: 40),
      );
      images.add(bytes);
    }

    final doc = pw.Document();
    for (final img in images) {
      final memImg = pw.MemoryImage(img);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (_) => pw.Center(child: pw.Image(memImg, fit: pw.BoxFit.contain)),
      ));
    }
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Widget _pageWidget(
      String title, String summary, List<Member> chunk, int page, int pages) {
    const headers = ['क्र.', 'नोंदणी', 'नाव', 'पत्ता', 'मोबाईल', 'वय', 'शेरा'];

    Widget cell(String t, {bool header = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            t,
            style: TextStyle(
              fontSize: header ? 21 : 20,
              height: 1.2,
              color: header ? Colors.white : _ink,
              fontWeight: header ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );

    final rows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: _green),
        children: headers.map((h) => cell(h, header: true)).toList(),
      ),
    ];
    for (final m in chunk) {
      rows.add(TableRow(children: [
        cell(m.memberNo),
        cell(m.regNo),
        cell(m.name),
        cell(m.fullAddress),
        cell(m.mobile),
        cell('${m.age}'),
        cell(m.statusRemark),
      ]));
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: _canvasW,
            height: _canvasH,
            child: Padding(
              padding: const EdgeInsets.all(34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title — माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold, color: _green),
                  ),
                  const SizedBox(height: 6),
                  Text(summary,
                      style: const TextStyle(fontSize: 19, color: _muted)),
                  const SizedBox(height: 16),
                  Table(
                    border: TableBorder.all(color: _line, width: 1.1),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(95),
                      1: FixedColumnWidth(120),
                      2: FlexColumnWidth(3.2),
                      3: FlexColumnWidth(4.6),
                      4: FixedColumnWidth(230),
                      5: FixedColumnWidth(70),
                      6: FlexColumnWidth(2.4),
                    },
                    children: rows,
                  ),
                  const Spacer(),
                  if (pages > 1)
                    Text('पान $page / $pages',
                        style: const TextStyle(fontSize: 15, color: _muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
