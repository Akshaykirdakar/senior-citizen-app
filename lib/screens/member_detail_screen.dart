import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';
import '../data/member_repo.dart';
import '../services/pdf_service.dart';
import 'add_member_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  final Member member;
  final Future<void> Function() onChanged;
  const MemberDetailScreen({super.key, required this.member, required this.onChanged});

  String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  @override
  Widget build(BuildContext context) {
    final m = member;
    final isM = m.gender == 'M';
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          pinned: true,
          expandedHeight: 168,
          actions: [
            TextButton.icon(
              onPressed: () async {
                final ok = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => AddMemberScreen(existing: m)));
                if (ok == true && context.mounted) {
                  await onChanged();
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
              label: const Text('एडिट', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              onPressed: () => PdfService.memberCard(m),
              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF3A2400), size: 16),
              label: const Text('कार्ड PDF', style: TextStyle(color: Color(0xFF3A2400), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: AppColors.marigold),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: 64,
                    height: 76,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: (m.photoPath != null && File(m.photoPath!).existsSync())
                        ? Image.file(File(m.photoPath!), fit: BoxFit.cover, width: 64, height: 76)
                        : Text(m.name.isEmpty ? '?' : m.name.characters.first,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.marigold, borderRadius: BorderRadius.circular(20)),
                          child: Text('आजीव सभासद #${m.memberNo}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3A2400))),
                        ),
                        const SizedBox(width: 8),
                        Text('${m.age} वर्षे', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(children: [
              _card([
                _row(Icons.phone, 'मोबाईल नं.', m.mobile),
                if (m.contactMobile.isNotEmpty) _row(Icons.phone, 'संपर्क मोबाईल नं.', m.contactMobile),
                _row(Icons.cake, 'जन्मतारीख', '${_fmt(m.dob)}  (वय ${m.age})'),
                _row(Icons.location_on, 'संपूर्ण पत्ता', m.fullAddress),
                _row(Icons.school, 'शिक्षण', m.education),
                _row(Icons.work, 'व्यवसाय', m.occupation),
                _row(Icons.volunteer_activism, 'समाजकार्याची आवड', m.social ? 'आहे' : 'नाही'),
                _row(m.deceased ? Icons.sentiment_very_dissatisfied : Icons.favorite,
                    'सभासद स्थिती', m.deceased ? ('मयत · ' + m.deathDateFmt) : 'हयात'),
              ]),
              _section('सभासदत्व व फी'),
              _card([
                _row(Icons.confirmation_number, 'नोंदणी क्रमांक', m.regNo),
                _row(Icons.account_balance_wallet, 'प्रवेश फी', 'रु. ${m.fee}/– (${m.genderLabel})'),
                _row(Icons.receipt_long, 'पावती क्रमांक', m.receiptNo),
                _row(Icons.event, 'प्रवेश दिनांक', _fmt(m.joinDate)),
              ]),
              _section('आपत्कालीन संपर्क'),
              _card([
                _row(Icons.person, 'नाव', m.emName),
                _row(Icons.phone, 'मोबाईल नं.', m.emMobile),
                _row(Icons.location_on, 'पत्ता', m.emAddress),
                _row(Icons.medical_services, 'फॅमिली डॉक्टर', m.doctor),
              ]),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('सभासद काढायचा?'),
                      content: Text('${m.name} यांची नोंद कायमची काढली जाईल.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('रद्द')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('काढा', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  );
                  if (ok == true && m.id != null) {
                    await MemberRepo.instance.delete(m.id!);
                    await onChanged();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: const Text('सभासद काढा', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.green)),
        ),
      );

  Widget _card(List<Widget> rows) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(children: rows),
      );

  Widget _row(IconData icon, String label, String value) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              const SizedBox(height: 1),
              Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
            ]),
          ),
        ]),
      );
}
