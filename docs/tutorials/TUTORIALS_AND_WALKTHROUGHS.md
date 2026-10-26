# Step-by-Step Tutorials & Walkthroughs

This document contains 5 hands-on tutorials guiding you from initial store setup to advanced AI marketing and printing.

---

## Tutorial 1: Quickstart — Creating a Real Store & First Bill from Clean Slate

### Objective:
Set up a clean merchant account, add a real SKU at the counter, and generate your first customer bill with thermal printout.

### Steps:
1. **Launch & Account Sign Up**:
   - Open BharatHisab on Android or browser ([http://localhost:8090](http://localhost:8090)).
   - In the **Create Merchant Business Account** form:
     - Store Name: `Shree Ganesh Supermarket`
     - Owner Name: `Ramanuj Sarkar`
     - Mobile Phone: `9876543210`
     - 4-Digit Quick PIN: `1234`
     - State: `27 - Maharashtra`
     - Vertical: `Kirana & Supermarket`
     - Check: **"Start with 100% Clean Slate (0 products, clean ledger)"**
     - Tap **"Launch Business Counter"**.
2. **Arrive at Clean Counter**:
   - You arrive at your billing screen with **0 dummy items**.
3. **Add First Product SKU**:
   - Tap **`+ Add Your First Product SKU`** on screen (or **`+ Add SKU`** in the search toolbar).
   - Name: `Tata Salt 1kg`
   - Barcode/SKU: `8901030383794` (or leave blank to auto-generate)
   - MRP: `₹28`
   - Sale Price: `₹26`
   - GST Slab: `0% (Exempt)`
   - Stock Qty: `50`
   - Tap **"Add SKU to Shelf"**. The product immediately appears on your counter!
   *(Optional: If you ever want instant test data, tap `⚡ Quick-Load 10 Essential Staples` to load 10 common items).*
4. **Bill the Item**:
   - Tap `Tata Salt 1kg` to add it to the cart.
   - Notice the cart automatically updates: Subtotal, CGST, SGST, Round-off, and **You Saved ₹2.00**.
5. **Settle Transaction**:
   - Tap **"Charge / Bill (F12)"** $\rightarrow$ Select **Cash** $\rightarrow$ Enter Received: `₹50`.
   - The app computes change: `₹24.00` and generates the thermal receipt.
6. **Lock Register or Reset Slate**:
   - Tap the Cashier profile badge on the top bar $\rightarrow$ **"Lock Register & Switch Cashier"**.
   - To test onboarding from scratch again, go to **Settings** $\rightarrow$ **Session & Store Management** $\rightarrow$ **"Reset Clean Slate"**.

---

## Tutorial 2: Setting Up Thermal Printing (Bluetooth & USB)

### Objective:
Pair a 58mm (Chota) or 80mm (Bada) thermal printer with your Android device or Windows PC.

### Part A: Android Bluetooth Pairing
1. Power on your Bluetooth thermal printer (e.g. *MPT-II*, *Sunmi*, or *RP-3200*).
2. Open Android **Settings** $\rightarrow$ **Bluetooth** $\rightarrow$ Scan for devices.
3. Select your printer and enter PIN: `0000` or `1234`.
4. Open **BharatHisab POS** $\rightarrow$ Tap **Settings** (Gear icon) $\rightarrow$ **Printer Settings**.
5. Select **Bluetooth**, pick your paired device from the list, and tap **"Print Test Slip"**.

### Part B: Windows USB-OTG Setup
1. Connect printer via USB cable.
2. In Windows **Printers & Scanners**, verify the printer appears (e.g. *POS-80* or *Generic / Text Only*).
3. In **BharatHisab POS**, select **USB RAW Printing** and choose the COM port or USB printer endpoint.

---

## Tutorial 3: Collecting Customer Udhaar via UPI & WhatsApp

### Objective:
Record an Udhaar entry for a regular customer and send an instant vernacular WhatsApp reminder with a dynamic NPCI UPI payment link.

### Steps:
1. **Record the Credit Sale**:
   - In POS Billing, add items to cart.
   - In payment mode, select **"Udhaar (Khata)"**.
   - Tap **"Select Customer"** $\rightarrow$ Pick *Ramesh Sharma* (Balance: ₹400).
   - Tap **"Confirm Udhaar Bill"**. The new bill amount (₹650) is added to his ledger; his new balance is ₹1,050.
2. **Open the Customer's Khata Bahi**:
   - Tap the **Khata** icon on the bottom navigation bar.
   - Select *Ramesh Sharma*. You will see the complete double-sided statement with debit entries, credit entries, and dates.
3. **Send 1-Click WhatsApp Reminder**:
   - Tap **"Send WhatsApp Reminder"**.
   - Choose language: **Hindi** (or English/Marathi/Bengali/etc.).
   - Tap **"Open WhatsApp"**. BharatHisab opens WhatsApp with the pre-composed text:
     > *"नमस्ते Ramesh Sharma जी, Apna Super Bazaar पर आपका कुल उधार ₹1,050.00 है। तुरंत भुगतान करने के लिए इस UPI लिंक पर क्लिक करें: upi://pay?pa=apnabazaar@upi&am=1050.00"*
4. **Record Settlement**:
   - When the customer pays, tap **"Received Payment (Mujhe Mila)"**, enter ₹1,050, select Mode **UPI**, and tap Save. The balance resets to **₹0.00**.

---

## Tutorial 4: Running a Seasonal Clearance Sale with Barcode Stickers

### Objective:
Generate and print custom 38mm × 25mm barcode stickers for apparel or retail items.

### Steps:
1. **Navigate to Barcode Generator**:
   - Open **Inventory** tab $\rightarrow$ Tap **"Barcode Stickers & Labels"**.
2. **Select SKUs**:
   - Check *Men's Slim Fit Cotton Shirt (Blue - L)* and *Denim Jeans (32)*.
3. **Configure Copies & Discount Callout**:
   - Set Copies: `30 copies each`.
   - Toggle **"Print MRP & Discount Offer"** to ON (e.g. *MRP ₹1,299 | Offer Price ₹899*).
4. **Print Stickers**:
   - Tap **"Generate Sticker PDF"**.
   - Send to your 203 DPI barcode label roll printer.
   - Affix stickers to physical garment tags for 1-second checkout scanning.

---

## Tutorial 5: Boosting Local Footfall with Dhanda AI & SEO Schemas

### Objective:
Audit your store's Google Business Profile, reply to reviews using AI, and generate NearSearch Local SEO schema.

### Steps:
1. **Check Dhanda AI Score**:
   - Open **Dhanda AI** tab in BharatHisab POS.
   - View your store's **Google Health Score** (e.g. `84 / 100`).
   - Notice recommendations: *"Add 3 store interior photos"* and *"Reply to 2 pending reviews"*.
2. **Auto-Reply to Reviews**:
   - Scroll to **Pending Customer Reviews**.
   - Review: *"Good collection, but billing queue was slightly slow yesterday."*
   - Tap **"Generate AI Reply"**.
   - Dhanda AI creates a professional response:
     > *"Thank you for your visit and feedback, Vikas! We're glad you enjoyed our collection. We have recently upgraded to high-speed barcode billing at all counters to ensure zero waiting time on your next visit. Looking forward to welcoming you back soon!"*
   - Tap **"Copy & Post to Google"**.
3. **Publish NearSearch SEO Schema**:
   - Tap **"Generate NearSearch Schema"**.
   - The engine produces a complete JSON-LD `Store` schema containing your GSTIN, catalog categories, geo-coordinates, and operating hours for search engines.

---

For architectural details, refer to [Monorepo Architecture](../architecture/ARCHITECTURE.md).
