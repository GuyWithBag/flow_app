# Ad Implementation Guide

This document provides instructions for replacing ad placeholders with real ads when your ad account is approved.

## Current Ad Placements

### 1. Banner Ad - Account Screen (Guest Users Only)
**File**: `lib/pages/account_screen.dart`  
**Line**: ~26-28  
**Current Code**:
```dart
const AdPlaceholder(height: 60),
```

**Replace With**: Your banner ad widget (e.g., Google AdMob BannerAd)
```dart
// Example with AdMob:
Container(
  height: 60,
  alignment: Alignment.center,
  child: AdWidget(ad: _bannerAd),
)
```

---

### 2. Interstitial Ads (50% probability)
**File**: `lib/shared/ad_helper.dart`  
**Method**: `_showInterstitialAdPlaceholder()`  
**Lines**: ~33-74

**Current Code**: Shows a placeholder dialog

**Replace With**: Real interstitial ad loading/showing logic
```dart
// Example with AdMob:
static Future<void> _showInterstitialAdPlaceholder(BuildContext context) async {
  InterstitialAd? interstitialAd;
  
  await InterstitialAd.load(
    adUnitId: 'YOUR_AD_UNIT_ID',
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        interstitialAd = ad;
        ad.show();
      },
      onAdFailedToLoad: (error) {
        // Handle error - proceed without ad
      },
    ),
  );
}
```

---

## Interstitial Ad Trigger Points

All interstitial ads are triggered via `AdHelper.maybeShowAdAndNavigate()` with 50% probability:

1. **Account Screen** (`lib/pages/account_screen.dart`)
   - Line ~43: Tapping "Settings" button
   - Line ~54: Tapping "Presets" button

2. **Timer Bottom Controls** (`lib/widgets/timer_bottom_controls.dart`)
   - Line ~188: Tapping settings icon (tune icon)

3. **Preset Selector** (`lib/widgets/preset_selector.dart`)
   - Line ~19: Tapping preset selector to open preset menu

4. **Dashboard Screen** (`lib/pages/dashboard_screen.dart`)
   - Line ~41: Tapping history button

---

## Ad Probability Configuration

To change ad frequency, modify the `adProbability` parameter in `AdHelper.maybeShowAdAndNavigate()`:

- `adProbability: 0.5` = 50% chance (current default)
- `adProbability: 0.3` = 30% chance
- `adProbability: 1.0` = Always show
- `adProbability: 0.0` = Never show

---

## Remove Ads Feature (In-App Purchase)

**File**: `lib/pages/account_screen.dart`  
**Location**: After Daily Goal card (~line 36)

A "Remove Ads" card placeholder is included. When implementing:

1. **Add in-app purchase dependency** to `pubspec.yaml`:
   ```yaml
   dependencies:
     in_app_purchase: ^3.1.0
   ```

2. **Create purchase provider** to manage ad-free status:
   ```dart
   class PurchaseProvider extends ChangeNotifier {
     bool _isAdFree = false;
     bool get isAdFree => _isAdFree;
     
     // Implement purchase logic
   }
   ```

3. **Conditionally show ads** based on purchase status:
   ```dart
   if (!purchaseProvider.isAdFree) {
     // Show ad
   }
   ```

4. **Update ad logic** in `AdHelper` to check purchase status before showing ads.

---

## Required Dependencies

When implementing real ads, add to `pubspec.yaml`:

```yaml
dependencies:
  google_mobile_ads: ^5.3.0  # For Google AdMob
  # OR
  facebook_audience_network: ^1.3.0  # For Facebook Audience Network
  
  # For Remove Ads feature:
  in_app_purchase: ^3.1.0
```

---

## Testing Checklist

After implementing real ads:

- [ ] Banner ad displays correctly on Account screen (guest users)
- [ ] Interstitial ads show with correct frequency (~50% of the time)
- [ ] Ads don't break navigation flow
- [ ] Ads respect user's ad-free purchase status
- [ ] Ads work on both Android and iOS
- [ ] Test with real ad IDs (not test IDs) before release
- [ ] Verify GDPR/consent handling if required for your region

---

## Notes

- All ad placeholders are clearly marked with "Ad Placeholder" text
- Ad system uses randomization via `dart:math.Random()`
- Interstitial ads are non-blocking - navigation continues after ad is dismissed
- Banner ads are only shown to guest (non-authenticated) users currently
- Easy to extend to show banner ads to all users if needed

---

## Contact Points

**Main Files to Modify**:
1. `lib/shared/ad_helper.dart` - Core ad display logic
2. `lib/pages/account_screen.dart` - Banner ad & Remove Ads card
3. `lib/widgets/ad_placeholder.dart` - Banner ad placeholder widget (can be deleted when using real ads)

**No Changes Needed** (uses AdHelper):
- `lib/pages/dashboard_screen.dart`
- `lib/widgets/timer_bottom_controls.dart`
- `lib/widgets/preset_selector.dart`
