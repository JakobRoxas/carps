import 'event_models.dart';

/// Per-guest attendance history entry (distinguishes bookings from arrivals).
enum HistoryState { checkedIn, noShow, booked, cancelled }

class HistoryEntry {
  const HistoryEntry({
    required this.event,
    required this.state,
    this.arrivedAt,
    this.canPost = false,
    this.canReview = false,
    this.hasReviewed = false,
  });

  final CarpsEvent event;
  final HistoryState state;
  final DateTime? arrivedAt;
  final bool canPost;
  final bool canReview;
  final bool hasReviewed;
}

class HostAnalytics {
  const HostAnalytics({
    required this.confirmedAtStart,
    required this.arrivals,
    required this.postCount,
    required this.commentCount,
    required this.reviewCount,
    required this.ratingBreakdown,
    required this.pendingCount,
  });

  final int confirmedAtStart;
  final int arrivals;
  final int postCount;
  final int commentCount;
  final int reviewCount;
  final int pendingCount;

  /// index 0 = 1 star … index 4 = 5 stars.
  final List<int> ratingBreakdown;

  /// null means "Not available" (zero denominator).
  double? get turnout =>
      confirmedAtStart == 0 ? null : arrivals / confirmedAtStart;

  /// null means "No reviews yet".
  double? get averageRating {
    if (reviewCount == 0) return null;
    var total = 0;
    for (var i = 0; i < 5; i++) {
      total += ratingBreakdown[i] * (i + 1);
    }
    return total / reviewCount;
  }
}
