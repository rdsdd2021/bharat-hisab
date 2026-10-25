# EZO POS & Billing Suite — Documentation Portal

Welcome to the official developer, operator, and administrator documentation for the **EZO POS, Books, Online Dukan, Dhanda AI & Reseller Suite**.

This suite is engineered as a production-grade, offline-first Flutter Melos Monorepo targeting **Android (Mobile & POS Terminals)**, **Windows Desktop**, and **Web (Admin Console)**.

---

## 📚 Documentation Index

| Section | Document | Target Audience | Summary |
|---|---|---|---|
| **System Architecture** | [Architecture Blueprint](architecture/ARCHITECTURE.md) | Architects & Senior Devs | Monorepo layout, offline-first SQLite/Hive repository, outbox sync engine, and RBAC matrix. |
| **GST & Tax Engine** | [Indian GST & Tax Math](tax_and_accounting/GST_TAX_MATHEMATICS.md) | FinTech Devs & Accountants | Exact GST formulas, Intra vs Inter-State splitting, Tax-inclusive reverse math, and GSTR reporting. |
| **POS Hardware** | [Hardware Integration Manual](hardware/HARDWARE_INTEGRATION_MANUAL.md) | Hardware Engineers | ESC/POS 58mm/80mm byte streams, Bluetooth/USB drivers, NPCI dynamic UPI QR, weighing scales, and barcode scanners. |
| **Packages API** | [Packages API Reference](packages/PACKAGES_API_REFERENCE.md) | Flutter Developers | Detailed API guide and code snippets for all 7 domain packages (`ezo_core_models`, `ezo_gst_tax_engine`, etc.). |
| **Store Operator Manual** | [Merchant Operations Manual](merchant/MERCHANT_OPERATIONS_MANUAL.md) | Store Cashiers & Managers | High-speed billing, split payments, Khata credit ledger, WhatsApp reminders, and daily shift closing. |
| **Industry Verticals** | [Industry Verticals Playbook](merchant/INDUSTRY_VERTICALS_PLAYBOOK.md) | Store Owners & Onboarding | Tailored workflows for Kirana/Grocery, Restaurant/Cafe (KOT), Pharmacy (Batch/Exp), Garments, and Electronics (IMEI). |
| **Superadmin & Reseller** | [Superadmin & Reseller Guide](superadmin/SUPERADMIN_AND_RESELLER_GUIDE.md) | SaaS Resellers & Franchisors | Multi-tenant commercial key generator, quota enforcement, zero-recompile rebranding, and fleet analytics. |
| **Step-by-Step Tutorials** | [Tutorials & Walkthroughs](tutorials/TUTORIALS_AND_WALKTHROUGHS.md) | All Users | Hands-on guides: First Bill in 60s, Thermal Bluetooth pairing, Udhaar recovery via UPI, and Google profile SEO audit. |
| **Build & Deployment** | [Deployment & Packaging Guide](deployment/DEPLOYMENT_AND_PACKAGING.md) | DevOps & Release Engineers | Melos CI/CD commands, Android APK/AAB release signing, Windows Desktop MSIX packaging, and Web hosting. |

---

## ⚡ Quick System Overview

```
ezo_pos_workspace/
├── apps/
│   ├── ezo_pos_merchant_app          # Flagship Merchant POS, Inventory, Khata & AI app
│   ├── ezo_reseller_admin_portal     # Web/Desktop Superadmin & Reseller Control Tower
│   └── ezo_salesperson_app           # Field Order Booking & Udhaar Collection mobile app
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

# 3. Run all unit and integration tests (42 passing tests)
melos run test

# 4. Launch the Flagship Merchant POS App
cd apps/ezo_pos_merchant_app
flutter run

# 5. Launch the Superadmin Reseller Portal (Web/Desktop)
cd apps/ezo_reseller_admin_portal
flutter run -d chrome
```

---

*Engineered for speed, compliance, and zero offline downtime across Bharat.*
