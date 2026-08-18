import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/member.dart';
import 'data/member_repo.dart';
import 'services/pdf_service.dart';
import 'screens/home_screen.dart';
import 'screens/members_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/add_member_screen.dart';
import 'screens/masters_screen.dart';
import 'services/notification_service.dart';
import 'services/report_pdf.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const SanghApp());
}

class SanghApp extends StatelessWidget {
  const SanghApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ज्येष्ठ नागरिक संघ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  List<Member> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final data = await MemberRepo.instance.all();
    if (mounted) setState(() {
      _members = data;
      _loading = false;
    });
    NotificationService.syncBirthdayReminders(data);
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMemberScreen()),
    );
    if (saved == true) {
      await _reload();
      if (mounted) {
        setState(() => _tab = 1);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.greenDeep,
          content: Row(children: const [
            Icon(Icons.check_circle, color: Color(0xFF8FE3B8), size: 18),
            SizedBox(width: 8),
            Text('सभासद जतन झाला', style: TextStyle(color: Colors.white)),
          ]),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(members: _members, onAdd: _openAdd, onGoTab: (i) => setState(() => _tab = i), onDataChanged: _reload),
      MembersScreen(members: _members, onChanged: _reload),
      ReportsScreen(members: _members),
    ];
    final titles = ['मुख्य', 'सभासद', 'अहवाल'];

    return Scaffold(
      appBar: _tab == 0 ? _sanghAppBar() : AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: Text(titles[_tab], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: _tab == 1
            ? [
                IconButton(
                  tooltip: 'यादी PDF',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => ReportPdf.membersList(_members),
                )
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _tab, children: pages),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.marigold,
        foregroundColor: const Color(0xFF3A2400),
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('नवीन सभासद', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.greenSoft,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'मुख्य'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'सभासद'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'अहवाल'),
        ],
      ),
    );
  }

  PreferredSizeWidget _sanghAppBar() => AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
        actions: [
          IconButton(
            tooltip: 'गाव / तालुका / जिल्हा मास्टर',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MastersScreen())),
          ),
        ],
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
            ),
            child: const Text('🌳', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('माळशिरस तालुका ज्येष्ठ नागरिक संघ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                Text('अकलूज · स्थापना २३/०१/२००५',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ]),
      );
}
