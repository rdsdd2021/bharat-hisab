# Changelog

All notable changes to the **BharatHisab (भारतहिसाब)** POS & Retail Suite are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.3.0] - 2026-10-28

### 🐛 Fixed
- **Udhaar Sticky / Defaulting Bug**:
  - Resolved root cause where previous deferred/credit (Udhaar) transactions or cancelled bills kept settlement mode sticky on Udhaar for subsequent sales.
  - Cart clearance (clearCart) and invoice completion (commitInvoice) now strictly reset settlement mode to standard Cash (SettlementMode.cash).
  - Emptying cart (removeCartLine) and resuming parked sales (resumeHeldSale) default to Cash.
  - In POS UI, selecting Udhaar mode prompts for an attached customer account first; if user dismisses or cancels the customer selector modal without picking a customer, billing automatically reverts to Cash with user notification.
  - Tapping Walk-in Cash Customer explicitly clears customer and resets settlement mode to Cash.

### 🚀 Added
- **Product Media Attachment (ProductImagePicker)**:
  - Interactive photo container in Add and Edit SKU dialogs (Inventory Management) and Quick Add SKU dialog (POS Billing Counter).
  - Multi-source image input:
    - Camera capture snapshot flow.
    - Direct web URL / file link input.
    - 12 curated retail catalog presets (Atta, Rice, Milk, Cooking Oil, Biscuits, Spices, Tea/Coffee, Soaps, Pharma, Garments, Electronics, Fruits/Veg).
  - Responsive thumbnail preview card with change and delete actions.
  - Product thumbnails rendered in inventory list tiles and POS shelf item cards with category fallback avatars.
- **Auto-Fill Optical Barcode Scanner (BarcodeScannerModal)**:
  - Dedicated scan button next to Barcode and SKU input fields across both Inventory and POS Quick-Add dialogs.
  - Interactive camera viewfinder with animated laser guide, torch/flashlight toggle, and camera flip.
  - Real-time hardware USB/Bluetooth barcode scanner HID listener.
  - 1-tap optical capture and EAN-13 simulation with haptic feedback.
  - Automatically injects the scanned code into Barcode and SKU fields without manual typing.
- **Automated Verification**:
  - Added udhaar_reset_and_item_media_test.dart verifying Udhaar resets to Cash across commits, cancellations, and line removals, as well as ProductImagePicker presets and BarcodeScannerModal callbacks.
  - 100% green test suite across 68 automated tests in 11 test suites.

---

## [1.2.0] - 2026-10-28

### 🚀 Added
- **5-Vertical Interactive Setup Selector Cards (`MerchantAuthScreen`)**:
  - Replaced plain setup selector with 5 visual cards showing industry badges, icons, color codes, and capability bullets for Kirana, Restaurant, Pharmacy, Garments, and Electronics.
  - Linked "Seed Demo Catalog" toggle to initialize vertical-specific demo inventory on registration.
- **Dynamic Billing Counter Mode Switcher (`PosBillingScreen`)**:
  - Embedded `[ 🛒 Kirana & Grocery ▾ ]` quick-switch pill directly in POS top app bar.
  - Interactive bottom sheet allowing cashiers to switch verticals on the fly with two choices:
    - *Switch Mode & Load Sample Items*: Instantly switches counter and loads sample inventory.
    - *Switch Mode (Keep Current Items)*: Retains current cart items while altering mode-specific actions.
- **Vertical-Specific Micro-Interaction Toolbars**:
  - **🍽️ Restaurant, Cafe & QSR**: Table and takeaway selection bar (`T-01` to `T-12`, `Takeaway`), Room Service tags, and instant `[ 🍳 Send / Print KOT ]` kitchen order ticket modal preview.
  - **💊 Pharmacy & Healthcare**: Prescribing Doctor & Patient info prompt (`🩺 Rx Doctor`), Schedule H drug compliance warning badge, and Near-Expiry indicator chip.
  - **👕 Garments & Apparel**: Garment size matrix chips (`XS`, `S`, `M`, `L`, `XL`, `XXL`), Color variant selector chips (`Black`, `Navy`, `Olive`, `White`, `Red`, `Beige`), and `[ 🏷️ Print Barcode Tag (38x25mm) ]` sticker preview modal.
  - **📱 Electronics & Mobiles**: 15-digit IMEI & Serial Number modal prompt (`📱 Add IMEI / Serial`) and 1-Year brand warranty certificate banner on receipts.
  - **🛒 Kirana & Supermarket**: Digital scale tare/read button (`⚖️ Read Scale`) and Bag Charge toggle (`🛍️ Bag Charge`).
- **Vertical-Specific Thermal Receipt Printing**:
  - Tailored receipts dynamically featuring order type/table number (Restaurant), Drug License & Batch/Expiry details (Pharmacy), 7-day apparel exchange policy (Garments), and Serial/IMEI warranty certification (Electronics).
- **Automated Mode Switching Test Suite**:
  - Added `vertical_mode_switching_test.dart` verifying all 5 modes, dynamic action bars, sample catalog loading, and KOT dispatch.
  - Maintained 100% green test suite across 62 tests in 10 test files.

---

## [1.1.0] - 2026-10-28

### 🚀 Added
- **Centralized Cloud Backend Service (`server/`)**:
  - Implemented Node.js/Express cloud API server on port `5000` (`http://localhost:5000` and LAN IP `http://192.168.31.33:5000`).
  - Added `POST /api/v1/auth/register` for cloud tenant onboarding with automatic 3-year commercial Pro license provisioning.
  - Added `POST /api/v1/auth/login` for cross-platform authentication across mobile and web.
  - Added `POST /api/v1/sync/push` and `GET /api/v1/sync/pull` for delta replication of products, parties, invoices, and khata entries.
  - Added protected `GET /api/v1/admin/merchants` and `POST /api/v1/admin/license/issue` for real-time reseller telemetry.
  - Added atomic JSON database durability engine (`server/data/bharathisab_cloud_db.json`).
- **Cryptographic Security & Brute-Force Rate Limiting**:
  - Hashed user PINs using **10,000 iterations of PBKDF2-SHA256** with unique 16-byte cryptographically secure random salts.
  - Implemented IP + Phone sliding-window rate limiter (5 failed attempts locks out for 5 minutes).
  - Enforced Bearer Token authentication on all Superadmin fleet telemetry and licensing routes.
- **Client Cloud Integration (`ezo_core_models`)**:
  - Created [`BackendApiService`](file:///C:/Users/Ramanuj%20Dey%20Sarkar/ezo_pos_workspace/packages/ezo_core_models/lib/src/services/backend_api_service.dart) with platform-aware base URL resolution (Android emulator `10.0.2.2`, physical LAN IP, Web localhost).
  - Enhanced [`EzoOfflineRepository`](file:///C:/Users/Ramanuj%20Dey%20Sarkar/ezo_pos_workspace/packages/ezo_core_models/lib/src/storage/offline_repository.dart) with `registerCloud`, `loginCloud`, and `syncWithCloud` methods with graceful offline local database fallback.
- **Cross-Platform Verification & Testing**:
  - Added `http: ^1.2.0` across all packages and apps (`ezo_core_models`, `ezo_pos_merchant_app`, `ezo_reseller_admin_portal`, `ezo_salesperson_app`, `ezo_e2e_tests`).
  - Expanded automated test coverage to **58 passing tests** across 10 test suites (100% green).

### 🔧 Changed
- **Android Network Manifest**:
  - Added `<uses-permission android:name="android.permission.INTERNET"/>` and `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>` to `apps/ezo_pos_merchant_app/android/app/src/main/AndroidManifest.xml` so release builds can connect to the cloud.
- **Web Cache Invalidation & Service Worker**:
  - Added explicit service worker unregistration scripts in `web/index.html` for both Merchant and Superadmin web portals to purge legacy bundles.
  - Configured `NoCacheHandler` with `Cache-Control: no-store, no-cache, must-revalidate, max-age=0` headers in local multi-server daemon.
- **Superadmin Telemetry**:
  - Replaced static mock merchant entries in `reseller_dashboard_screen.dart` with live polling of `/api/v1/admin/merchants`.
- **Release Split APKs**:
  - Generated fresh production release split APKs:
    - `arm64-v8a`: 20.3 MB
    - `armeabi-v7a`: 17.8 MB

---

## [1.0.0] - 2026-10-26

### 🚀 Initial Monorepo Release
- **7 Melos Domain Packages**:
  - `ezo_core_models`: Clean DDD domain models, SQLite/Hive offline repository, outbox sync queue.
  - `ezo_gst_tax_engine`: Statutory Indian GST calculation (CGST/SGST/IGST), tax-inclusive reverse math, nearest-rupee round-off, 50+ business reports.
  - `ezo_thermal_printer_escpos`: 58mm (Chota) and 80mm (Bada) ESC/POS thermal byte streams, dynamic UPI QR code, restaurant KOT slips, and PDF invoices.
  - `ezo_inventory_barcode`: Real-time stock ledger, minimum reorder velocity alerts, CSV batch bulk editing, and discount barcode sticker generator.
  - `ezo_khata_upi_whatsapp`: Double-sided Udhaar credit ledger, dynamic customer balance reconciliation, and 1-click WhatsApp payment reminders with dynamic UPI links.
  - `ezo_online_dukan_ai`: WhatsApp mini-store catalog publishing, automated Google Review AI replier, and local NearSearch SEO schemas.
  - `ezo_l10n_vernacular`: 10 Indian vernacular languages (English, Hindi, Bengali, Marathi, Gujarati, Telugu, Tamil, Kannada, Malayalam, Punjabi).
- **3 Front-End Applications**:
  - `ezo_pos_merchant_app`: Flagship Retail POS billing, inventory, and Khata application.
  - `ezo_reseller_admin_portal`: Multi-tenant Superadmin and SaaS Reseller Control Tower.
  - `ezo_salesperson_app`: Companion mobile application for field order booking and doorstep Khata collection.
- **Modern Kirana Billing Enhancements**:
  - Dual item-entry flow supporting both external hardware barcode scanners (HID/key events) and built-in mobile camera scanning with continuous multi-scan, torch toggle, and audio/haptic feedback.
  - Numeric 1-4 digit short-code rapid entry numpad for loose staples (Rice, Sugar, Dal).
  - Multi-queue parked bill hold & resume system.
  - Comprehensive 10-chapter documentation suite in `docs/`.
