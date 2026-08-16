# माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज — सभासद अ‍ॅप

A Flutter (Android) app for the senior citizens' association membership register:
**data entry** (प्रवेश अर्ज), **member directory**, **reports**, **photo capture**, and
**PDF export** of member cards and the full members list. Works fully offline (SQLite).

## Features
- नवीन सभासद form with every field from the paper अर्ज; fee auto-set (पुरुष ₹551 / महिला ₹261) and auto member number.
- **Edit** any member — the detail screen's एडिट button reopens the form pre-filled and updates the record.
- **Structured address**: एरिया, गावाचे नाव, तालुका, जिल्हा. Picking a **village auto-fills its तालुका & जिल्हा** (still editable).
- **Masters** screen (गाव · तालुका · जिल्हा) — each village stores its taluka/district; add or remove entries; new ones can also be added inline from the form. Reached from the ⚙ icon on the home screen.
- Photo from camera or gallery, stored on-device.
- Searchable, filterable सभासद यादी (also by village) → tap for a full ID-card detail view.
- अहवाल: gender split, **village-wise** counts, age bands, education, occupation, social-work interest, total fees.
- **स्वतंत्र गावाचा रिपोर्ट** — pick a village to see, print, or Excel-export just that village's members.
- **PDF** export: member card (A5) or any members list (A4, showing **नाव · पत्ता · मोबाईल**).
- **Excel (.xlsx)** export: full register or a single village, with all fields, via the share sheet.
- **Delete with confirmation** — removing a member asks to confirm first.
- **वाढदिवस (birthdays)** — home card shows upcoming birthdays (next 30 days); a full list is one tap away; and a **morning (8:00 AM) notification** reminds you on each member's birthday.
- **नोंदणी क्रमांक** column added, and the auto-generated **आजीव सभासद क्रमांक is now editable** in the add/edit form.
- **मिटींग मेसेज** — home now has a *मिटींग मेसेज पाठवा* button (the old static meeting-reminder text was removed). Compose a message and send it to **all living members** or a **selected list** via SMS (bulk), WhatsApp, share, or copy.
- **मयत (deceased) नोंद** — mark a member deceased with a मयत तारीख. The list shows a **मयत शेरा + तारीख** (name struck through), with हयात/मयत filters, and reports export as **एकूण / हयात / मयत** lists (PDF + Excel).
- **बॅकअप / रिस्टोअर** — backup writes all data to a `.json` file and opens the share sheet, so you can save it to **Google Drive**, WhatsApp, or email; restore picks that file back. (This uses the Android share/open flow — no Google sign-in setup needed. A direct Drive-API auto-sync can be added later but needs a Google Cloud OAuth client.)

---

## Get the APK — easiest way (no tools to install)

1. Create a free GitHub account and a new repository.
2. Upload this whole folder to it (or `git push`).
3. Open the **Actions** tab → run **Build APK** (or just push to `main`).
4. When it finishes (~5 min), open the run and download **senior-sangh-apk** from *Artifacts*.
5. Copy `app-release.apk` to the phone and install (allow "install from unknown sources").

The workflow at `.github/workflows/build-apk.yml` also downloads the Devanagari
font automatically so Marathi shows correctly inside the PDFs.

## Build it yourself (on a computer with Flutter)

```bash
flutter create --platforms=android --project-name senior_sangh .
mkdir -p assets/fonts
# Static Devanagari font so PDFs render Marathi (the CI does this automatically):
curl -fL "https://raw.githubusercontent.com/google/fonts/main/ofl/mukta/Mukta-Regular.ttf" -o assets/fonts/Mukta-Regular.ttf
curl -fL "https://raw.githubusercontent.com/google/fonts/main/ofl/mukta/Mukta-Bold.ttf"    -o assets/fonts/Mukta-Bold.ttf
python3 tool/patch_android.py   # enables notification permissions + desugaring
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

> Marathi in PDFs: the app embeds the **static Mukta** font (Devanagari). The
> earlier variable Noto font failed to parse and showed boxes (tofu) — Mukta
> fixes that. The CI downloads it automatically; for local builds run the two
> `curl` lines above before `flutter build`.

## Google Drive setup (for the direct Drive buttons)
The "थेट Google Drive" buttons need a one-time Google Cloud setup:
1. Create a project at console.cloud.google.com and **enable the Google Drive API**.
2. Configure the **OAuth consent screen** (External, add your email as a test user).
3. Create an **OAuth client ID → Android**, using the app's package name
   (`com.example.senior_sangh` unless you change it) and your signing **SHA-1**
   (`cd android && ./gradlew signingReport`).
4. Rebuild. Until this is done, the Drive buttons show "सेटअप आवश्यक"; the
   file-based backup (share to Drive/WhatsApp) works without any setup.

## Project structure
```
lib/
  main.dart                     app shell + bottom nav
  theme.dart                    colors / theme
  models/member.dart            Member model (fee, age, db mapping)
  data/member_repo.dart         SQLite storage + seed data
  services/pdf_service.dart     member card + list PDFs
  screens/
    home_screen.dart            dashboard
    members_screen.dart         list + search + filters
    member_detail_screen.dart   ID-card view + PDF + delete
    add_member_screen.dart      data-entry form + photo
    reports_screen.dart         charts / breakdowns
```
