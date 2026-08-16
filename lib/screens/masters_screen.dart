import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/member_repo.dart';

/// Manage गाव (with तालुका/जिल्हा), plus तालुका and जिल्हा master lists.
class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});
  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> {
  List<Map<String, String>> _villages = [];
  List<String> _talukas = [];
  List<String> _districts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await MemberRepo.instance.villageMasters();
    final t = await MemberRepo.instance.masters('taluka');
    final d = await MemberRepo.instance.masters('district');
    if (mounted) setState(() {
      _villages = v; _talukas = t; _districts = d; _loading = false;
    });
  }

  Future<void> _addSimple(String cat) async {
    final ctrl = TextEditingController();
    final val = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('नवीन नाव जोडा'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'नाव लिहा')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('रद्द')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('जोडा')),
        ],
      ),
    );
    if (val != null && val.isNotEmpty) {
      await MemberRepo.instance.addMaster(cat, val);
      await _load();
    }
  }

  Future<void> _addVillage() async {
    final nameC = TextEditingController();
    String tk = _talukas.isNotEmpty ? _talukas.first : 'माळशिरस';
    String dt = _districts.isNotEmpty ? _districts.first : 'सोलापूर';
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('नवीन गाव'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, autofocus: true, decoration: const InputDecoration(hintText: 'गावाचे नाव')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _talukas.contains(tk) ? tk : null, isExpanded: true,
              decoration: const InputDecoration(labelText: 'तालुका'),
              items: _talukas.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setD(() => tk = v ?? tk),
            ),
            DropdownButtonFormField<String>(
              value: _districts.contains(dt) ? dt : null, isExpanded: true,
              decoration: const InputDecoration(labelText: 'जिल्हा'),
              items: _districts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setD(() => dt = v ?? dt),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('रद्द')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('जोडा')),
          ],
        ),
      ),
    );
    if (res == true && nameC.text.trim().isNotEmpty) {
      await MemberRepo.instance.addVillageMaster(nameC.text.trim(), tk, dt);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('गाव · तालुका · जिल्हा मास्टर', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text('गाव निवडल्यावर तालुका/जिल्हा आपोआप भरतो', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              _villageSection(),
              _strSection('तालुक्यांची यादी', 'taluka', _talukas),
              _strSection('जिल्ह्यांची यादी', 'district', _districts),
            ]),
    );
  }

  Widget _villageSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 6, left: 2),
        child: Text('गावांची यादी (${_villages.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          for (final v in _villages)
            ListTile(
              dense: true,
              title: Text(v['name'] ?? '', style: const TextStyle(color: AppColors.ink)),
              subtitle: Text('ता. ${v['taluka']} · जि. ${v['district']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                onPressed: () async { await MemberRepo.instance.removeVillageMaster(v['name'] ?? ''); await _load(); },
              ),
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add, color: AppColors.green),
            title: const Text('नवीन गाव जोडा', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
            onTap: _addVillage,
          ),
        ]),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _strSection(String title, String cat, List<String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 6, left: 2),
        child: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          for (final v in items)
            ListTile(
              dense: true,
              title: Text(v, style: const TextStyle(color: AppColors.ink)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                onPressed: () async { await MemberRepo.instance.removeMaster(cat, v); await _load(); },
              ),
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add, color: AppColors.green),
            title: const Text('नवीन जोडा', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
            onTap: () => _addSimple(cat),
          ),
        ]),
      ),
      const SizedBox(height: 12),
    ]);
  }
}
