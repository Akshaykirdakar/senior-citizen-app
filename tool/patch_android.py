#!/usr/bin/env python3
"""Patch the freshly-generated android/ project so flutter_local_notifications
builds and can post notifications. Idempotent; safe to run in CI after
`flutter create`."""
import os
import re

APP = "android/app"
NDK = "27.0.12077973"


def patch_manifest():
    path = f"{APP}/src/main/AndroidManifest.xml"
    if not os.path.exists(path):
        print("manifest not found:", path)
        return
    s = open(path, encoding="utf-8").read()
    perms = [
        '<uses-permission android:name="android.permission.INTERNET"/>',
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
        '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
        '<uses-permission android:name="android.permission.VIBRATE"/>',
    ]
    add = "\n".join("    " + p for p in perms if p.split('"')[1] not in s)
    if add:
        s = re.sub(r"(<manifest[^>]*>)", r"\1\n" + add, s, count=1)

    if "<queries>" not in s:
        queries = (
            "    <queries>\n"
            "        <intent><action android:name=\"android.intent.action.VIEW\"/>"
            "<data android:scheme=\"https\"/></intent>\n"
            "        <intent><action android:name=\"android.intent.action.VIEW\"/>"
            "<data android:scheme=\"sms\"/></intent>\n"
            "        <intent><action android:name=\"android.intent.action.SENDTO\"/>"
            "<data android:scheme=\"smsto\"/></intent>\n"
            "        <intent><action android:name=\"android.intent.action.DIAL\"/>"
            "<data android:scheme=\"tel\"/></intent>\n"
            "    </queries>"
        )
        s = re.sub(r"(<manifest[^>]*>)", r"\1\n" + queries, s, count=1)

    open(path, "w", encoding="utf-8").write(s)
    print("manifest patched")


def patch_gradle():
    groovy = f"{APP}/build.gradle"
    kts = f"{APP}/build.gradle.kts"
    if os.path.exists(kts):
        _patch_kts(kts)
    elif os.path.exists(groovy):
        _patch_groovy(groovy)
    else:
        print("no app build.gradle found")


def _patch_groovy(path):
    s = open(path, encoding="utf-8").read()
    if "coreLibraryDesugaringEnabled" not in s:
        if re.search(r"compileOptions\s*\{", s):
            s = re.sub(r"(compileOptions\s*\{)", r"\1\n        coreLibraryDesugaringEnabled true", s, count=1)
        else:
            s = re.sub(r"(android\s*\{)", r"\1\n    compileOptions {\n        coreLibraryDesugaringEnabled true\n        sourceCompatibility JavaVersion.VERSION_1_8\n        targetCompatibility JavaVersion.VERSION_1_8\n    }", s, count=1)
    if "desugar_jdk_libs" not in s:
        s += '\n\ndependencies {\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.4"\n}\n'
    # NDK version required by plugins
    if re.search(r"ndkVersion\s+", s):
        s = re.sub(r"ndkVersion\s+[^\n]+", 'ndkVersion "%s"' % NDK, s, count=1)
    else:
        s = re.sub(r"(android\s*\{)", r'\1\n    ndkVersion "%s"' % NDK, s, count=1)
    open(path, "w", encoding="utf-8").write(s)
    print("groovy gradle patched")


def _patch_kts(path):
    s = open(path, encoding="utf-8").read()
    if "isCoreLibraryDesugaringEnabled" not in s:
        if re.search(r"compileOptions\s*\{", s):
            s = re.sub(r"(compileOptions\s*\{)", r"\1\n        isCoreLibraryDesugaringEnabled = true", s, count=1)
        else:
            s = re.sub(r"(android\s*\{)", r"\1\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n        sourceCompatibility = JavaVersion.VERSION_1_8\n        targetCompatibility = JavaVersion.VERSION_1_8\n    }", s, count=1)
    if "desugar_jdk_libs" not in s:
        s += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    # NDK version required by plugins
    if re.search(r"ndkVersion\s*=", s):
        s = re.sub(r"ndkVersion\s*=\s*[^\n]+", 'ndkVersion = "%s"' % NDK, s, count=1)
    else:
        s = re.sub(r"(android\s*\{)", r'\1\n    ndkVersion = "%s"' % NDK, s, count=1)
    open(path, "w", encoding="utf-8").write(s)
    print("kts gradle patched")


if __name__ == "__main__":
    patch_manifest()
    patch_gradle()
