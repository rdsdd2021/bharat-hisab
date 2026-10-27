# Merchant POS Operations Manual

A practical, step-by-step operator guide for Store Managers, Counter Cashiers, and Floor Staff using [`apps/ezo_pos_merchant_app`](../../apps/ezo_pos_merchant_app).

---

## 0. First Launch, Account Registration & Clean Slate Setup

### 0.1 Creating Your Real Business Account
When you first open BharatHisab on your Android terminal, tablet, or web browser ([http://localhost:8090](http://localhost:8090)), you are presented with the **Merchant Account Setup Portal**:
1. **Shop / Store Name**: Enter your commercial trading name (e.g. *Shree Ganesh Supermarket*).
2. **Owner / Manager Name**: Full name of the primary administrator.
3. **Mobile Phone**: 10-digit phone used for SMS/WhatsApp receipts and UPI receipts.
4. **4-Digit Quick PIN**: Used to unlock the cashier register and access managerial settings.
5. **State / UT**: Crucial for Indian GST rules—defines whether transactions are Intra-State (CGST + SGST) or Inter-State (IGST).
6. **Industry Vertical**: Choose Kirana, Restaurant, Electronics, Apparel, Pharmacy, or General Retail.
7. **Clean Slate Choice**: Keep **"Start with 100% Clean Slate (0 products, clean ledger)"** checked to start with an authentic empty store.

### 0.2 Adding Products Right at the Counter
If you start clean, you do not need to navigate deep into settings to stock your shelf:
- **Empty Counter Card**: Tap **`+ Add Your First Product SKU`** directly on the billing screen.
- **Header Action Button**: Tap the **`+ Add SKU`** pill in the search bar.
- **Product Parameters**: Enter Product Name, Barcode/SKU, MRP, Selling Price, Stock Qty, and GST Tax Slab (0%, 5%, 12%, 18%, 28%).
- **Quick-Load Starter Staples**: If you want instant grocery staples for staff training, tap **`⚡ Quick-Load 10 Essential Staples`** to seed 10 common items (Atta, Oil, Rice, Salt, Sugar, Tea, Milk, Biscuits, Maggi, Soap).

### 0.3 Shift Lock & Resetting the Store Slate
- **Lock Register**: Tap the Cashier profile badge in the top navigation bar and select **"Lock Register & Switch Cashier"**.
- **Wipe Slate (Testing Mode)**: Go to **Settings** $\rightarrow$ **Session & Store Management** $\rightarrow$ Tap **"Reset Clean Slate"**. Confirming erases local data and brings you back to the signup screen to test fresh store creation.

### 0.4 Cross-Device Multi-Terminal Sync (Phone & Web Login)
- **Central Cloud Registration**: When registering your store on the Android APK, your account is automatically provisioned in the central BharatHisab cloud database with a 3-year commercial Pro license.
- **Accessing Web from Desktop Counter**: Open http://localhost:8090 on your desktop browser. Enter the **exact same 10-digit mobile number and 4-digit PIN** and tap **Sign In**.
- **Real-Time Synchronized State**: Invoices created on the mobile terminal automatically sync to the cloud backend and reflect on the desktop web counter and Superadmin console.
- **Offline Resiliency**: If your Wi-Fi or broadband drops, both mobile and web terminals continue checkout without delay. Transactions queue in the local outbox and synchronize automatically upon reconnection.

---

## 1. Daily Cashier Routine & Shift Opening

### 1.1 Starting Your Shift
1. **Launch App**: Open the BharatHisab POS app on your terminal (Sunmi POS, Android tablet, or Windows Desktop).
2. **Log In**: Select your Cashier profile from the top-right avatar menu and enter your 4-digit PIN.
3. **Cash Drawer Float**: Enter the starting physical cash float (e.g., ₹2,000 in small change: ₹10, ₹20, ₹50, ₹100 notes).

---

## 2. High-Speed Counter Billing & Barcode Scanning

The billing screen is optimized for sub-10-second checkout:

```
[ Barcode Scanner (F2) ]  [ Search Item Name / SKU (F3) ]
┌─────────────────────────┬───────────────────────────────┐
│ Current Cart Items (5)  │ Category Quick Tiles          │
│ 1. Tata Salt 1kg    x2  │ [All] [Staples] [Dairy] [Oil] │
│ 2. Fortune Oil 1L   x1  │                               │
│ 3. Maggi 280g       x4  │ Product Grid (Tap to Add)     │
│                         │ [Amul Milk]  [Atta 5kg]       │
├─────────────────────────┴───────────────────────────────┤
│ Subtotal: ₹480.00 | Tax (GST): ₹32.40 | Round-Off: ₹0.60│
│ GRAND TOTAL: ₹513.00       [YOU SAVED ₹42.00]           │
│ [ Cash (F8) ] [ UPI QR (F9) ] [ Udhaar (F10) ] [Settle] │
└─────────────────────────────────────────────────────────┘
```

### 2.1 Three Ways to Add Items to Cart
1. **Barcode Scan (Fastest)**: Scan any product barcode with your handheld USB/Bluetooth scanner. The item instantly pops into the cart. Scanning the same barcode multiple times increments the quantity automatically.
2. **Category Grid**: Tap on category chips (e.g. *Dairy*, *Snacks*, *Beverages*) and tap the product card to add.
3. **Smart Search**: Type in English or regional language (e.g., `Atta` or `आटा`). Matches by name, SKU, or HSN.

### 2.2 Adding Special Industry Fields
- **Restaurant Table**: Tap **Custom Fields** $\rightarrow$ Enter Table Number (e.g., `Table 04`).
- **Pharma Batch / Expiry**: Select medicine $\rightarrow$ Enter Batch Number (e.g., `B-902`) and Expiry (e.g., `11/27`).
- **Electronics IMEI**: Enter 15-digit IMEI or Serial Number to print warranty tracking on the customer's receipt.

### 2.3 Payment Settlement Modes

| Mode | Procedure | Receipt Action |
|---|---|---|
| **Cash** | Enter cash tendered (e.g., ₹1,000 for a ₹780 bill). App computes change to return (**₹220.00**). | Pops cash drawer & prints bill. |
| **Dynamic UPI QR** | App shows dynamic NPCI QR on screen and customer prints it on the thermal slip. | Cashier verifies payment soundbox / notification $\rightarrow$ Confirms. |
| **Card / Bank POS** | Enter Card Auth / RRN code. | Prints card receipt record. |
| **Khata (Udhaar)** | Select existing customer or enter mobile number $\rightarrow$ Adds amount directly to customer's ledger. | WhatsApp receipt link sent automatically. |
| **Split Payment** | Split between multiple modes (e.g. ₹500 Cash + ₹748 UPI). | Itemized breakdown printed on bill. |

---

## 3. Khata (Customer & Supplier Udhaar Ledger)

BharatHisab maintains a zero-error, double-sided ledger (Bahi Khata) replacing paper notebooks.

### 3.1 Recording Customer Udhaar
1. Navigate to the **Khata** tab in the bottom navigation bar.
2. Search customer by Name or Mobile Number.
3. Tap **"Gave Credit (Maine Diya)"** to record Udhaar, or **"Received Payment (Mujhe Mila)"** when customer pays back.
4. The net balance updates instantly with timestamp and cashier audit trail.

### 3.2 1-Click WhatsApp Payment Reminders
1. Open the customer's Khata ledger card.
2. Tap the green **"Send WhatsApp Reminder"** button.
3. BharatHisab pre-fills a polite, regional language reminder with the customer's name, total outstanding dues, and a **clickable NPCI UPI payment link**:
   > *"Namaste Rahul ji, your outstanding bill at Apna Bazaar is Rs. 850.00. Please clear your dues using this UPI link: upi://pay?pa=store@upi&am=850.00. Dhanyawad!"*

---

## 4. Stock & Inventory Management

### 4.1 Low-Stock Warnings & Velocity Alerts
- The inventory catalog automatically tags items:
  - 🟢 **Fast-Moving**: High turnover items that should never stock out.
  - 🟡 **Low-Stock Alert**: Current inventory is below `lowStockThreshold`.
  - 🔴 **Out of Stock**: Cart prevents accidental over-billing.
  - ⚪ **Dead Stock**: Zero sales in past 30 days.

### 4.2 Barcode Label Printing
1. Go to **Inventory** $\rightarrow$ Tap **"Barcode Stickers"**.
2. Select products and enter quantity of sticker copies needed.
3. The app generates a 38mm × 25mm barcode label PDF ready to feed into any thermal barcode sticker printer (TVS, TSC, Zebra).

---

## 5. Dhanda AI & Online Dukan

### 5.1 Publishing Products to Online Dukan
1. In the product edit screen, toggle **"Show on Online Dukan"** to ON.
2. Go to **Dukan** tab $\rightarrow$ Tap **"Share Storefront Link"**.
3. Customers can browse your catalog, build carts, and send instant WhatsApp orders to your store's phone.

### 5.2 Dhanda AI Google Business Profile Audit
1. Tap the **Dhanda AI** tab.
2. Review your store's **Health Score (0-100)** based on customer reviews, photo updates, and response rates.
3. Tap **"Auto-Reply with AI"** on any negative or positive Google review to generate an empathetic, professional reply in seconds.

---

## 6. End-of-Day Shift Closing (Z-Report)

At the end of business hours, the Store Manager prints the **Shift Closing Z-Report**:
1. Open **Reports** $\rightarrow$ Select **"Cashier Shift Register"**.
2. Compare physical cash counted in drawer against system expected cash.
3. Tap **"Close Shift & Print Summary"**.
4. The thermal printer prints the daily summary slip showing:
   - Total Gross Sales & Invoices Count
   - Cash Collected vs UPI vs Card vs Udhaar
   - Total GST Collected (CGST + SGST + IGST)
   - Discrepancy delta (Overage / Shortage)

---

For hardware troubleshooting and printer pairing, refer to the [Hardware Integration Manual](../hardware/HARDWARE_INTEGRATION_MANUAL.md).
