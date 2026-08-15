import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';

class HomeScreen extends StatelessWidget {
  final List<Member> members;
  final VoidCallback onAdd;
  final ValueChanged<int> onGoTab;
  const HomeScreen({super.key, required this.members, required this.onAdd, required this.onGoTab});

  @override
  Widget build(BuildContext context) {
    final total = members.length;
    final male = members.where((m) => m.gender == 'M').length;
    final female = total - male;
    final fees = members.fold<int>(0, (s, m) => s + m.fee);
    final now = DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final thisMonth = members.where((m) => m.joinDate.startsWith(ym)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const Text('|| ज्येष्ठ आम्ही ज्येष्ठच राहू ||',
            style: TextStyle(color: AppColors.marigold, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 2),
        const Text('नमस्कार, कार्यालय 🙏',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('एकूण सभासद', '$total', AppColors.green),
          const SizedBox(width: 12),
          _stat('या महिन्यात नवीन', '$thisMonth', AppColors.marigold),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('पुरुष', '$male', AppColors.male),
          const SizedBox(width: 12),
          _stat('महिला', '$female', AppColors.female),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('जमा प्रवेश फी (एकूण)',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('रु. $fees/–',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _quick(Icons.groups, 'सभासद यादी', () => onGoTab(1)),
          const SizedBox(width: 12),
          _quick(Icons.bar_chart, 'अहवाल', () => onGoTab(2)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.marigoldSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.marigold.withOpacity(0.35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Icon(Icons.notifications, color: AppColors.marigold, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'सभेची आठवण: प्रत्येक महिन्याच्या पहिल्या रविवारी दुपारी ४:०० वा. स.मा. विद्यालय, अकलूज येथे सर्व सभासदांची सभा.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.ink),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
          ]),
        ),
      );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              Icon(icon, color: AppColors.green, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ]),
          ),
        ),
      );
}
