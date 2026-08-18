import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';
import '../services/pdf_service.dart';
import '../services/report_pdf.dart';
import '../services/excel_service.dart';

class ReportsScreen extends StatelessWidget {
  final List<Member> members;
  const ReportsScreen({super.key, required this.members});

  Map<String, int> _count(String Function(Member) key) {
    final map = <String, int>{};
    for (final m in members) {
      final k = key(m).isEmpty ? '—' : key(m);
      map[k] = (map[k] ?? 0) + 1;
    }
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    final total = members.length;
    final male = members.where((m) => m.gender == 'M').length;
    final female = total - male;
    final social = members.where((m) => m.social).length;
    final feeM = male * Member.feeMale;
    final feeF = female * Member.feeFemale;

    final ageOrder = ['६०–६४', '६५–६९', '७०–७४', '७५–७९', '८०–८४', '८५+', '६० खाली'];
    final ageMap = <String, int>{};
    for (final b in ageOrder) {
      final c = members.where((m) => m.ageBand == b).length;
      if (c > 0) ageMap[b] = c;
    }

    final alive = members.where((m) => !m.deceased).toList();
    final dead = members.where((m) => m.deceased).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
      _card('याद्या एक्सपोर्ट (PDF / Excel)', Column(children: [
        _expRow('एकूण यादी', members, 'एकूण-सभासद'),
        _expRow('हयात यादी', alive, 'हयात-सभासद'),
        _expRow('मयत यादी', dead, 'मयत-सभासद'),
      ])),
      _card('हयात / मयत', Column(children: [
        _bar('हयात', alive.length, members.length, AppColors.green),
        const SizedBox(height: 8),
        _bar('मयत', dead.length, members.length, AppColors.danger),
      ])),
      _card('स्त्री–पुरुष प्रमाण', Column(children: [
        _bar('पुरुष', male, total, AppColors.male),
        const SizedBox(height: 8),
        _bar('महिला', female, total, AppColors.female),
        const SizedBox(height: 8),
        Text('एकूण $total सभासद', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ])),
      _card('गावानुसार सभासद', _bars(_count((m) => m.village), total, AppColors.green)),
      _VillageReport(members: members),
      _card('वयोगटानुसार सभासद', _bars(ageMap, total, AppColors.green)),
      _card('शिक्षणानुसार', _bars(_count((m) => m.education), total, AppColors.marigold)),
      _card('व्यवसायानुसार', _bars(_count((m) => m.occupation), total, AppColors.male)),
      _card('समाजकार्याची आवड', Row(children: [
        const Icon(Icons.volunteer_activism, color: AppColors.green),
        const SizedBox(width: 8),
        const Expanded(child: Text('आवड असणारे सभासद', style: TextStyle(fontSize: 14, color: AppColors.ink))),
        Text('$social', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.green)),
        Text(' / $total', style: const TextStyle(color: AppColors.muted)),
      ])),
      _card('जमा प्रवेश फी', Column(children: [
        _feeRow('पुरुष ($male × रु.551)', feeM, AppColors.male),
        const SizedBox(height: 6),
        _feeRow('महिला ($female × रु.261)', feeF, AppColors.female),
        const Divider(color: AppColors.line, height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('एकूण', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
          Text('रु. ${feeM + feeF}/–', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
        ]),
      ])),
    ]);
  }

  Widget _expRow(String label, List<Member> list, String fname) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text('$label (${list.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink))),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.marigold),
            onPressed: list.isEmpty ? null : () => ReportPdf.membersList(list, title: label),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.grid_on, color: AppColors.green),
            onPressed: list.isEmpty ? null : () => ExcelService.export(list, filename: fname),
          ),
        ]),
      );

  Widget _card(String title, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _bars(Map<String, int> data, int total, Color color) {
    if (data.isEmpty) return const Text('माहिती नाही', style: TextStyle(color: AppColors.muted));
    final max = data.values.reduce((a, b) => a > b ? a : b);
    return Column(children: [
      for (final e in data.entries) ...[
        _bar(e.key, e.value, max, color),
        const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _bar(String label, int value, int max, Color color) {
    final frac = max == 0 ? 0.0 : value / max;
    return Row(children: [
      SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.ink))),
      Expanded(
        child: Stack(children: [
          Container(height: 22, decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(6))),
          FractionallySizedBox(
            widthFactor: frac.clamp(0.04, 1.0),
            child: Container(height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      SizedBox(width: 24, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.muted))),
    ]);
  }

  Widget _feeRow(String label, int amount, Color color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        Text('रु. $amount', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]);
}


class _VillageReport extends StatefulWidget {
  final List<Member> members;
  const _VillageReport({required this.members});
  @override
  State<_VillageReport> createState() => _VillageReportState();
}

class _VillageReportState extends State<_VillageReport> {
  String? _v;
  @override
  Widget build(BuildContext context) {
    final villages = widget.members.map((m) => m.village).where((x) => x.isNotEmpty).toSet().toList()..sort();
    final list = widget.members.where((m) => m.village == _v).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('स्वतंत्र गावाचा रिपोर्ट', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _v,
          isExpanded: true,
          hint: const Text('गाव निवडा'),
          decoration: InputDecoration(
            isDense: true, filled: true, fillColor: AppColors.cream,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green)),
          ),
          items: villages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (x) => setState(() => _v = x),
        ),
        if (_v != null) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text('$_v — ${list.length} सभासद', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink))),
            const SizedBox(width: 6),
            Wrap(spacing: 6, children: [
              FilledButton.icon(
                onPressed: () => ReportPdf.membersList(list, title: '$_v गाव — सभासद यादी'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.marigold, foregroundColor: const Color(0xFF3A2400), visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
              ),
              FilledButton.icon(
                onPressed: () => ExcelService.export(list, filename: '$_v-सभासद'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.grid_on, size: 16),
                label: const Text('Excel'),
              ),
            ]),
          ]),
          const SizedBox(height: 8),
          for (final m in list)
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.ink)),
                    Text(m.fullAddress, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
                Text(m.mobile, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
              ]),
            ),
        ],
      ]),
    );
  }
}
