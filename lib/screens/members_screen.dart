import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';
import 'member_detail_screen.dart';

class MembersScreen extends StatefulWidget {
  final List<Member> members;
  final Future<void> Function() onChanged;
  const MembersScreen({super.key, required this.members, required this.onChanged});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _q = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final list = widget.members.where((m) {
      if (_filter == 'M' && m.gender != 'M') return false;
      if (_filter == 'F' && m.gender != 'F') return false;
      if (_filter == 'social' && !m.social) return false;
      if (_q.isEmpty) return true;
      final s = _q.toLowerCase();
      return (m.name + m.memberNo + m.mobile + m.village).toLowerCase().contains(s);
    }).toList();

    final chips = [
      ['all', 'सर्व'],
      ['M', 'पुरुष'],
      ['F', 'महिला'],
      ['social', 'समाजकार्य'],
    ];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(children: [
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              hintText: 'नाव / क्रमांक / मोबाईल शोधा',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.green),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final c in chips)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c[1]),
                    selected: _filter == c[0],
                    onSelected: (_) => setState(() => _filter = c[0]),
                    selectedColor: AppColors.green,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(
                        color: _filter == c[0] ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    side: const BorderSide(color: AppColors.line),
                  ),
                ),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('${list.length} सभासद',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ),
      ),
      Expanded(
        child: list.isEmpty
            ? const Center(
                child: Text('या शोधात सभासद सापडले नाहीत.',
                    style: TextStyle(color: AppColors.muted)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _tile(context, list[i]),
              ),
      ),
    ]);
  }

  Widget _tile(BuildContext context, Member m) {
    final isM = m.gender == 'M';
    final tint = isM ? AppColors.male : AppColors.female;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MemberDetailScreen(member: m, onChanged: widget.onChanged)),
        );
        await widget.onChanged();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isM ? const Color(0xFFEAF1F8) : const Color(0xFFF8EAF1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: (m.photoPath != null && File(m.photoPath!).existsSync())
                ? Image.file(File(m.photoPath!), fit: BoxFit.cover, width: 46, height: 46)
                : Text(m.name.isEmpty ? '?' : m.name.characters.first,
                    style: TextStyle(color: tint, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
              const SizedBox(height: 2),
              Row(children: [
                Text('#${m.memberNo}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green)),
                Text('  · ${m.age} वर्षे  ', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: isM ? const Color(0xFFEAF1F8) : const Color(0xFFF8EAF1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(m.genderLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tint)),
                ),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: AppColors.green),
                Text(' ${m.village.isEmpty ? "—" : m.village}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 8),
                const Icon(Icons.phone, size: 12, color: AppColors.green),
                Text(' ${m.mobile}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
