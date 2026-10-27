import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Storefront Activation State
  bool _isDukanActive = true;

  // Review Reply State
  final TextEditingController _reviewCustCtrl = TextEditingController(text: 'Sunil Rao');
  final TextEditingController _reviewTextCtrl = TextEditingController(text: 'Great experience shopping here! Clean shop and fresh goods.');
  int _reviewStarRating = 5;
  String _generatedReply = '';

  // Dhanda AI Audit State
  int _simulatedReviews = 84;
  final double _simulatedRating = 4.6;
  int _simulatedPosts = 4;
  final int _simulatedPhotos = 22;
  late GbpAuditReport _auditReport;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _dukanManager = OnlineDukanStorefrontManager(repository: widget.repository);
    _runDhandaAiAudit();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _reviewCustCtrl.dispose();
    _reviewTextCtrl.dispose();
    super.dispose();
  }

  void _runDhandaAiAudit() {
    _auditReport = DhandaAiMarketingSuite.auditGoogleBusinessProfile(
      storeProfile: widget.storeProfile,
      totalGoogleReviews: _simulatedReviews,
      averageStarRating: _simulatedRating,
      monthlyPostsCount: _simulatedPosts,
      uploadedPhotosCount: _simulatedPhotos,
      isGstinVerified: widget.storeProfile.isGstRegistered,
    );
  }

  String get _dukanUrl => 'https://bharathisab.in/dukan/${widget.storeProfile.id}';

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
    final allProducts = widget.repository.getAllProducts();
    final catalog = allProducts.where((p) => p.showOnOnlineDukan).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storefront Activation & Share Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDukanActive ? const Color(0xFF065F46) : const Color(0xFF374151), // Emerald vs Slate Gray
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (_isDukanActive ? const Color(0xFF065F46) : Colors.black).withValues(alpha: 0.2),
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
                            _isDukanActive ? 'WhatsApp Online Dukan is LIVE!' : 'Online Dukan is PAUSED',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _dukanUrl,
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
                    // Dukan Activation Switch
                    Switch(
                      value: _isDukanActive,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.black38,
                      onChanged: (val) {
                        setState(() => _isDukanActive = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? '🟢 WhatsApp Online Dukan is now ACTIVE and receiving orders!' : '⏸️ Online Dukan is now PAUSED.'),
                            backgroundColor: val ? const Color(0xFF065F46) : const Color(0xFF374151),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Copy Store Link & Share WhatsApp Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF065F46),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(LucideIcons.copy, size: 14),
                        label: Text(
                          'Copy Store Link',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _handleCopyStoreLink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(LucideIcons.share2, size: 14),
                        label: Text(
                          'Share on WhatsApp',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _handleShareOnWhatsApp,
                      ),
                    ),
                  ],
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
                'Live Dukan Catalog Products (${catalog.length})',
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

          allProducts.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: EzoColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EzoColors.border),
                  ),
                  child: Center(
                    child: Text('No inventory products yet. Add items in Catalog first.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final p = allProducts[idx];
                    return Container(
                      color: EzoColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: p.showOnOnlineDukan ? EzoColors.primaryLight : EzoColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: p.showOnOnlineDukan ? EzoColors.primary : EzoColors.textMuted,
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
                                    color: p.showOnOnlineDukan ? EzoColors.textPrimary : EzoColors.textMuted,
                                  ),
                                ),
                                Text(
                                  'MRP: ₹${p.mrp.toInt()} • Cat: ${p.category}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Offer ₹${p.sellingPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: p.showOnOnlineDukan ? EzoColors.success : EzoColors.textMuted,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Toggle switch for individual product on online dukan
                          Switch(
                            value: p.showOnOnlineDukan,
                            activeThumbColor: EzoColors.primary,
                            onChanged: (val) async {
                              final updated = p.copyWith(showOnOnlineDukan: val);
                              await widget.repository.upsertProduct(updated);
                              setState(() {});
                            },
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

  void _handleCopyStoreLink() {
    Clipboard.setData(ClipboardData(text: _dukanUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Online Dukan link copied to clipboard: $_dukanUrl'),
        backgroundColor: const Color(0xFF065F46),
      ),
    );
  }

  void _handleShareOnWhatsApp() {
    final catalog = _dukanManager.getDukanCatalog();
    final message = '''
🙏 Namaste!
Now order fresh groceries & daily items online from *${widget.storeProfile.storeName}*! 🛒

👉 View our 24x7 WhatsApp Catalog (${catalog.length} items):
$_dukanUrl

⚡ Fast Delivery & Store Pickup Available!
Thank you for shopping with *${widget.storeProfile.storeName}*.
''';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WhatsApp store announcement text copied to clipboard! Ready to send to customer broadcast list.'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  Widget _buildDhandaAiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GBP Score Card with Re-audit Button
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
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _auditReport.overallScore / 100.0,
                            strokeWidth: 7,
                            backgroundColor: EzoColors.surfaceSecondary,
                            color: EzoColors.success,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_auditReport.overallScore}',
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
                            'Google Business Profile Score',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _auditReport.estimatedRank.description,
                            style: GoogleFonts.plusJakartaSans(color: EzoColors.success, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Completeness: ${_auditReport.profileCompletenessScore}/25\nReviews: ${_auditReport.reviewsAndRatingScore}/25 • Posts: ${_auditReport.postFrequencyScore}/25',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EzoColors.textMuted, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.sparkles, size: 14),
                    label: const Text('Run Dhanda AI Audit & Re-Evaluate GBP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _simulatedReviews += 2;
                        _simulatedPosts += 1;
                        _runDhandaAiAudit();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✨ Dhanda AI GBP Audit complete! Score: ${_auditReport.overallScore}/100'),
                          backgroundColor: EzoColors.success,
                        ),
                      );
                    },
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
          ..._auditReport.prioritizedActionPlan.map((action) => Padding(
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
                        initialValue: _reviewStarRating,
                        decoration: const InputDecoration(labelText: 'Rating'),
                        items: [5, 4, 3, 2, 1].map((s) => DropdownMenuItem(value: s, child: Text('$s ⭐'))).toList(),
                        onChanged: (s) => setState(() => _reviewStarRating = s ?? 5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewTextCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                  decoration: const InputDecoration(labelText: 'Customer Review Text'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.bot, size: 14),
                    label: const Text('Generate AI Review Reply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      setState(() {
                        _generatedReply = DhandaAiMarketingSuite.generateReviewReply(
                          customerName: _reviewCustCtrl.text.isNotEmpty ? _reviewCustCtrl.text : 'Customer',
                          starRating: _reviewStarRating,
                          reviewText: _reviewTextCtrl.text.isNotEmpty ? _reviewTextCtrl.text : 'Good store',
                          storeName: widget.storeProfile.storeName,
                          storeCategory: 'Kirana & Supermarket',
                        );
                      });
                    },
                  ),
                ),
                if (_generatedReply.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EzoColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EzoColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          _generatedReply,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textPrimary, height: 1.35),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            icon: const Icon(LucideIcons.copy, size: 13),
                            label: const Text('Copy Reply'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _generatedReply));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AI review reply copied to clipboard!')),
                              );
                            },
                          ),
                        ),
                      ],
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

          // NearSearch Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.refreshCw, size: 13),
                  label: const Text('Refresh Local SEO Tags'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('NearSearch GEO Score updated: ${readiness.score}/100')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.copy, size: 13),
                  label: const Text('Copy JSON-LD Tags'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonLd));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('LocalBusiness JSON-LD Schema copied to clipboard!')),
                    );
                  },
                ),
              ),
            ],
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
