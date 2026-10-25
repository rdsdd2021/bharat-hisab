# Superadmin & Reseller Guidebook

This guide instructs SaaS resellers, franchisors, and application owners on administering the **EZO Reseller Control Tower** (`apps/ezo_reseller_admin_portal`), generating commercial license keys, managing tenant quotas, and executing zero-recompile white-label rebranding.

---

## 1. The Reseller Control Tower Console

The portal is a high-performance web and desktop console designed for executive operations, running locally on [http://localhost:8091](http://localhost:8091):

```
┌───────────────────────────────────────────────────────────────────────────┐
│ 🛡️ BharatHisab Control Tower           [Issue New Key]  [Sign Out]        │
├───────────────────────────────────────────────────────────────────────────┤
│ [ Tab 1: Cloud Fleet Analytics ] [ Tab 2: Tenant Licenses ] [ Tab 3: White-Label ]│
└───────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Master Authentication & Agency Registration
Access to the Control Tower is gated behind `SuperadminAuthScreen`:
- **Master Sign In**:
  - Email: `admin@bharathisab.com`
  - Master Security PIN: `889900`
- **Register New Reseller / Agency**:
  - Agency Name (e.g. *Apex Commercial Systems*)
  - Primary Contact Email & 6-digit Master PIN
  - Agency Authorization Key
- **Sign Out**: Tap the logout icon in the top right to end the session and return to the login gate.

---

## 2. Centralized Cloud Analytics & Fleet Telemetry

The central telemetry tab aggregates real-time business health across all deployed merchant stores in your territory.

### 2.1 The 4 Fleet Health KPIs
1. **Total Fleet Gross Sales (Today)**: Real-time cumulative turnover across all merchant terminals (e.g., ₹27,90,500).
2. **Invoices Processed**: Total transaction volume processed across the network today (e.g., 254 bills).
3. **Active Connected Stores**: Live status ratio of actively communicating stores (e.g., 4 / 5 Stores Online).
4. **Cloud Outbox Health**: Percentage of transactions successfully committed to the cloud ledger (e.g., 99.8% Sync Rate with <15ms latency).

### 2.2 Live Store Fleet Telemetry Table
The telemetry table streams live heartbeats from every POS terminal:

| Store Name | Industry Vertical | Today's Sales | Heartbeat & Sync Status | Cashier on Duty | Action |
|---|---|---|---|---|---|
| **Shivaji Nagar Kirana** | Kirana & Retail | ₹48,250 | 🟢 `Online (Just now)` | Sunil Verma | Remote Sync Ping |
| **Pune Mega Mart & Cafe** | Restaurant & Cafe | ₹1,42,800 | 🟢 `Online (2m ago)` | Rohan Nair | Inspect Ledger |
| **Apex Electronics Hub** | Consumer Tech | ₹3,85,000 | 🟢 `Online (5m ago)` | Vikram Shinde | Inspect Ledger |
| **Sanjivani Medicos** | Healthcare & Pharma | ₹64,200 | 🟡 `Offline (4 queued)` | Dr. Kulkarni | View Outbox Queue |
| **StyleStreet Garments** | Fashion & Apparel | ₹92,400 | 🟢 `Online (1m ago)` | Pooja Patil | Remote Sync Ping |

> [!NOTE]
> When a merchant operates offline (e.g., *Sanjivani Medicos* with 4 queued bills), their local database continues billing without latency. The outbox count automatically decrements and resets to *Online* as soon as connectivity resumes.

---

## 3. Commercial License Generation & Quota Management

All tenant access, validity periods, and hardware quotas are cryptographically enforced via `MerchantLicenseKey`.

### 3.1 Subscription Tiers

| Tier Name | Key Prefix | Validity Duration | Target Merchant |
|---|---|---|---|
| `freeTrial` | `EZO-TRIAL` | 14 Days | Evaluation and new store onboarding. |
| `oneYearStandard` | `EZO-STD` | 365 Days | Small kirana, solo cafes, and boutique retailers. |
| `threeYearPro` | `EZO-PRO` | 1,095 Days (3 Yrs) | Growing supermarkets, multi-counter restaurants. |
| `lifetimeEnterprise` | `EZO-ENT` | 36,500 Days (Perpetual) | Franchises, enterprise chains, and flagship stores. |

### 3.2 Granular Quota & Module Controls
When issuing a key via the **"Issue New Commercial License Key"** modal, configure:
- **Merchant Legal Entity Name**: Locks the license to the merchant's GSTIN/entity.
- **Branch Store Quota**: Number of branch outlets permitted (1, 2, 3, 5, 10, or 25 stores).
- **Staff Seat Quota**: Number of concurrent staff logins permitted (2, 5, 10, 20, or 50 seats).
- **Add-on Feature Gates**:
  - `isDhandaAiEnabled`: Enables automated Google review AI replier and reputation dashboard.
  - `isOnlineDukanEnabled`: Enables WhatsApp mini-store catalog publishing.

### 3.3 License Key Format & Verification
Generated keys follow the canonical pattern:
```
EZO-{TIER}-{TIMESTAMP_MILLIS}
Example: EZO-PRO-1771958291042
```

The POS validates keys locally by evaluating:
$$\text{Days Remaining} = \text{expiresAt} - \text{now}()$$
$$\text{Is Valid} = \text{Days Remaining} > 0 \land \text{Store Count} \le \text{maxAllowedStores}$$

---

## 4. Zero-Recompile White-Label Rebranding Engine

Resellers can rebrand the POS application and receipt printouts without changing Dart source code or rebuilding APKs.

```
┌─────────────────────────────────────────────────────────────┐
│ 🎨 Global White-Label Rebranding Engine                      │
├─────────────────────────────────────────────────────────────┤
│ Brand App Name:      [ RetailMaster POS Suite             ] │
│ Reseller Company:    [ Apex Technologies Solutions Ltd    ] │
│ Support WhatsApp:    [ +91 98220 12345                    ] │
│ Primary Color Hex:   [ #4338CA                            ] │
│ Receipt Tagline:     [ Thank You! Visit Us Again!         ] │
│                      [ Save Changes & Push to Fleet ]       │
└─────────────────────────────────────────────────────────────┘
```

### 4.1 Real-Time Simulator
The right panel of Tab 3 simulates how changes immediately render on:
1. **The Navigation Header**: Injects the chosen Hex color (`#4338CA`) and custom app name.
2. **Thermal Receipt Footer**: Renders an authentic monospace thermal slip displaying the custom header, store contact, and receipt footer slogan.

---

## 5. Reseller Business Model & Monetization Strategy

| Offering | Suggested Reseller Pricing (INR) | Margin (%) |
|---|---|---|
| **Chota Billing Machine Bundle** (58mm POS + 1-Yr Standard) | ₹8,999 – ₹10,999 | 45% – 55% |
| **Bada Desktop POS Bundle** (80mm Printer + Scanner + 3-Yr Pro) | ₹18,999 – ₹24,999 | 50% – 60% |
| **Annual Software AMC Renewal** | ₹2,499 / store / year | 80% |
| **Dhanda AI & WhatsApp Dukan Add-on** | ₹999 / store / year | 90% |

---

For dashboard source code, explore [`apps/ezo_reseller_admin_portal/lib/src/reseller_dashboard_screen.dart`](../../apps/ezo_reseller_admin_portal/lib/src/reseller_dashboard_screen.dart).
