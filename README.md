# BharatHisab (भारतहिसाब) 🇮🇳

**Complete Indian POS Billing, GST Accounting, Khata & AI Storefront Monorepo Suite**

[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Web-blue.svg)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Melos%20Monorepo%20Clean%20DDD-green.svg)](https://melos.invertase.dev)
[![Offline First](https://img.shields.io/badge/Offline--First-%3C15ms%20Local%20Writes-orange.svg)](#offline-first-architecture)
[![Tax Compliance](https://img.shields.io/badge/Compliance-Exact%20Indian%20GST%20%28CGST%2FSGST%2FIGST%29-purple.svg)](docs/tax_and_accounting/GST_TAX_MATHEMATICS.md)
[![License](https://img.shields.io/badge/License-Proprietary%20Commercial-red.svg)](#commercial-licensing)

---

## 🌟 Executive Overview

**BharatHisab** is a commercial-grade, multi-tenant, white-label retail operating system built specifically for the diverse commercial ecosystem of Bharat. It delivers instant billing, double-sided Udhaar Khata, real-time inventory tracking, vernacular thermal printing, and Google/WhatsApp AI marketing in a single, high-performance Flutter Monorepo.

Designed to eliminate counter delays and withstand frequent network blackouts, BharatHisab commits all transactions locally first (<15ms latency) and transparently syncs with the cloud when connectivity resumes.

---

## 🏗️ Monorepo Architecture Blueprint

```
bharat_hisab_workspace/
├── apps/
│   ├── ezo_pos_merchant_app          # Flagship Merchant POS, Inventory, Khata & AI app
│   ├── ezo_reseller_admin_portal     # Web/Desktop Superadmin & Reseller Control Tower
│   └── ezo_salesperson_app           # Field Order Booking & Udhaar Collection mobile app
│
├── packages/
│   ├── ezo_core_models               # Domain models, SQLite/Hive storage & SyncQueue outbox
│   ├── ezo_gst_tax_engine            # CGST/SGST/IGST math, Round-off, and 50+ business reports
│   ├── ezo_thermal_printer_escpos    # 58mm/80mm ESC/POS byte streams, KOT, NPCI UPI QR & PDFs
│   ├── ezo_inventory_barcode         # Real-time stock ledger, velocity alerts, CSV bulk edit & labels
│   ├── ezo_khata_upi_whatsapp        # Double-sided Udhaar ledger, UPI dynamic QR & WhatsApp links
│   ├── ezo_online_dukan_ai           # WhatsApp Online Dukan, Dhanda AI audit & NearSearch SEO
│   └── ezo_l10n_vernacular           # 10 Indian regional languages (en, hi, bn, mr, gu, te, ta, kn, ml, pa)
│
└── server/                           # Node.js/Express Central Cloud API & Sync Backend (Port 5000)
```

---

## 🚀 Key Business & Engineering Capabilities

### 1. ⚡ High-Speed Offline-First Billing (<15ms Write Latency)
- **Local-First Engine**: Uses embedded local storage (SQLite/Hive) with an immutable `sync_queue` outbox table.
- **Zero Counter Disruption**: Invoices, customer balances, and stock deductions update instantly even without an active internet connection.
- **Automatic Reconnection Sync**: Background daemon syncs outbox batches with idempotent replay when network resumes.

### 2. 🧾 Statutory Indian GST Mathematics
- **Intra vs Inter-State Supply**: Compares store state code vs customer state code (`27` Maharashtra, `29` Karnataka, etc.) to automatically split 50/50 into CGST + SGST or apply 100% IGST.
- **Tax-Inclusive MRP Reverse Math**: $\text{Taxable} = \text{Gross} / (1 + \text{Rate}/100)$.
- **Automatic Nearest-Rupee Round-Off**: Prevents paise calculation disputes on cash counters.
- **Consumer Psychology Callout**: Computes and prints `"*** YOU SAVED Rs. X ***"` on receipts.
- **GSTR-Ready Reporting**: Tables for GSTR-1 (B2B, B2C Large, B2C Small, HSN Table 12) and GSTR-3B.

### 3. 🖨️ Multi-Format ESC/POS & PDF Print Engine
- **2-Inch Chota Billing Machine (58mm)**: 32 chars/line byte stream for portable Bluetooth terminals (Sunmi, MPT-II).
- **3-Inch Bada Billing Machine (80mm)**: 46–48 chars/line byte stream for desktop thermal printers (Epson, TVS).
- **Dynamic NPCI UPI QR**: Generates transaction-specific `upi://pay` QR codes on receipts for instant customer scan-and-pay.
- **Restaurant KOT Slips**: Kitchen Order Tickets formatted with Table Numbers and Server tags.
- **Full-Page Invoices**: Selectable Modern Card A4, Classic Tally-Style A4 Grid, and Half-Page A5 Landscape.

### 4. 📒 Double-Sided Khata (Udhaar Bahi) with WhatsApp Links
- Digital replacement for paper Khata books with automatic debit/credit balance reconciliation.
- **1-Click WhatsApp Reminders**: Pre-filled polite vernacular reminders with clickable dynamic UPI payment links.

### 5. 🏪 5 Pre-Seeded Industry Vertical Modules
1. **Kirana, Supermarket & Grocery**: Loose item weighing scale integration (KG/GMS), multi-pack barcodes.
2. **Restaurant, Cafe & QSR**: Table & room orders, instant KOT kitchen dispatch, 5% composite GST.
3. **Pharmacy & Healthcare**: Mandatory Batch Number, Expiry Date tracking, 30/60/90-day expiry alerts.
4. **Garments & Apparel**: Size & Color matrix, 38mm × 25mm barcode tag printing, tiered clothing GST.
5. **Electronics & Mobiles**: 15-digit IMEI & Serial Number tracking, printed warranty certification.

### 6. 🛡️ Superadmin & Reseller Control Tower
- **Centralized Cloud Analytics**: Real-time fleet turnover, invoice volume, store heartbeats, and 99.8% outbox sync health.
- **Commercial License Key Issuer**: Monospace cryptographic keys (`BH-{TIER}-{TIMESTAMP}`) enforcing branch limits (1-25) and staff seat limits (2-50).
- **Zero-Recompile White-Label Rebranding**: Dynamically rebrand application name, primary colors, support WhatsApp, and receipt footers at runtime.

---

## 📚 Comprehensive Documentation Library

Complete technical manuals and tutorials are stored in [`docs/`](docs/README.md):

- [Architecture Blueprint](docs/architecture/ARCHITECTURE.md)
- [Indian GST & Tax Math Manual](docs/tax_and_accounting/GST_TAX_MATHEMATICS.md)
- [POS Hardware Integration Manual](docs/hardware/HARDWARE_INTEGRATION_MANUAL.md)
- [Packages API Reference Guide](docs/packages/PACKAGES_API_REFERENCE.md)
- [Merchant Operations Manual](docs/merchant/MERCHANT_OPERATIONS_MANUAL.md)
- [Industry Verticals Playbook](docs/merchant/INDUSTRY_VERTICALS_PLAYBOOK.md)
- [Superadmin & Reseller Guide](docs/superadmin/SUPERADMIN_AND_RESELLER_GUIDE.md)
- [5 Step-by-Step Practical Tutorials](docs/tutorials/TUTORIALS_AND_WALKTHROUGHS.md)
- [Production Deployment & CI/CD Guide](docs/deployment/DEPLOYMENT_AND_PACKAGING.md)

---

## 💻 Developer Quickstart

```bash
# 1. Bootstrap all packages and link dependencies
melos bootstrap

# 2. Run static analyzer across all packages and apps
melos run analyze

# 3. Execute all unit, widget, and integration tests (58 passing tests)
melos run test

# 4. Start Central Cloud API Backend (Node.js on port 5000)
cd server
npm start

# 5. Launch Flagship Merchant POS App
cd apps/ezo_pos_merchant_app
flutter run

# 6. Launch Superadmin Reseller Console
cd apps/ezo_reseller_admin_portal
flutter run -d chrome
```

For the full revision history, see [CHANGELOG.md](CHANGELOG.md).

---

*Proudly Engineered for Indian Retail & MSMEs — Built to Power Every Counter Across Bharat.*
