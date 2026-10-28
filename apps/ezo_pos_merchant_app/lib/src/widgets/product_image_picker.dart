import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/ezo_theme.dart';
import '../theme/google_fonts.dart';

class ProductImagePreset {
  final String label;
  final String category;
  final String imageUrl;
  final IconData fallbackIcon;

  const ProductImagePreset({
    required this.label,
    required this.category,
    required this.imageUrl,
    required this.fallbackIcon,
  });
}

class ProductImagePicker extends StatelessWidget {
  final String currentImageUrl;
  final ValueChanged<String> onImageChanged;
  final double height;

  const ProductImagePicker({
    super.key,
    required this.currentImageUrl,
    required this.onImageChanged,
    this.height = 90,
  });

  static const List<ProductImagePreset> defaultPresets = [
    ProductImagePreset(
      label: 'Atta / Flour',
      category: 'Groceries',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.wheat,
    ),
    ProductImagePreset(
      label: 'Rice & Pulses',
      category: 'Groceries',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.container,
    ),
    ProductImagePreset(
      label: 'Milk & Dairy',
      category: 'Dairy',
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.milk,
    ),
    ProductImagePreset(
      label: 'Cooking Oil',
      category: 'Groceries',
      imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.droplets,
    ),
    ProductImagePreset(
      label: 'Biscuits / Snacks',
      category: 'Snacks',
      imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.cookie,
    ),
    ProductImagePreset(
      label: 'Tea & Coffee',
      category: 'Beverages',
      imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.cupSoda,
    ),
    ProductImagePreset(
      label: 'Spices / Masala',
      category: 'Groceries',
      imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.flame,
    ),
    ProductImagePreset(
      label: 'Soaps / Cleaners',
      category: 'Personal Care',
      imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.sparkles,
    ),
    ProductImagePreset(
      label: 'Medicine / Pharma',
      category: 'Pharmacy',
      imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.pill,
    ),
    ProductImagePreset(
      label: 'Apparel / Garments',
      category: 'Apparel',
      imageUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.shirt,
    ),
    ProductImagePreset(
      label: 'Mobile / Gadget',
      category: 'Electronics',
      imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02560?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.smartphone,
    ),
    ProductImagePreset(
      label: 'Fresh Produce',
      category: 'Produce',
      imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=300&q=80',
      fallbackIcon: LucideIcons.apple,
    ),
  ];

  void _showImagePickerSheet(BuildContext context) {
    final urlCtrl = TextEditingController(text: currentImageUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 14,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EzoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attach Product Image',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: EzoColors.textPrimary,
                    ),
                  ),
                  if (currentImageUrl.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: EzoColors.error),
                      icon: const Icon(LucideIcons.trash2, size: 14),
                      label: const Text('Remove Photo', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        onImageChanged('');
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Action 1: Capture Photo via Device Camera
              InkWell(
                onTap: () {
                  // Simulate live camera snapshot capture
                  final simulatedSnap = 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80';
                  onImageChanged(simulatedSnap);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📷 Product photo captured and attached!'),
                      backgroundColor: EzoColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: EzoColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EzoColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EzoColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capture with Camera',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: EzoColors.primary),
                            ),
                            Text(
                              'Take a quick photo of the product on shelf',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: EzoColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action 2: Enter Web URL or Cloud Link
              Container(
                decoration: BoxDecoration(
                  color: EzoColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EzoColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Row(
                  children: [
                    const Icon(LucideIcons.link, size: 16, color: EzoColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: urlCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Paste image URL or web image link...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(50, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        if (urlCtrl.text.trim().isNotEmpty) {
                          onImageChanged(urlCtrl.text.trim());
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action 3: Choose from Curated Retail Presets
              Text(
                'Or Choose Instant Retail Catalog Preset:',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textMuted),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 180,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: defaultPresets.length,
                  itemBuilder: (context, idx) {
                    final p = defaultPresets[idx];
                    return InkWell(
                      onTap: () {
                        onImageChanged(p.imageUrl);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: EzoColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: EzoColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(p.fallbackIcon, size: 20, color: EzoColors.primary),
                            const SizedBox(height: 4),
                            Text(
                              p.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentImageUrl.isEmpty) {
      return InkWell(
        onTap: () => _showImagePickerSheet(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: EzoColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EzoColors.border,
              style: BorderStyle.solid,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EzoColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera, color: EzoColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+ Upload / Capture Product Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: EzoColors.primary,
                    ),
                  ),
                  Text(
                    'Camera, gallery, or instant catalog preset',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: EzoColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Has image: Show preview card with edit and delete controls
    return Container(
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: EzoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EzoColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: height - 12,
              height: height - 12,
              child: Image.network(
                currentImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: EzoColors.primaryLight,
                  child: const Center(
                    child: Icon(LucideIcons.image, color: EzoColors.primary, size: 22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: EzoColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Photo Attached',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: EzoColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Visible on Online Dukan & Billing shelf',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EzoColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              foregroundColor: EzoColors.primary,
            ),
            icon: const Icon(LucideIcons.edit2, size: 13),
            label: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            onPressed: () => _showImagePickerSheet(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: EzoColors.error, size: 15),
            tooltip: 'Remove',
            onPressed: () => onImageChanged(''),
          ),
        ],
      ),
    );
  }
}
