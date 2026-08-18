import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/member.dart';

/// Renders the members list with Flutter's own text engine (which shapes
/// Marathi/Devanagari conjuncts perfectly), captures each page as an image,
/// and assembles those images into a PDF. This avoids the `pdf` package's
/// limited Devanagari shaping, so words no longer break.
class ReportPdf {
  static const _green = Color(0xFF14503C);
  static const _line = Color(0xFFB9B9B9);
  static const _ink = Color(0xFF22201B);
  static const _muted = Color(0xFF6B6A63);
  static const int _rowsPerPage = 16;

  static Future<void> membersList(List<Member> members,
      {String title = 'सभासद यादी'}) async {
    final total = members.length;
    final male = members.where((m) => m.gender == 'M').length;
    final fees = members.fold<int>(0, (s, m) => s + m.fee);
    final summary =
        'एकूण $total · पुरुष $male · महिला ${total - male} · जमा फी रु. $fees/–';

    // Split members into pages.
    final pages = <List<Member>>[];
    if (members.isEmpty) {
      pages.add(<Member>[]);
    } else {
      for (var i = 0; i < members.length; i += _rowsPerPage) {
        final end =
            (i + _rowsPerPage) > members.length ? members.length : i + _rowsPerPage;
        pages.add(members.sublist(i, end));
      }
    }

    // Capture each page widget as a PNG using Flutter's renderer.
    final controller = ScreenshotController();
    final images = <Uint8List>[];
    for (var p = 0; p < pages.length; p++) {
      final bytes = await controller.captureFromWidget(
        _pageWidget(title, summary, pages[p], p + 1, pages.length),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 30),
      );
      images.add(bytes);
    }

    // Assemble the images into a landscape A4 PDF.
    final doc = pw.Document();
    for (final img in images) {
      final memImg = pw.MemoryImage(img);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => pw.Center(child: pw.Image(memImg, fit: pw.BoxFit.contain)),
      ));
    }
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Widget _pageWidget(
      String title, String summary, List<Member> chunk, int page, int pages) {
    const headers = ['क्र.', 'नोंदणी', 'नाव', 'पत्ता', 'मोबाईल', 'वय', 'शेरा'];

    final rows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: _green),
        children: headers
            .map((h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Text(h,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                ))
            .toList(),
      ),
    ];
    for (final m in chunk) {
      rows.add(TableRow(children: [
        _cell(m.memberNo),
        _cell(m.regNo),
        _cell(m.name),
        _cell(m.fullAddress),
        _cell(m.mobile),
        _cell('${m.age}'),
        _cell(m.statusRemark),
      ]));
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: Container(
          width: 1700,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title — माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: _green)),
              const SizedBox(height: 6),
              Text(summary, style: const TextStyle(fontSize: 20, color: _muted)),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: _line, width: 1.2),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FixedColumnWidth(95),
                  1: FixedColumnWidth(120),
                  2: FlexColumnWidth(3.2),
                  3: FlexColumnWidth(4.6),
                  4: FixedColumnWidth(240),
                  5: FixedColumnWidth(70),
                  6: FlexColumnWidth(2.4),
                },
                children: rows,
              ),
              if (pages > 1) ...[
                const SizedBox(height: 12),
                Text('पान $page / $pages',
                    style: const TextStyle(fontSize: 16, color: _muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _cell(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(t, style: const TextStyle(fontSize: 22, color: _ink)),
      );
}
