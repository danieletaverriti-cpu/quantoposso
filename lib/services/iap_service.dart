import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../app/state.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  static const String monthlyId = 'quantoposso_pro_monthly';
  static const String yearlyId = 'quantoposso_pro_yearly';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere((p) => p.id == monthlyId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere((p) => p.id == yearlyId);
    } catch (_) {
      return null;
    }
  }

  Future<void> init(AppState state) async {
    await _subscription?.cancel();

    final available = await _iap.isAvailable();
    if (!available) return;

    final response = await _iap.queryProductDetails({
      monthlyId,
      yearlyId,
    });

    _products = response.productDetails;

    _subscription = _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          await _handlePurchaseUpdate(purchase, state);
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _handlePurchaseUpdate(
    PurchaseDetails purchase,
    AppState state,
  ) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        return;

      case PurchaseStatus.error:
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        return;

      case PurchaseStatus.canceled:
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        return;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _unlockFromPurchase(purchase, state);

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        return;
    }
  }

  Future<void> _unlockFromPurchase(
    PurchaseDetails purchase,
    AppState state,
  ) async {
    final now = DateTime.now();

    if (purchase.productID == monthlyId) {
      await state.unlockPro(
        plan: 'monthly',
        expiry: now.add(const Duration(days: 30)),
      );
      return;
    }

    if (purchase.productID == yearlyId) {
      await state.unlockPro(
        plan: 'yearly',
        expiry: now.add(const Duration(days: 365)),
      );
      return;
    }
  }

  Future<void> buyMonthly() async {
    final product = monthlyProduct;
    if (product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buyYearly() async {
    final product = yearlyProduct;
    if (product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}