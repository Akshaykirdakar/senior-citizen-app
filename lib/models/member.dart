/// A single सभासद (member) record, mirroring the प्रवेश अर्ज fields.
class Member {
  int? id;
  String memberNo; // आजीव सभासद क्रमांक
  String gender; // 'M' पुरुष / 'F' महिला
  String name; // संपूर्ण नाव
  String address; // संपूर्ण पत्ता
  String dob; // जन्मतारीख (ISO yyyy-MM-dd)
  String mobile; // मोबाईल नं.
  String contactMobile; // संपर्क मोबाईल नं.
  String education; // शिक्षण
  String occupation; // व्यवसाय
  String receiptNo; // पावती क्रमांक
  String joinDate; // प्रवेश दिनांक (ISO)
  bool social; // समाजकार्याची आवड
  String emName; // आपत्कालीन संपर्क - नाव
  String emMobile; // आपत्कालीन संपर्क - मोबाईल
  String emAddress; // आपत्कालीन संपर्क - पत्ता
  String doctor; // फॅमिली डॉक्टर
  String? photoPath; // सभासद फोटो (local file path)

  Member({
    this.id,
    required this.memberNo,
    required this.gender,
    required this.name,
    this.address = '',
    this.dob = '',
    this.mobile = '',
    this.contactMobile = '',
    this.education = '',
    this.occupation = '',
    this.receiptNo = '',
    this.joinDate = '',
    this.social = true,
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

  int get age {
    if (dob.isEmpty) return 0;
    final d = DateTime.tryParse(dob);
    if (d == null) return 0;
    final n = DateTime.now();
    var a = n.year - d.year;
    if (n.month < d.month || (n.month == d.month && n.day < d.day)) a--;
    return a;
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
        'gender': gender,
        'name': name,
        'address': address,
        'dob': dob,
        'mobile': mobile,
        'contactMobile': contactMobile,
        'education': education,
        'occupation': occupation,
        'receiptNo': receiptNo,
        'joinDate': joinDate,
        'social': social ? 1 : 0,
        'emName': emName,
        'emMobile': emMobile,
        'emAddress': emAddress,
        'doctor': doctor,
        'photoPath': photoPath,
      };

  factory Member.fromMap(Map<String, Object?> m) => Member(
        id: m['id'] as int?,
        memberNo: (m['memberNo'] ?? '') as String,
        gender: (m['gender'] ?? 'M') as String,
        name: (m['name'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        dob: (m['dob'] ?? '') as String,
        mobile: (m['mobile'] ?? '') as String,
        contactMobile: (m['contactMobile'] ?? '') as String,
        education: (m['education'] ?? '') as String,
        occupation: (m['occupation'] ?? '') as String,
        receiptNo: (m['receiptNo'] ?? '') as String,
        joinDate: (m['joinDate'] ?? '') as String,
        social: (m['social'] ?? 1) == 1,
        emName: (m['emName'] ?? '') as String,
        emMobile: (m['emMobile'] ?? '') as String,
        emAddress: (m['emAddress'] ?? '') as String,
        doctor: (m['doctor'] ?? '') as String,
        photoPath: m['photoPath'] as String?,
      );
}
