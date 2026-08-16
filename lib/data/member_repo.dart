import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/member.dart';

/// Offline-first storage for members using SQLite (sqflite).
class MemberRepo {
  MemberRepo._();
  static final MemberRepo instance = MemberRepo._();
  static Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'sangh.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE members(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            memberNo TEXT, gender TEXT, name TEXT,
            dob TEXT, mobile TEXT, contactMobile TEXT, education TEXT,
            occupation TEXT, receiptNo TEXT, joinDate TEXT, social INTEGER,
            area TEXT, village TEXT, taluka TEXT, district TEXT,
            emName TEXT, emMobile TEXT, emAddress TEXT, doctor TEXT, photoPath TEXT
          )
        ''');
        for (final m in _seed) {
          await db.insert('members', m.toMap()..remove('id'));
        }
        await db.execute(
            'CREATE TABLE masters(id INTEGER PRIMARY KEY AUTOINCREMENT, cat TEXT, value TEXT)');
        for (final e in _masterSeed.entries) {
          for (final v in e.value) {
            await db.insert('masters', {'cat': e.key, 'value': v});
          }
        }
        await db.execute(
            'CREATE TABLE village_master(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, taluka TEXT, district TEXT)');
        for (final v in _villageSeed) {
          await db.insert('village_master', v);
        }
      },
    );
  }

  Future<List<Member>> all() async {
    final db = await _database;
    final rows = await db.query('members', orderBy: 'memberNo ASC');
    return rows.map(Member.fromMap).toList();
  }

  Future<int> insert(Member m) async {
    final db = await _database;
    return db.insert('members', m.toMap()..remove('id'));
  }

  Future<int> update(Member m) async {
    final db = await _database;
    return db.update('members', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  /// Next आजीव सभासद क्रमांक, zero-padded to 4 digits.
  Future<String> nextMemberNo() async {
    final db = await _database;
    final r = await db.rawQuery('SELECT COUNT(*) c FROM members');
    final count = Sqflite.firstIntValue(r) ?? 0;
    return (count + 1).toString().padLeft(4, '0');
  }


  Future<List<String>> masters(String cat) async {
    final db = await _database;
    final rows = await db.query('masters',
        where: 'cat = ?', whereArgs: [cat], orderBy: 'value ASC');
    return rows.map((r) => (r['value'] ?? '') as String).toList();
  }

  Future<void> addMaster(String cat, String value) async {
    final db = await _database;
    final existing = await masters(cat);
    if (existing.contains(value)) return;
    await db.insert('masters', {'cat': cat, 'value': value});
  }

  Future<void> removeMaster(String cat, String value) async {
    final db = await _database;
    await db.delete('masters', where: 'cat = ? AND value = ?', whereArgs: [cat, value]);
  }

  Future<List<Map<String, String>>> villageMasters() async {
    final db = await _database;
    final rows = await db.query('village_master', orderBy: 'name ASC');
    return rows
        .map((r) => {
              'name': (r['name'] ?? '') as String,
              'taluka': (r['taluka'] ?? '') as String,
              'district': (r['district'] ?? '') as String,
            })
        .toList();
  }

  Future<void> addVillageMaster(String name, String taluka, String district) async {
    final db = await _database;
    final existing = await db.query('village_master', where: 'name = ?', whereArgs: [name]);
    if (existing.isNotEmpty) {
      await db.update('village_master', {'taluka': taluka, 'district': district},
          where: 'name = ?', whereArgs: [name]);
    } else {
      await db.insert('village_master', {'name': name, 'taluka': taluka, 'district': district});
    }
  }

  Future<void> removeVillageMaster(String name) async {
    final db = await _database;
    await db.delete('village_master', where: 'name = ?', whereArgs: [name]);
  }

  static const Map<String, List<String>> _masterSeed = {
    'taluka': ['माळशिरस', 'पंढरपूर', 'सांगोला'],
    'district': ['सोलापूर'],
  };

  static const List<Map<String, String>> _villageSeed = [
    {'name': 'अकलूज', 'taluka': 'माळशिरस', 'district': 'सोलापूर'},
    {'name': 'नातेपुते', 'taluka': 'माळशिरस', 'district': 'सोलापूर'},
    {'name': 'वेळापूर', 'taluka': 'माळशिरस', 'district': 'सोलापूर'},
    {'name': 'पिळीव', 'taluka': 'माळशिरस', 'district': 'सोलापूर'},
    {'name': 'माळशिरस', 'taluka': 'माळशिरस', 'district': 'सोलापूर'},
  ];

  /// Export everything for a backup file.
  Future<Map<String, dynamic>> dumpAll() async {
    final db = await _database;
    final members = await db.query('members');
    final masters = await db.query('masters');
    final villages = await db.query('village_master');
    return {
      'app': 'senior_sangh',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'members': members,
      'masters': masters,
      'village_master': villages,
    };
  }

  /// Replace all data from a restored backup map.
  Future<void> replaceAllData(Map<String, dynamic> data) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('members');
      await txn.delete('masters');
      await txn.delete('village_master');
      for (final m in (data['members'] as List? ?? [])) {
        final row = Map<String, Object?>.from(m as Map);
        row.remove('id');
        await txn.insert('members', row);
      }
      for (final m in (data['masters'] as List? ?? [])) {
        final row = Map<String, Object?>.from(m as Map);
        row.remove('id');
        await txn.insert('masters', row);
      }
      for (final m in (data['village_master'] as List? ?? [])) {
        final row = Map<String, Object?>.from(m as Map);
        row.remove('id');
        await txn.insert('village_master', row);
      }
    });
  }

  static final List<Member> _seed = [
    Member(memberNo: '0001', gender: 'M', name: 'रामचंद्र गोविंद देशमुख', dob: '1948-06-12', village: 'अकलूज', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9822011234', contactMobile: '9822455678', education: 'बी.ए.', occupation: 'निवृत्त शिक्षक', receiptNo: '1201', joinDate: '2024-01-07', social: true, emName: 'प्रकाश देशमुख', emMobile: '9890012345', emAddress: 'अकलूज', doctor: 'डॉ. कुलकर्णी'),
    Member(memberNo: '0002', gender: 'F', name: 'सुनिता विठ्ठल पाटील', dob: '1953-03-22', village: 'नातेपुते', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9765043210', education: '१० वी', occupation: 'गृहिणी', receiptNo: '1202', joinDate: '2024-01-14', social: true, emName: 'अनिता पाटील', emMobile: '9765400011', emAddress: 'नातेपुते', doctor: 'डॉ. पवार'),
    Member(memberNo: '0003', gender: 'M', name: 'विठ्ठल तुकाराम जाधव', dob: '1945-11-02', village: 'वेळापूर', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9922033445', contactMobile: '9922100200', education: '७ वी', occupation: 'शेती', receiptNo: '1203', joinDate: '2024-02-04', social: false, emName: 'संजय जाधव', emMobile: '9922099887', emAddress: 'वेळापूर', doctor: 'डॉ. शहा'),
    Member(memberNo: '0004', gender: 'F', name: 'कमल श्रीराम कुलकर्णी', dob: '1958-07-19', village: 'अकलूज', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9403011122', education: 'एम.ए.', occupation: 'निवृत्त प्राध्यापक', receiptNo: '1204', joinDate: '2024-02-11', social: true, emName: 'राजेश कुलकर्णी', emMobile: '9403099001', emAddress: 'अकलूज', doctor: 'डॉ. कुलकर्णी'),
    Member(memberNo: '0005', gender: 'M', name: 'शंकरराव बाळू मोरे', dob: '1942-01-30', village: 'पिळीव', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9130044556', contactMobile: '9130044999', education: '४ थी', occupation: 'निवृत्त शेतकरी', receiptNo: '1205', joinDate: '2024-03-03', social: false, emName: 'मारुती मोरे', emMobile: '9130010101', emAddress: 'पिळीव', doctor: 'डॉ. पवार'),
    Member(memberNo: '0006', gender: 'F', name: 'लता दत्तात्रय शिंदे', dob: '1960-09-05', village: 'माळशिरस', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9975066778', education: '१२ वी', occupation: 'गृहिणी', receiptNo: '1206', joinDate: '2024-03-17', social: true, emName: 'स्वाती शिंदे', emMobile: '9975060606', emAddress: 'माळशिरस', doctor: 'डॉ. शहा'),
    Member(memberNo: '0007', gender: 'M', name: 'गणपत नामदेव माने', dob: '1950-04-14', village: 'अकलूज', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9822077889', contactMobile: '9822077000', education: 'पदवीधर', occupation: 'व्यापार', receiptNo: '1207', joinDate: '2024-04-07', social: true, emName: 'किरण माने', emMobile: '9822070707', emAddress: 'अकलूज', doctor: 'डॉ. कुलकर्णी'),
    Member(memberNo: '0008', gender: 'F', name: 'सिंधुताई रघुनाथ गायकवाड', dob: '1955-12-25', village: 'नातेपुते', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9689088990', education: 'अशिक्षित', occupation: 'गृहिणी', receiptNo: '1208', joinDate: '2024-05-05', social: true, emName: 'बाळासाहेब गायकवाड', emMobile: '9689080808', emAddress: 'नातेपुते', doctor: 'डॉ. पवार'),
    Member(memberNo: '0009', gender: 'M', name: 'दत्तात्रय आनंदा कदम', dob: '1947-08-08', village: 'वेळापूर', taluka: 'माळशिरस', district: 'सोलापूर', mobile: '9765099001', education: 'डी.एड.', occupation: 'निवृत्त शिक्षक', receiptNo: '1209', joinDate: '2024-06-02', social: false, emName: 'योगेश कदम', emMobile: '9765090909', emAddress: 'वेळापूर', doctor: 'डॉ. शहा'),
  ];
}
