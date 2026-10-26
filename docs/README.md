# BharatHisab (भारतहिसाब) POS & Billing Suite — Documentation Portal

Welcome to the official developer, operator, and administrator documentation for **BharatHisab (भारतहिसाब)**, the offline-first billing, inventory, Khata credit ledger, Online Dukan, Dhanda AI & Reseller Suite.

This suite is engineered as a production-grade, offline-first Flutter Melos Monorepo targeting **Android (Mobile & POS Terminals)**, **Windows Desktop**, and **Web (Browser & Admin Console)**.

---

## 🌐 Live Local Web Endpoints & Testing Services

All three applications can be served concurrently locally via the integrated multi-daemon:

| Application | Local Web Endpoint | Target Role | Key Features |
|---|---|---|---|
| **Merchant POS App** | [http://localhost:8090](http://localhost:8090) | Store Owners & Cashiers | Account signup, clean slate counter, quick SKU add, GST billing, Khata udhaar, thermal receipt generator |
| **Superadmin Portal** | [http://localhost:8091](http://localhost:8091) | Resellers & App Admins | Master admin authentication, tenant fleet telemetry, license key generator, agency white-labeling |
| **Salesperson App** | [http://localhost:8092](http://localhost:8092) | Field Sales Agents | Field agent login, catalog browsing, offline order booking, doorstep Khata collection |

---

## 📱 Release Android APKs (Optimized & Compressed)

Release split-per-ABI builds are maintained under `outputs/`:

| Architecture | APK File | Size | Suitable Devices |
|---|---|---|---|
| **64-bit ARM** | `BharatHisab_POS_v1.0.0_arm64-v8a.apk` | **18.5 MB** | Modern Android smartphones (2017+) |
| **32-bit ARM** | `BharatHisab_POS_v1.0.0_armeabi-v7a.apk` | **16.1 MB** | Budget phones, Sunmi/iMin handheld POS devices |

---

## 📚 Documentation Index

| Section | Document | Target Audience | Summary |
|---|---|---|---|
| **System Architecture** | [Architecture Blueprint](architecture/ARCHITECTURE.md) | Architects & Senior Devs | Monorepo layout, offline-first SQLite/Hive repository, outbox sync engine, and RBAC authentication matrix. |
| **GST & Tax Engine** | [Indian GST & Tax Math](tax_and_accounting/GST_TAX_MATHEMATICS.md) | FinTech Devs & Accountants | Exact GST formulas, Intra vs Inter-State splitting, Tax-inclusive reverse math, and GSTR reporting. |
| **POS Hardware** | [Hardware Integration Manual](hardware/HARDWARE_INTEGRATION_MANUAL.md) | Hardware Engineers | ESC/POS 58mm/80mm byte streams, Bluetooth/USB drivers, NPCI dynamic UPI QR, weighing scales, and barcode scanners. |
| **Packages API** | [Packages API Reference](packages/PACKAGES_API_REFERENCE.md) | Flutter Developers | Detailed API guide and code snippets for all 7 domain packages (`ezo_core_models`, `ezo_gst_tax_engine`, etc.). |
| **Store Operator Manual** | [Merchant Operations Manual](merchant/MERCHANT_OPERATIONS_MANUAL.md) | Store Cashiers & Managers | Real signup, clean slate counter, quick item addition, high-speed billing, Khata ledger, and shift lock. |
| **Industry Verticals** | [Industry Verticals Playbook](merchant/INDUSTRY_VERTICALS_PLAYBOOK.md) | Store Owners & Onboarding | Tailored workflows for Kirana/Grocery, Restaurant/Cafe (KOT), Pharmacy (Batch/Exp), Garments, and Electronics (IMEI). |
| **Superadmin & Reseller** | [Superadmin & Reseller Guide](superadmin/SUPERADMIN_AND_RESELLER_GUIDE.md) | SaaS Resellers & Franchisors | Master admin login, multi-tenant commercial key generator, quota enforcement, and fleet analytics. |
| **Step-by-Step Tutorials** | [Tutorials & Walkthroughs](tutorials/TUTORIALS_AND_WALKTHROUGHS.md) | All Users | Hands-on guides: Real Account Setup, Clean Slate Billing, Thermal Bluetooth pairing, and Udhaar recovery. |
| **Build & Deployment** | [Deployment & Packaging Guide](deployment/DEPLOYMENT_AND_PACKAGING.md) | DevOps & Release Engineers | Melos CI/CD commands, split-per-ABI APK optimization, Windows Desktop packaging, and Web hosting. |

---

## ⚡ Quick System Overview

```
ezo_pos_workspace/
├── apps/
│   ├── ezo_pos_merchant_app          # Flagship Merchant POS, Inventory, Khata & AI app (Port 8090)
│   ├── ezo_reseller_admin_portal     # Web/Desktop Superadmin & Reseller Control Tower (Port 8091)
│   └── ezo_salesperson_app           # Field Order Booking & Udhaar Collection mobile app (Port 8092)
│
├── packages/
│   ├── ezo_core_models               # Immutable domain models, Hive/SQLite repository & SyncQueue
│   ├── ezo_gst_tax_engine            # CGST/SGST/IGST math, Round-off, and 50+ business reports
│   ├── ezo_thermal_printer_escpos    # 58mm/80mm ESC/POS byte streams, KOT, NPCI UPI QR & PDFs
│   ├── ezo_inventory_barcode         # Real-time stock ledger, velocity alerts, CSV bulk edit & labels
│   ├── ezo_khata_upi_whatsapp        # Double-sided Udhaar ledger, UPI dynamic QR & WhatsApp links
│   ├── ezo_online_dukan_ai           # WhatsApp Online Dukan, Dhanda AI audit & NearSearch SEO schemas
│   └── ezo_l10n_vernacular           # 10 Indian regional languages (en, hi, bn, mr, gu, te, ta, kn, ml, pa)
```

---

## 🚀 Quick Start Commands

```bash
# 1. Bootstrap all packages and apps
melos bootstrap

# 2. Run static analysis across the entire monorepo
melos run analyze

# 3. Run all unit and integration tests
melos run test

# 4. Launch the Flagship Merchant POS App
cd apps/ezo_pos_merchant_app
flutter run

# 5. Build Split Release APKs (15-30 MB)
flutter build apk --release --split-per-abi

# 6. Launch the Superadmin Reseller Portal (Web/Desktop)
cd apps/ezo_reseller_admin_portal
flutter run -d chrome
```

---

*Engineered for speed, compliance, and zero offline downtime across Bharat.*
