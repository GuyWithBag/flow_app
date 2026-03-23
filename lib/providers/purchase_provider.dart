import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseProvider extends ChangeNotifier {
  static const String _apiKey = 'test_JeVPpLYxXOmwZtFYmyeQHogMMqf';
  static const String noAdsEntitlementId = 'one-time-remove-ads-tier';

  CustomerInfo? _customerInfo;
  bool _isInitialized = false;

  CustomerInfo? get customerInfo => _customerInfo;
  bool get isInitialized => _isInitialized;

  bool get isNoAds {
    final entitlement = _customerInfo?.entitlements.all[noAdsEntitlementId];
    return entitlement != null && entitlement.isActive;
  }

  /// Initialize RevenueCat SDK. Call once at app startup.
  Future<void> initialize() async {
    if (!_isMobile) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      // Listen for customer info updates (e.g. purchases made on another device)
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Fetch initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      _isInitialized = true;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('RevenueCat init error: ${e.message}');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _customerInfo = info;
    notifyListeners();
  }

  /// Refresh customer info from RevenueCat servers.
  Future<void> refreshCustomerInfo() async {
    if (!_isMobile || !_isInitialized) return;

    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('RevenueCat refresh error: ${e.message}');
    }
  }

  /// Restore previous purchases (useful after reinstall).
  Future<bool> restorePurchases() async {
    if (!_isMobile || !_isInitialized) return false;

    try {
      _customerInfo = await Purchases.restorePurchases();
      notifyListeners();
      return isNoAds;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat restore error: ${e.message}');
      return false;
    }
  }

  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
