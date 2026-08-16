/// A single सभासद (member) record, mirroring the प्रवेश अर्ज fields.
class Member {
  int? id;
  String memberNo; // आजीव सभासद क्रमांक (auto, editable)
  String regNo; // नोंदणी क्रमांक
  String gender; // 'M' पुरुष / 'F' महिला
  String name; // संपूर्ण नाव
  String area; // एरिया / भाग
  String village; // गावाचे नाव
  String taluka; // तालुका
  String district; // जिल्हा
  String dob; // जन्मतारीख (ISO yyyy-MM-dd)
  String mobile; // मोबाईल नं.
  String contactMobile; // संपर्क मोबाईल नं.
  String education; // शिक्षण
  String occupation; // व्यवसाय
  String receiptNo; // पावती क्रमांक
  String joinDate; // प्रवेश दिनांक (ISO)
  bool social; // समाजकार्याची आवड
  bool deceased; // मयत
  String deathDate; // मयत तारीख (ISO)
  String emName; // आपत्कालीन संपर्क - नाव
  String emMobile; // आपत्कालीन संपर्क - मोबाईल
  String emAddress; // आपत्कालीन संपर्क - पत्ता
  String doctor; // फॅमिली डॉक्टर
  String? photoPath; // सभासद फोटो (local file path)

  Member({
    this.id,
    required this.memberNo,
    this.regNo = '',
    required this.gender,
    required this.name,
    this.area = '',
    this.village = '',
    this.taluka = 'माळशिरस',
    this.district = 'सोलापूर',
    this.dob = '',
    this.mobile = '',
    this.contactMobile = '',
    this.education = '',
    this.occupation = '',
    this.receiptNo = '',
    this.joinDate = '',
    this.social = true,
    this.deceased = false,
    this.deathDate = '',
    this.emName = '',
    this.emMobile = '',
    this.emAddress = '',
    this.doctor = '',
    this.photoPath,
  });

  static const int feeMale = 551;
  static const int feeFemale = 261;

  int get fee => gender == 'M' ? feeMale : feeFemale;
  String get genderLabel => gender == 'M' ? 'पुरुष' : 'महिला';

  String get deathDateFmt {
    if (deathDate.isEmpty) return '';
    final p = deathDate.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : deathDate;
  }
  String get statusRemark => deceased ? ('मयत ' + deathDateFmt).trim() : 'हयात';

  String get fullAddress {
    final parts = <String>[];
    if (area.isNotEmpty) parts.add(area);
    if (village.isNotEmpty) parts.add(village);
    var s = parts.join(', ');
    if (taluka.isNotEmpty) s += (s.isEmpty ? '' : ', ') + 'ता. ' + taluka;
    if (district.isNotEmpty) s += (s.isEmpty ? '' : ', ') + 'जि. ' + district;
    return s.isEmpty ? '—' : s;
  }

  int get age {
    if (dob.isEmpty) return 0;
    final d = DateTime.tryParse(dob);
    if (d == null) return 0;
    final n = DateTime.now();
    var a = n.year - d.year;
    if (n.month < d.month || (n.month == d.month && n.day < d.day)) a--;
    return a;
  }

  DateTime? get _dobDate => dob.isEmpty ? null : DateTime.tryParse(dob);

  /// Days until the next birthday (0 = today).
  int get birthdayInDays {
    final d = _dobDate;
    if (d == null) return 99999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, d.month, d.day);
    if (next.isBefore(today)) next = DateTime(now.year + 1, d.month, d.day);
    return next.difference(today).inDays;
  }

  /// Age they turn on the next birthday.
  int get turningAge {
    final d = _dobDate;
    if (d == null) return 0;
    final now = DateTime.now();
    var yr = now.year;
    final passed = DateTime(now.year, d.month, d.day).isBefore(DateTime(now.year, now.month, now.day));
    if (passed) yr = now.year + 1;
    return yr - d.year;
  }

  String get ageBand {
    final a = age;
    if (a < 60) return '६० खाली';
    if (a < 65) return '६०–६४';
    if (a < 70) return '६५–६९';
    if (a < 75) return '७०–७४';
    if (a < 80) return '७५–७९';
    if (a < 85) return '८०–८४';
    return '८५+';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'memberNo': memberNo,
        'regNo': regNo,
        'gender': gender,
        'name': name,
        'area': area,
        'village': village,
        'taluka': taluka,
        'district': district,
        'dob': dob,
        'mobile': mobile,
        'contactMobile': contactMobile,
        'education': education,
        'occupation': occupation,
        'receiptNo': receiptNo,
        'joinDate': joinDate,
        'social': social ? 1 : 0,
        'deceased': deceased ? 1 : 0,
        'deathDate': deathDate,
        'emName': emName,
        'emMobile': emMobile,
        'emAddress': emAddress,
        'doctor': doctor,
        'photoPath': photoPath,
      };

  factory Member.fromMap(Map<String, Object?> m) => Member(
        id: m['id'] as int?,
        memberNo: (m['memberNo'] ?? '') as String,
        regNo: (m['regNo'] ?? '') as String,
        gender: (m['gender'] ?? 'M') as String,
        name: (m['name'] ?? '') as String,
        area: (m['area'] ?? '') as String,
        village: (m['village'] ?? '') as String,
        taluka: (m['taluka'] ?? '') as String,
        district: (m['district'] ?? '') as String,
        dob: (m['dob'] ?? '') as String,
        mobile: (m['mobile'] ?? '') as String,
        contactMobile: (m['contactMobile'] ?? '') as String,
        education: (m['education'] ?? '') as String,
        occupation: (m['occupation'] ?? '') as String,
        receiptNo: (m['receiptNo'] ?? '') as String,
        joinDate: (m['joinDate'] ?? '') as String,
        social: (m['social'] ?? 1) == 1,
        deceased: (m['deceased'] ?? 0) == 1,
        deathDate: (m['deathDate'] ?? '') as String,
        emName: (m['emName'] ?? '') as String,
        emMobile: (m['emMobile'] ?? '') as String,
        emAddress: (m['emAddress'] ?? '') as String,
        doctor: (m['doctor'] ?? '') as String,
        photoPath: m['photoPath'] as String?,
      );
}
