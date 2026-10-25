import 'package:flutter/material.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_online_dukan_ai/ezo_online_dukan_ai.dart';
import '../theme/ezo_theme.dart';

class OnlineDukanDhandaScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;

  const OnlineDukanDhandaScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
  });

  @override
  State<OnlineDukanDhandaScreen> createState() => _OnlineDukanDhandaScreenState();
}

class _OnlineDukanDhandaScreenState extends State<OnlineDukanDhandaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late OnlineDukanStorefrontManager _dukanManager;

  // Review Reply State
  final TextEditingController _reviewCustCtrl = TextEditingController(text: 'Sunil Rao');
  int _reviewStarRating = 5;
  String _generatedReply = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _dukanManager = OnlineDukanStorefrontManager(repository: widget.repository);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EzoColors.background,
      body: Column(
        children: [
          Container(
            height: 44,
            decoration: const BoxDecoration(
              color: EzoColors.surface,
              border: Border(bottom: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: EzoColors.primary,
              unselectedLabelColor: EzoColors.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
              indicatorColor: EzoColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'WhatsApp Store'),
                Tab(text: 'Dhanda AI GBP'),
                Tab(text: 'NearSearch SEO'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOnlineDukanTab(),
                _buildDhandaAiTab(),
                _buildNearSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineDukanTab() {
    final catalog = _dukanManager.getDukanCatalog();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storefront Share Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46), // Deep Emerald
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF065F46).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.store, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Online Dukan is LIVE!',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'https://in.co.ezo/dukan/${widget.storeProfile.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF065F46),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(LucideIcons.share2, size: 14),
                    label: Text(
                      'Share Store Link on WhatsApp',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Online Dukan link copied to clipboard!'),
                          backgroundColor: Color(0xFF065F46),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Products Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Catalog Products (${catalog.length})',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EzoColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${catalog.length} items live',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: EzoColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: catalog.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final p = catalog[idx];
              return Container(
                color: EzoColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: EzoColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          p.name.isNotEmpty ? p.name[0] : 'P',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: EzoColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: EzoColors.textPrimary,
                            ),
                          ),
                          Text(
                            'MRP: ₹${p.mrp.toInt()} • Category: ${p.category}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Offer ₹${p.sellingPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: EzoColors.success,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDhandaAiTab() {
    final audit = DhandaAiMarketingSuite.auditGoogleBusinessProfile(
      storeProfile: widget.storeProfile,
      totalGoogleReviews: 84,
      averageStarRating: 4.6,
      monthlyPostsCount: 4,
      uploadedPhotosCount: 22,
      isGstinVerified: true,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GBP Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EzoColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: audit.overallScore / 100.0,
                        strokeWidth: 7,
                        backgroundColor: EzoColors.surfaceSecondary,
                        color: EzoColors.success,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${audit.overallScore}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: EzoColors.textPrimary),
                        ),
                        Text(
                          '/100',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EzoColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Business Score',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Top 3 Google Maps Pack (High Footfall)',
                        style: GoogleFonts.plusJakartaSans(color: EzoColors.success, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Completeness: ${audit.profileCompletenessScore}/25\nReviews: ${audit.reviewsAndRatingScore}/25 • Posts: ${audit.postFrequencyScore}/25',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EzoColors.textMuted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Plan
          Text(
            'Prioritized AI Growth Plan',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...audit.prioritizedActionPlan.map((action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: EzoColors.primary, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // AI Review Reply Generator Tool
          Text(
            'AI Google Review Reply Generator',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _reviewCustCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Reviewer Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        value: _reviewStarRating,
                        decoration: const InputDecoration(labelText: 'Rating'),
                        items: [5, 4, 3, 2, 1].map((s) => DropdownMenuItem(value: s, child: Text('$s ⭐'))).toList(),
                        onChanged: (s) => setState(() => _reviewStarRating = s ?? 5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.sparkles, size: 14),
                    label: const Text('Generate Review Reply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      setState(() {
                        _generatedReply = DhandaAiMarketingSuite.generateReviewReply(
                          customerName: _reviewCustCtrl.text,
                          starRating: _reviewStarRating,
                          reviewText: 'Great experience shopping here!',
                          storeName: widget.storeProfile.storeName,
                          storeCategory: 'Supermarket',
                        );
                      });
                    },
                  ),
                ),
                if (_generatedReply.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EzoColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EzoColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _generatedReply,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textPrimary, height: 1.35),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearSearchTab() {
    final products = widget.repository.getAllProducts();
    final readiness = NearSearchGeoOptimizer.evaluateAiReadiness(widget.storeProfile, products);
    final jsonLd = NearSearchGeoOptimizer.generateJsonLdSchema(storeProfile: widget.storeProfile, products: products);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF), // Purple 50
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF), width: 1),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bot, size: 30, color: Color(0xFF7C3AED)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generative Engine Optimization (GEO)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF581C87)),
                      ),
                      Text(
                        'AI Search Readiness Score: ${readiness.score}/100',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Live JSON-LD LocalBusiness Schema (For ChatGPT, Claude & Gemini Bots):',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              jsonLd,
              style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF38BDF8), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
