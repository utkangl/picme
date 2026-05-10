import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the smart in-app review prompt.
///
/// The prompt is triggered once after the user completes their 2nd successful
/// bulk delete, ensuring they have experienced genuine value before being asked
/// to rate the app.
class ReviewPrompter {
  static const _keyBatches = 'picme_total_delete_batches';
  static const _keyPrompted = 'picme_review_prompted';
  static const _batchThreshold = 2;

  /// Records a completed delete batch and, if conditions are met, shows the
  /// in-app review dialog exactly once.
  ///
  /// Returns true if the review dialog was requested this call.
  static Future<bool> recordBatchAndMaybePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final batches = (prefs.getInt(_keyBatches) ?? 0) + 1;
    await prefs.setInt(_keyBatches, batches);

    final alreadyPrompted = prefs.getBool(_keyPrompted) ?? false;
    if (alreadyPrompted) return false;
    if (batches < _batchThreshold) return false;

    final review = InAppReview.instance;
    if (!await review.isAvailable()) return false;

    await review.requestReview();
    await prefs.setBool(_keyPrompted, true);
    return true;
  }

  /// Opens the Play Store / App Store listing unconditionally. Useful as a
  /// fallback from the settings "Rate" tile when the in-app dialog isn't
  /// available.
  static Future<void> openStoreListing() async {
    await InAppReview.instance.openStoreListing();
  }

  /// Attempts to show the in-app review dialog immediately (e.g. from
  /// settings). Falls back to [openStoreListing] if not available.
  static Future<void> requestReviewOrOpenStore() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  }
}
