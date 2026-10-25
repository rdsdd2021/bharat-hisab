import 'package:ezo_core_models/ezo_core_models.dart';

enum LocalPackRankEstimate {
  top3MapPack('Top 3 Google Maps Pack (High Footfall)'),
  rank4To8('Rank #4 - #8 (Moderate Footfall)'),
  belowRank10('Below Top 10 (Low Footfall - Needs Optimization)');

  final String description;
  const LocalPackRankEstimate(this.description);
}

class GbpAuditReport {
  final int overallScore; // 0 - 100
  final LocalPackRankEstimate estimatedRank;
  final int profileCompletenessScore; // max 25
  final int reviewsAndRatingScore; // max 25
  final int postFrequencyScore; // max 25
  final int mediaAndVerificationScore; // max 25
  final List<String> prioritizedActionPlan;

  const GbpAuditReport({
    required this.overallScore,
    required this.estimatedRank,
    required this.profileCompletenessScore,
    required this.reviewsAndRatingScore,
    required this.postFrequencyScore,
    required this.mediaAndVerificationScore,
    required this.prioritizedActionPlan,
  });
}

class CompetitorMetric {
  final String competitorName;
  final double starRating;
  final int reviewCount;
  final int estimatedMonthlyPhotos;

  const CompetitorMetric({
    required this.competitorName,
    required this.starRating,
    required this.reviewCount,
    required this.estimatedMonthlyPhotos,
  });
}

class DhandaAiMarketingSuite {
  /// 1. Google Business Profile (GBP) Score Auditor (0–100)
  static GbpAuditReport auditGoogleBusinessProfile({
    required BusinessProfile storeProfile,
    required int totalGoogleReviews,
    required double averageStarRating,
    required int monthlyPostsCount,
    required int uploadedPhotosCount,
    required bool isGstinVerified,
  }) {
    int profileScore = 0;
    if (storeProfile.storeName.isNotEmpty) profileScore += 5;
    if (storeProfile.address.isNotEmpty) profileScore += 5;
    if (storeProfile.phone.isNotEmpty) profileScore += 5;
    if (storeProfile.email.isNotEmpty) profileScore += 5;
    if (storeProfile.upiId.isNotEmpty) profileScore += 5;

    int reviewScore = 0;
    if (averageStarRating >= 4.5) {
      reviewScore += 15;
    } else if (averageStarRating >= 4.0) {
      reviewScore += 10;
    } else if (averageStarRating >= 3.0) {
      reviewScore += 5;
    }

    if (totalGoogleReviews >= 100) {
      reviewScore += 10;
    } else if (totalGoogleReviews >= 30) {
      reviewScore += 7;
    } else if (totalGoogleReviews >= 10) {
      reviewScore += 4;
    }

    int postScore = 0;
    if (monthlyPostsCount >= 8) {
      postScore = 25;
    } else if (monthlyPostsCount >= 4) {
      postScore = 18;
    } else if (monthlyPostsCount >= 1) {
      postScore = 10;
    }

    int mediaScore = 0;
    if (isGstinVerified) mediaScore += 10;
    if (uploadedPhotosCount >= 30) {
      mediaScore += 15;
    } else if (uploadedPhotosCount >= 10) {
      mediaScore += 10;
    } else if (uploadedPhotosCount >= 3) {
      mediaScore += 5;
    }

    final totalScore = profileScore + reviewScore + postScore + mediaScore;

    LocalPackRankEstimate rank;
    if (totalScore >= 80) {
      rank = LocalPackRankEstimate.top3MapPack;
    } else if (totalScore >= 50) {
      rank = LocalPackRankEstimate.rank4To8;
    } else {
      rank = LocalPackRankEstimate.belowRank10;
    }

    final List<String> plan = [];
    if (monthlyPostsCount < 4) {
      plan.add('Publish at least 1 promotional offer post every week using Dhanda AI generator.');
    }
    if (totalGoogleReviews < 50) {
      plan.add('Send 1-tap WhatsApp Google Review request links to every billed customer.');
    }
    if (uploadedPhotosCount < 20) {
      plan.add('Upload 10+ high-quality store interior, storefront, and top-product photos.');
    }
    if (!isGstinVerified && storeProfile.gstin.isNotEmpty) {
      plan.add('Verify GSTIN certificate on Google Business Profile for trust badge.');
    }
    if (plan.isEmpty) {
      plan.add('Profile is in Top 3 Map Pack rank! Maintain weekly posts to defend local dominance.');
    }

    return GbpAuditReport(
      overallScore: totalScore,
      estimatedRank: rank,
      profileCompletenessScore: profileScore,
      reviewsAndRatingScore: reviewScore,
      postFrequencyScore: postScore,
      mediaAndVerificationScore: mediaScore,
      prioritizedActionPlan: plan,
    );
  }

  /// 2. Local Keyword & Competitor Gap Analyzer
  static List<String> suggestLocalKeywords({
    required String storeCategory,
    required String cityOrArea,
  }) {
    final cat = storeCategory.trim();
    final loc = cityOrArea.trim();
    return [
      'Best $cat in $loc',
      '$cat shop near me',
      'Affordable $cat store $loc',
      'Wholesale and retail $cat $loc',
      'Top rated $cat dealer near me',
      'Open now $cat in $loc',
    ];
  }

  /// 3. AI Google Profile Offer Post & Festival Poster Generator
  static String generateFestivalPostCopy({
    required String storeName,
    required String festivalOrOccasion, // e.g., 'Diwali Mega Sale', 'Dussehra Special'
    required String discountOffer, // e.g., 'Flat 20% Off on all sweets'
    required String address,
    required String phone,
  }) {
    return '''
✨ Celebrate $festivalOrOccasion with $storeName! ✨

Special Festive Offer: $discountOffer! 🎁
Visit us today for genuine quality, fresh stock, and instant festive discounts.

📍 Location: $address
📞 Contact: $phone
⚡ Open 7 Days a week. Scan & Pay via UPI accepted!

#$festivalOrOccasion #$storeName #LocalOffers #BestDeals #FestiveSale
''';
  }

  /// 4. AI Google Review Reply Generator
  static String generateReviewReply({
    required String customerName,
    required int starRating,
    required String reviewText,
    required String storeName,
    required String storeCategory,
  }) {
    if (starRating >= 4) {
      // 4-5 Stars: Gratitude + Keyword Reinforcement for Google Maps SEO
      return 'Thank you so much for the wonderful 5-star rating, $customerName! '
          'We take great pride in being your trusted neighborhood $storeCategory at $storeName. '
          'We look forward to serving you again soon!';
    } else {
      // 1-3 Stars: Empathetic, Resolution-Oriented Reply
      return 'Hello $customerName, thank you for bringing this to our attention. '
          'At $storeName, customer satisfaction is our highest priority, and we deeply apologize that your experience did not meet expectations. '
          'Please contact our store manager directly so we can resolve this immediately for you.';
    }
  }
}
