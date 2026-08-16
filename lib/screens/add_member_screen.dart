import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme.dart';
import '../models/member.dart';
import '../data/member_repo.dart';

class AddMemberScreen extends StatefulWidget {
  final Member? existing;
  const AddMemberScreen({super.key, this.existing});
  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{
    for (final k in ['name', 'area', 'mob', 'cmob', 'edu', 'occ', 'receipt', 'eName', 'eMob', 'eAddr', 'doctor'])
      k: TextEditingController(),
  };
  String _gender = 'M';
  bool _social = true;
  DateTime? _dob;
  DateTime _join = DateTime.now();
  String? _photoPath;
  String _memberNo = '----';
  String? _village;
  String? _taluka = 'माळशिरस';
  String? _district = 'सोलापूर';
  List<Map<String, String>> _villageObjs = [];
  List<String> _talukas = [];
  List<String> _districts = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _memberNo = e.memberNo;
      _gender = e.gender;
      _social = e.social;
      _photoPath = e.photoPath;
      _village = e.village.isEmpty ? null : e.village;
      _taluka = e.taluka.isEmpty ? null : e.taluka;
      _district = e.district.isEmpty ? null : e.district;
      _dob = e.dob.isEmpty ? null : DateTime.tryParse(e.dob);
      _join = e.joinDate.isEmpty ? DateTime.now() : (DateTime.tryParse(e.joinDate) ?? DateTime.now());
      _c['name']!.text = e.name;
      _c['area']!.text = e.area;
      _c['mob']!.text = e.mobile;
      _c['cmob']!.text = e.contactMobile;
      _c['edu']!.text = e.education;
      _c['occ']!.text = e.occupation;
      _c['receipt']!.text = e.receiptNo;
      _c['eName']!.text = e.emName;
      _c['eMob']!.text = e.emMobile;
      _c['eAddr']!.text = e.emAddress;
      _c['doctor']!.text = e.doctor;
    } else {
      MemberRepo.instance.nextMemberNo().then((n) => setState(() => _memberNo = n));
    }
    _loadMasters();
  }

  Future<void> _loadMasters() async {
    final vObjs = await MemberRepo.instance.villageMasters();
    final t = await MemberRepo.instance.masters('taluka');
    final d = await MemberRepo.instance.masters('district');
    if (mounted) setState(() { _villageObjs = vObjs; _talukas = t; _districts = d; });
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
      final name = nameC.text.trim();
      await MemberRepo.instance.addVillageMaster(name, tk, dt);
      _villageObjs = await MemberRepo.instance.villageMasters();
      setState(() { _village = name; _taluka = tk; _district = dt; });
    }
  }

  Future<void> _addMasterSimple(String cat, void Function(String) select) async {
    final ctrl = TextEditingController();
    final title = cat == 'village' ? 'नवीन गाव' : cat == 'taluka' ? 'नवीन तालुका' : 'नवीन जिल्हा';
    final val = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'नाव लिहा')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('रद्द')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('जोडा')),
        ],
      ),
    );
    if (val != null && val.isNotEmpty) {
      await MemberRepo.instance.addMaster(cat, val);
      final list = await MemberRepo.instance.masters(cat);
      setState(() {
        if (cat == 'taluka') _talukas = list;
        else _districts = list;
        select(val);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) c.dispose();
    super.dispose();
  }

  String _iso(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmt(DateTime? d) => d == null ? 'निवडा' : '${d.day}/${d.month}/${d.year}';

  Future<void> _pickPhoto(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 800, imageQuality: 80);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(x.path).copy(dest);
    setState(() => _photoPath = dest);
  }

  void _photoSheet() => showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('कॅमेरा'), onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('गॅलरी'), onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); }),
          ]),
        ),
      );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final m = Member(
      memberNo: _memberNo,
      gender: _gender,
      name: _c['name']!.text.trim(),
      area: _c['area']!.text.trim(),
      village: _village ?? '',
      taluka: _taluka ?? '',
      district: _district ?? '',
      dob: _iso(_dob),
      mobile: _c['mob']!.text.trim(),
      contactMobile: _c['cmob']!.text.trim(),
      education: _c['edu']!.text.trim(),
      occupation: _c['occ']!.text.trim(),
      receiptNo: _c['receipt']!.text.trim(),
      joinDate: _iso(_join),
      social: _social,
      emName: _c['eName']!.text.trim(),
      emMobile: _c['eMob']!.text.trim(),
      emAddress: _c['eAddr']!.text.trim(),
      doctor: _c['doctor']!.text.trim(),
      photoPath: _photoPath,
    );
    if (widget.existing != null) {
      m.id = widget.existing!.id;
      await MemberRepo.instance.update(m);
    } else {
      await MemberRepo.instance.insert(m);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.existing != null ? 'सभासद माहिती एडिट' : 'नवीन सभासद — प्रवेश अर्ज', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text('आजीव सभासद क्रमांक: #$_memberNo', style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          // photo
          Row(children: [
            GestureDetector(
              onTap: _photoSheet,
              child: Container(
                width: 84,
                height: 100,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, style: BorderStyle.solid, width: 1.5),
                ),
                child: _photoPath == null
                    ? const Icon(Icons.person, size: 34, color: AppColors.line)
                    : Image.file(File(_photoPath!), fit: BoxFit.cover, width: 84, height: 100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('सभासद फोटो', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                const Text('कॅमेरा किंवा गॅलरीतून निवडा', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _photoSheet,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.greenSoft, foregroundColor: AppColors.green),
                  child: Text(_photoPath == null ? 'फोटो जोडा' : 'फोटो बदला'),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),

          _label('सभासद प्रकार · फी आपोआप ठरते'),
          Row(children: [
            _genderBtn('M', 'पुरुष', 'रु. 551/–', AppColors.male),
            const SizedBox(width: 10),
            _genderBtn('F', 'महिला', 'रु. 261/–', AppColors.female),
          ]),
          const SizedBox(height: 4),

          _text('name', '१. संपूर्ण नाव', required: true, hint: 'उदा. रामचंद्र गोविंद देशमुख'),
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 2),
            child: Align(alignment: Alignment.centerLeft, child: Text('२. पत्ता', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green))),
          ),
          _villageField(),
          Row(children: [
            Expanded(child: _masterField('तालुका', _taluka, _talukas, (v) => setState(() => _taluka = v), () => _addMasterSimple('taluka', (x) => _taluka = x))),
            const SizedBox(width: 12),
            Expanded(child: _masterField('जिल्हा', _district, _districts, (v) => setState(() => _district = v), () => _addMasterSimple('district', (x) => _district = x))),
          ]),
          _text('area', 'एरिया / भाग (ऐच्छिक)', hint: 'उदा. गांधी चौक / वॉर्ड'),
          Row(children: [
            Expanded(child: _text('mob', '३. मोबाईल नं.', number: true, required: true, phone: true)),
            const SizedBox(width: 12),
            Expanded(child: _text('cmob', 'संपर्क मोबाईल', number: true)),
          ]),
          Row(children: [
            Expanded(child: _dateField('४. जन्मतारीख', _dob, (d) => setState(() => _dob = d), dob: true)),
            const SizedBox(width: 12),
            Expanded(child: _text('edu', '५. शिक्षण', hint: '१० वी / पदवीधर')),
          ]),
          _text('occ', '६. व्यवसाय', hint: 'निवृत्त शिक्षक / शेती'),
          Row(children: [
            Expanded(child: _text('receipt', '७. पावती क्रमांक')),
            const SizedBox(width: 12),
            Expanded(child: _dateField('प्रवेश दिनांक', _join, (d) => setState(() => _join = d ?? _join))),
          ]),

          _label('८. समाजकार्याची आवड'),
          Row(children: [
            _toggle('आहे', _social, () => setState(() => _social = true)),
            const SizedBox(width: 10),
            _toggle('नाही', !_social, () => setState(() => _social = false)),
          ]),
          const SizedBox(height: 8),

          _label('९. आपत्कालीन संपर्क (अर्जदाराच्या व्यतिरिक्त)'),
          Row(children: [
            Expanded(child: _text('eName', 'नाव')),
            const SizedBox(width: 12),
            Expanded(child: _text('eMob', 'मोबाईल नं.', number: true)),
          ]),
          _text('eAddr', 'संपूर्ण पत्ता'),
          _text('doctor', '१०. फॅमिली डॉक्टरांचे नाव', hint: 'उदा. डॉ. कुलकर्णी'),

          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.marigold,
              foregroundColor: const Color(0xFF3A2400),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.save),
            label: Text(widget.existing != null ? 'बदल जतन करा' : 'सभासद जतन करा', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ]),
      ),
    );
  }

  Widget _villageField() {
    final names = _villageObjs.map((e) => e['name']!).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 2),
          child: Text('गावाचे नाव · निवडल्यास तालुका/जिल्हा आपोआप',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: names.contains(_village) ? _village : null,
              isExpanded: true,
              hint: const Text('गाव निवडा'),
              decoration: InputDecoration(
                isDense: true, filled: true, fillColor: AppColors.cream,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green)),
              ),
              items: names.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                if (v == null) return;
                final obj = _villageObjs.firstWhere((e) => e['name'] == v, orElse: () => <String, String>{});
                setState(() {
                  _village = v;
                  if ((obj['taluka'] ?? '').isNotEmpty) _taluka = obj['taluka'];
                  if ((obj['district'] ?? '').isNotEmpty) _district = obj['district'];
                });
              },
              validator: (v) => (v == null || v.isEmpty) ? 'निवडा' : null,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _addVillage,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: AppColors.green),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _masterField(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged, VoidCallback onAdd, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: const Text('निवडा'),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.cream,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green)),
              ),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
              validator: required ? (v) => (v == null || v.isEmpty) ? 'निवडा' : null : null,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: AppColors.green),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 0, 8),
        child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink))),
      );

  Widget _genderBtn(String v, String label, String fee, Color color) {
    final on = _gender == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? color : AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? color : AppColors.line),
          ),
          child: Column(children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.ink)),
            Text('$fee प्रवेश फी सहीत', style: TextStyle(fontSize: 11, color: on ? Colors.white70 : AppColors.muted)),
          ]),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool on, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.green : AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? AppColors.green : AppColors.line),
            ),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.ink)),
          ),
        ),
      );

  Widget _text(String key, String label,
      {bool required = false, bool number = false, bool phone = false, int lines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
        TextFormField(
          controller: _c[key],
          maxLines: lines,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : null,
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) return 'हे भरा';
            if (phone && !(RegExp(r'^\d{10}$').hasMatch(v ?? ''))) return '१० अंकी नंबर';
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: AppColors.cream,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green)),
          ),
        ),
      ]),
    );
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime?> onPick, {bool dob = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? (dob ? DateTime(1955) : now),
              firstDate: DateTime(1930),
              lastDate: now,
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              const Icon(Icons.event, size: 18, color: AppColors.green),
              const SizedBox(width: 8),
              Text(_fmt(value), style: const TextStyle(color: AppColors.ink)),
            ]),
          ),
        ),
      ]),
    );
  }
}
