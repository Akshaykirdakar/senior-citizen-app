import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';

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

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
      _card('स्त्री–पुरुष प्रमाण', Column(children: [
        _bar('पुरुष', male, total, AppColors.male),
        const SizedBox(height: 8),
        _bar('महिला', female, total, AppColors.female),
        const SizedBox(height: 8),
        Text('एकूण $total सभासद', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ])),
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
