# Deployment, Packaging & CI/CD Guide

This guide covers building, signing, and releasing production artifacts for **Android (Mobile & POS Terminals)**, **Windows Desktop**, and **Web (Admin Console)** from the Melos monorepo.

---

## 1. Monorepo CI/CD & Melos Commands

All build workflows are automated via [`melos.yaml`](../../melos.yaml) at the repository root.

```bash
# 1. Link all local packages and fetch pub dependencies
melos bootstrap

# 2. Run static analyzer across all 7 packages and 3 apps
melos run analyze

# 3. Execute all unit, widget, and integration tests
melos run test

# 4. Build Android Release APK for Flagship POS App
melos run build:pos_apk

# 5. Build Android Release APK for Salesperson App
melos run build:sales_apk

# 6. Build Release Web Bundle for Reseller Admin Portal
melos run build:reseller_web
```

---

## 2. Android Production Builds (APK & AAB for Play Store)

### 2.1 Release Signing Keystore Configuration

Create `android/key.properties` inside `apps/ezo_pos_merchant_app`:

```properties
storePassword=YourStorePasswordSecure123
keyPassword=YourKeyPasswordSecure123
keyAlias=ezo_pos_key
storeFile=C:/keys/ezo_pos_upload_keystore.jks
```

In `android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2.2 Generating Release Artifacts

```bash
cd apps/ezo_pos_merchant_app

# 1. Build Google Play Android App Bundle (AAB)
flutter build appbundle --release

# 2. Build Split-per-ABI APKs (Target: 15-30 MB)
flutter build apk --release --split-per-abi

# 3. Build Standalone Universal APK (Fat APK ~147MB)
flutter build apk --release --split-per-abi=false
```

### 2.3 Optimized APK Artifacts (15–30 MB Target Achieved)

By splitting by ABI (Application Binary Interface), each APK bundles only the native C++ libraries for its architecture, dramatically shrinking download sizes:

| Artifact | Size | Target Hardware | Location |
|---|---|---|---|
| **`BharatHisab_POS_v1.0.0_arm64-v8a.apk`** | **18.5 MB** | 64-bit ARM smartphones & tablets | `outputs/BharatHisab_POS_v1.0.0_arm64-v8a.apk` |
| **`BharatHisab_POS_v1.0.0_armeabi-v7a.apk`** | **16.1 MB** | 32-bit ARM phones & POS terminals (Sunmi, iMin) | `outputs/BharatHisab_POS_v1.0.0_armeabi-v7a.apk` |
| **`BharatHisab_POS_v1.0.0_x86_64.apk`** | **20.0 MB** | x86_64 Android emulators & Chromebooks | `outputs/BharatHisab_POS_v1.0.0_x86_64.apk` |

---

## 3. Local Multi-Daemon Web Server Deployment

To test the entire three-application ecosystem locally without running heavy emulators:

```bash
python scratch/serve_all_local.py
```

| Application | Port | Source Build Directory |
|---|---|---|
| **BharatHisab POS Merchant App** | `http://localhost:8090/` | `apps/ezo_pos_merchant_app/build/web` |
| **Superadmin & Reseller Tower** | `http://localhost:8091/` | `apps/ezo_reseller_admin_portal/build/web` |
| **Field Salesperson Companion** | `http://localhost:8092/` | `apps/ezo_salesperson_app/build/web` |

---

## 4. Windows Desktop Deployment (MSIX / Inno Setup)

For retail billing counters running Windows 10/11 with USB thermal printers and handheld barcode scanners:

### 4.1 Building Windows Release Executable

```bash
cd apps/ezo_pos_merchant_app
flutter build windows --release
```

Output folder: `build/windows/x64/runner/Release/`

### 4.2 Packaging with Inno Setup
Create `installer_script.iss` to generate a lightweight single-file setup installer:
- Embeds Flutter engine DLLs (`flutter_windows.dll`, plugins).
- Adds Desktop shortcut and Start Menu entry.
- Grants firewall permissions for local LAN KOT kitchen printing.

---

## 5. Web Console Deployment (`apps/ezo_reseller_admin_portal`)

The Superadmin Reseller Portal compiles to high-performance web:

```bash
cd apps/ezo_reseller_admin_portal

# Build optimized production web release
flutter build web --release --web-renderer canvaskit
```

Output directory: `build/web/`

### 5.1 Deployment to Cloudflare Pages / Firebase
Deploy the `build/web` folder to any static hosting provider:

```bash
# Firebase Hosting
firebase deploy --only hosting

# Cloudflare Pages
npx wrangler pages deploy build/web --project-name=bharathisab-reseller-portal
```

---

## 6. White-Label Multi-Brand Build Pipeline

To build a branded flavor for a specific reseller without altering code:

```bash
flutter build apk --release \
  --dart-define=BRAND_NAME="RetailMaster POS" \
  --dart-define=PRIMARY_COLOR="#4338CA" \
  --dart-define=RESELLER_LEGAL="Apex Tech Ltd" \
  --dart-define=SUPPORT_PHONE="+919822012345"
```

The app's [`WhiteLabelBranding`](../../packages/ezo_core_models/lib/src/models/business_profile.dart) dynamically reads these flags during boot.

---

For architectural reference, see [Architecture Blueprint](../architecture/ARCHITECTURE.md).
