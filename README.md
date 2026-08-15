# माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज — सभासद अ‍ॅप

A Flutter (Android) app for the senior citizens' association membership register:
**data entry** (प्रवेश अर्ज), **member directory**, **reports**, **photo capture**, and
**PDF export** of member cards and the full members list. Works fully offline (SQLite).

## Features
- नवीन सभासद form with every field from the paper अर्ज; fee auto-set (पुरुष ₹551 / महिला ₹261) and auto member number.
- Photo from camera or gallery, stored on-device.
- Searchable, filterable सभासद यादी → tap for a full ID-card detail view.
- अहवाल: gender split, age bands, education, occupation, social-work interest, total fees.
- Export a member card (A5) or the whole register (A4) to **PDF / print** in Marathi.

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
# Put a Devanagari .ttf here (both names) so PDFs render Marathi:
#   assets/fonts/NotoSansDevanagari-Regular.ttf
#   assets/fonts/NotoSansDevanagari-Bold.ttf
# (download from fonts.google.com/noto/specimen/Noto+Sans+Devanagari)
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

> Note: the app UI renders Marathi using the phone's built-in Devanagari font.
> The bundled font is only needed for **PDF** output. If it is missing, the app
> still runs — only the PDFs fall back to a Latin font.

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
