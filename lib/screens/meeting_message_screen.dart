import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/member.dart';

class MeetingMessageScreen extends StatefulWidget {
  final List<Member> members;
  const MeetingMessageScreen({super.key, required this.members});
  @override
  State<MeetingMessageScreen> createState() => _MeetingMessageScreenState();
}

class _MeetingMessageScreenState extends State<MeetingMessageScreen> {
  late final TextEditingController _msg;
  bool _selective = false;
  final Set<String> _picked = {}; // member numbers

  // living members who have a mobile number
  late final List<Member> _eligible = widget.members
      .where((m) => !m.deceased && m.mobile.trim().isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _msg = TextEditingController(
      text: 'माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज\n\n'
          'सर्व सभासदांना कळविण्यात येते की, या रविवारी दुपारी ४:०० वा. '
          'स.मा. विद्यालय, अकलूज येथे मासिक सभा आयोजित केली आहे. '
          'आपण उपस्थित राहावे ही विनंती.\n\n– कार्यकारी मंडळ',
    );
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  List<Member> get _recipients =>
      _selective ? _eligible.where((m) => _picked.contains(m.memberNo)).toList() : _eligible;

  List<String> get _numbers => _recipients.map((m) => m.mobile.trim()).toList();

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.greenDeep));

  Future<void> _sendSms() async {
    if (_numbers.isEmpty) return _snack('कृपया किमान एक सभासद निवडा.');
    final uri = Uri.parse('sms:${_numbers.join(',')}?body=${Uri.encodeComponent(_msg.text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('SMS अ‍ॅप उघडता आले नाही.');
    }
  }

  Future<void> _whatsapp() async {
    if (_recipients.isEmpty) return _snack('कृपया किमान एक सभासद निवडा.');
    // WhatsApp opens one chat at a time; use the first recipient.
    var num = _numbers.first.replaceAll(RegExp(r'\D'), '');
    if (num.length == 10) num = '91$num';
    final uri = Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(_msg.text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('WhatsApp उघडता आले नाही.');
    } else if (_recipients.length > 1) {
      _snack('WhatsApp एका वेळी एकाच सभासदाला उघडते. मोठ्या गटासाठी SMS किंवा शेअर वापरा.');
    }
  }

  Future<void> _share() async {
    if (_recipients.isEmpty) return _snack('कृपया किमान एक सभासद निवडा.');
    await Share.share(_msg.text, subject: 'मिटींग मेसेज');
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _msg.text));
    _snack('मेसेज कॉपी झाला.');
  }

  @override
  Widget build(BuildContext context) {
    final count = _recipients.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: const Text('मिटींग मेसेज', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('मेसेज', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 6),
            TextField(
              controller: _msg,
              maxLines: 6,
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.card,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('कोणाला पाठवायचे?', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 6),
            Row(children: [
              _modeBtn('सर्व हयात सभासद', !_selective, () => setState(() => _selective = false)),
              const SizedBox(width: 10),
              _modeBtn('निवडक सभासद', _selective, () => setState(() => _selective = true)),
            ]),
            const SizedBox(height: 6),
            Text('मोबाईल असलेले हयात सभासद: ${_eligible.length} · निवडलेले: $count',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            if (_selective) ...[
              const SizedBox(height: 8),
              Row(children: [
                TextButton(onPressed: () => setState(() => _picked.addAll(_eligible.map((m) => m.memberNo))), child: const Text('सर्व निवडा')),
                TextButton(onPressed: () => setState(() => _picked.clear()), child: const Text('सर्व रद्द')),
              ]),
              ..._eligible.map((m) => CheckboxListTile(
                    dense: true,
                    activeColor: AppColors.green,
                    value: _picked.contains(m.memberNo),
                    onChanged: (v) => setState(() => v == true ? _picked.add(m.memberNo) : _picked.remove(m.memberNo)),
                    title: Text(m.name),
                    subtitle: Text('${m.mobile} · ${m.village}', style: const TextStyle(fontSize: 12)),
                  )),
            ],
          ]),
        ),
        // action bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: _sendSms,
                style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
                icon: const Icon(Icons.sms, size: 18), label: Text('SMS ($count)', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(
                onPressed: _whatsapp,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
                icon: const Icon(Icons.chat, size: 18), label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _share,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.line), minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.share, size: 18), label: const Text('शेअर'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: _copy,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.line), minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.copy, size: 18), label: const Text('कॉपी'),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _modeBtn(String label, bool on, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.green : AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? AppColors.green : AppColors.line),
            ),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: on ? Colors.white : AppColors.ink)),
          ),
        ),
      );
}
