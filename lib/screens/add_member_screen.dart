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
  const AddMemberScreen({super.key});
  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{
    for (final k in ['name', 'addr', 'mob', 'cmob', 'edu', 'occ', 'receipt', 'eName', 'eMob', 'eAddr', 'doctor'])
      k: TextEditingController(),
  };
  String _gender = 'M';
  bool _social = true;
  DateTime? _dob;
  DateTime _join = DateTime.now();
  String? _photoPath;
  String _memberNo = '----';

  @override
  void initState() {
    super.initState();
    MemberRepo.instance.nextMemberNo().then((n) => setState(() => _memberNo = n));
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
      address: _c['addr']!.text.trim(),
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
    await MemberRepo.instance.insert(m);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('नवीन सभासद — प्रवेश अर्ज', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
          _text('addr', '२. संपूर्ण पत्ता', lines: 2, hint: 'मु.पो. ..., ता. माळशिरस, जि. सोलापूर'),
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
            label: const Text('सभासद जतन करा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ]),
      ),
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
