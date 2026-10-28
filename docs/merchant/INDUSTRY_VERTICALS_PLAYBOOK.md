# Industry Verticals Playbook

BharatHisab POS features an interactive **First-Launch Industry Onboarding Wizard** that configures custom tax categories, default hardware profiles, receipt templates, and sample inventory catalogs tailored to 5 major Indian retail sectors.

---

## 1. Kirana, Supermarket & Grocery (`kiranaGrocery`)

Designed for general provision stores, hypermarkets, and departmental stores.

```
┌──────────────────────────────────────────────────────────────┐
│ 🛒 Kirana & Supermarket                                       │
│ • Loose items weighing scale integration (KG / GMS)          │
│ • Zero-tax staples (Atta, Rice, Pulses) + 5%/12%/18% FMCG    │
│ • Fast multi-pack barcode scanning                           │
│ • Daily Bahi Khata Udhaar ledger                             │
└──────────────────────────────────────────────────────────────┘
```

### Key Configurations:
- **Default Hardware**: 58mm Chota or 80mm Bada Bluetooth Thermal Printer + USB Barcode Scanner + RS-232 Weighing Scale.
- **Tax Rules**: Multi-slab GST (0% on unpackaged grains, 5% on packaged staples, 12% on dairy/ghee, 18% on personal care/detergents).
- **Default Categories**: *Staples & Grains*, *Dairy & Eggs*, *Oils & Ghee*, *Snacks & Biscuits*, *Beverages*, *Cleaning & Hygiene*.
- **Sample Seeded Catalog**: Fortune Sunlite Oil 1L, Aashirvaad Shudh Chakki Atta 5kg, Tata Salt 1kg, Amul Butter 500g, Maggi 2-Minute Noodles 280g.
- **Operational Workflow**: Fast barcode scanning $\rightarrow$ Weighing scale input for loose rice/sugar $\rightarrow$ Cash / Dynamic UPI QR settlement $\rightarrow$ "You Saved Rs. X" printout.

---

## 2. Restaurant, Cafe & QSR (`restaurantCafe`)

Designed for dine-in restaurants, quick-service cafes, bakeries, and cloud kitchens.

```
┌──────────────────────────────────────────────────────────────┐
│ 🍽️ Restaurant & Cafe                                          │
│ • Table numbers, Room orders, and Takeaway / Delivery tags   │
│ • Instant Kitchen Order Ticket (KOT) thermal slips           │
│ • 5% GST Restaurant Rate (Without ITC)                       │
│ • Split bills across group diners                            │
└──────────────────────────────────────────────────────────────┘
```

### Key Configurations:
- **Default Hardware**: 80mm Bada Main POS Counter Printer + 58mm/80mm Network Kitchen Printer (KOT) + Cash Drawer.
- **Tax Rules**: 5% GST (2.5% CGST + 2.5% SGST) flat on food & beverage services without input tax credit (ITC).
- **Default Categories**: *Starters & Appetizers*, *Main Course*, *Breads & Rice*, *Beverages & Shakes*, *Desserts*.
- **Sample Seeded Catalog**: Paneer Butter Masala, Butter Naan, Veg Dum Biryani, Cold Coffee with Ice Cream, Gulab Jamun (2 pcs).
- **Operational Workflow**: Captain takes order $\rightarrow$ Enters Table Number $\rightarrow$ App dispatches KOT to Kitchen $\rightarrow$ Additional rounds added $\rightarrow$ Table bill requested $\rightarrow$ Discount/Split $\rightarrow$ Receipt with dynamic UPI QR.

---

## 3. Pharmacy & Healthcare Store (`pharmacyHealth`)

Designed for medical stores, chemist shops, clinics, and surgical distributors.

```
┌──────────────────────────────────────────────────────────────┐
│ 💊 Pharmacy & Healthcare                                      │
│ • Mandatory Batch Number & Expiry Date tracking              │
│ • Near-expiry stock alerts (30/60/90 days warning)           │
│ • Schedule H / Narcotic prescription doctor tag              │
│ • Strip vs Tablet loose cutting                              │
└──────────────────────────────────────────────────────────────┘
```

### Key Configurations:
- **Default Hardware**: A5 Landscape Laser / Thermal Printer (for itemized batch reports) or 80mm Thermal Printer.
- **Tax Rules**: 12% GST on general pharmaceuticals; 5% on critical life-saving drugs; 18% on dietary supplements.
- **Default Categories**: *Pain & Fever*, *Antibiotics*, *Vitamins & Supplements*, *First Aid & Surgical*, *Baby Care*.
- **Sample Seeded Catalog**: Dolo 650 Strip (15 Tabs), Augmentin 625 Duo, Becosules Z Capsules, Dettol Antiseptic Liquid 250ml, Digital Thermometer.
- **Operational Workflow**: Scan medicine barcode $\rightarrow$ Confirm Batch Number & Expiry Date $\rightarrow$ Enter Prescribing Doctor Name $\rightarrow$ Print bill compliant with state Drug Controller standards.

---

## 4. Garments & Apparel Store (`garmentsApparel`)

Designed for clothing boutiques, shoe stores, textile shops, and fashion retail.

```
┌──────────────────────────────────────────────────────────────┐
│ 👕 Garments & Apparel                                         │
│ • Size & Color Variant Matrix (S / M / L / XL / XXL)         │
│ • 38mm x 25mm Barcode Tag / Sticker printing                 │
│ • Tiered GST: 5% (Value < ₹1,000) vs 12% (Value ≥ ₹1,000)    │
│ • Seasonal clearance discount campaigns                      │
└──────────────────────────────────────────────────────────────┘
```

### Key Configurations:
- **Default Hardware**: 80mm Thermal Printer + 38mm × 25mm Thermal Barcode Tag Printer + Bluetooth Scanner.
- **Tax Rules**: Inverted duty structure rule: Apparel priced under ₹1,000 attracts 5% GST; apparel priced at or above ₹1,000 attracts 12% GST.
- **Default Categories**: *Men's Wear*, *Women's Ethnic*, *Kids Apparel*, *Footwear*, *Accessories*.
- **Sample Seeded Catalog**: Men's Slim Fit Cotton Shirt (Blue - L), Women's Rayon Kurti (Printed - M), Regular Fit Denim Jeans (32), Cotton Ankle Socks (Pack of 3).
- **Operational Workflow**: Tag items with custom printed barcode stickers $\rightarrow$ Scan size/color at checkout $\rightarrow$ Automatic tax bracket switching based on net piece price $\rightarrow$ Loyalty discounts.

---

## 5. Electronics, Mobiles & Hardware (`electronicsMobiles`)

Designed for smartphone stores, consumer electronics, computer hardware, and electrical shops.

```
┌──────────────────────────────────────────────────────────────┐
│ 📱 Electronics & Mobiles                                      │
│ • Serial Number & 15-Digit IMEI capture                      │
│ • Brand Warranty tracking on printed invoice                 │
│ • 18% & 28% GST brackets with B2B Input Tax Credit (ITC)     │
│ • Accessory cross-sell & financing split payments            │
└──────────────────────────────────────────────────────────────┘
```

### Key Configurations:
- **Default Hardware**: A4 Modern Laser Printer (for warranty documentation) + 80mm Bada Thermal Printer for quick accessories.
- **Tax Rules**: 18% GST on smartphones, accessories, and PC parts; 28% on air conditioners, large displays, and high-end consumer appliances.
- **Default Categories**: *Smartphones*, *Audio & Headphones*, *Cables & Chargers*, *Power Banks*, *Smart Wearables*.
- **Sample Seeded Catalog**: 65W Fast USB-C Charger, Bluetooth ANC Earbuds Pro, Braided Type-C Cable 1.5m, 10000mAh Power Bank, Smart Fitness Band 8.
- **Operational Workflow**: Add phone to cart $\rightarrow$ Scan or enter 15-digit IMEI $\rightarrow$ Upsell recommended screen guard / case $\rightarrow$ Record B2B customer GSTIN for input credit $\rightarrow$ Print warranty-certified A4/Thermal invoice.

---

## 6. Live Interactive Switching & Dual Mode Support

BharatHisab provides seamless switching across all 5 industry verticals both at onboarding and dynamically during active billing:

### A. Visual Setup Onboarding Cards
During merchant sign up in [`MerchantAuthScreen`](../../apps/ezo_pos_merchant_app/lib/src/screens/merchant_auth_screen.dart), merchants are presented with an interactive 5-Vertical Grid containing dedicated color badges, icons, and capability highlights. Toggling off "Clean Slate" automatically pre-seeds the store with the industry-specific catalog and default categories.

### B. Header Mode Switcher Dropdown
In [`PosBillingScreen`](../../apps/ezo_pos_merchant_app/lib/src/screens/pos_billing_screen.dart), merchants can switch verticals at any time via the quick-switch button in the top app bar (`[ 🛒 Kirana & Grocery ▾ ]`). The switcher offers two options:
1. **Switch Mode & Load Sample Items**: Clears cart and populates the counter with the target vertical's pre-seeded catalog.
2. **Switch Mode (Keep Current Items)**: Keeps existing cart and catalog while dynamically updating the action bar, theme accents, and receipt layouts.

### C. Vertical-Specific Dynamic Action Bars & Micro-Interactions
- **🛒 Kirana**: Live digital scale sync button (`⚖️ Read Scale`), Bag Charge toggle (`🛍️ Bag Charge`), Quick staples numpad.
- **🍽️ Restaurant**: Table Selector pills (`T-01` to `T-12`, `Takeaway`), `🍳 Send / Print KOT` instant kitchen dispatch slip modal.
- **💊 Pharmacy**: Prescribing Doctor & Patient modal (`🩺 Rx Doctor`), Schedule H narcotic compliance warnings, Batch & Expiry date indicators.
- **👕 Garments**: Size matrix chips (`XS`, `S`, `M`, `L`, `XL`, `XXL`), Color chips (`Black`, `Navy`, `Olive`, etc.), `🏷️ Print Barcode Tag (38x25mm)` sticker dialog.
- **📱 Electronics**: 15-digit IMEI / Serial number validation prompt (`📱 Add IMEI / Serial`), Printed 1-Year Warranty Certificate banner.

---

To run or test the onboarding wizard, open [`apps/ezo_pos_merchant_app/lib/src/screens/industry_onboarding_wizard_screen.dart`](../../apps/ezo_pos_merchant_app/lib/src/screens/industry_onboarding_wizard_screen.dart) or switch directly within the main billing counter.
