import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';

class BirthdaysScreen extends StatelessWidget {
  final List<Member> members;
  const BirthdaysScreen({super.key, required this.members});

  String _dm(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : iso;
  }

  String _when(int days) => days == 0 ? 'आज! 🎉' : days == 1 ? 'उद्या' : '$days दिवसांनी';

  @override
  Widget build(BuildContext context) {
    final list = members.where((m) => m.dob.isNotEmpty).toList()
      ..sort((a, b) => a.birthdayInDays.compareTo(b.birthdayInDays));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: const Text('वाढदिवस', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: list.isEmpty
          ? const Center(child: Text('जन्मतारीख असलेले सभासद नाहीत.', style: TextStyle(color: AppColors.muted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = list[i];
                final today = m.birthdayInDays == 0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: today ? AppColors.marigoldSoft : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: today ? AppColors.marigold : AppColors.line),
                  ),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: (m.photoPath != null && File(m.photoPath!).existsSync())
                          ? Image.file(File(m.photoPath!), fit: BoxFit.cover, width: 46, height: 46)
                          : const Icon(Icons.cake, color: AppColors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                        Text('${_dm(m.dob)} · वय ${m.turningAge} होणार · ${m.village}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_when(m.birthdayInDays),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: today ? AppColors.marigold : AppColors.green)),
                      if (m.mobile.isNotEmpty)
                        Text(m.mobile, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ]),
                );
              },
            ),
    );
  }
}
