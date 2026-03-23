import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../app/state.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  static const String monthlyId = 'quantoposso_pro_monthly_v2';
  static const String yearlyId = 'quantoposso_pro_yearly_v2';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];

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
    _subscription = null;

    final available = await _iap.isAvailable();
    print('IAP AVAILABLE -> $available');

    if (!available) {
      print('IAP non disponibile su questo device/account');
      return;
    }

    final response = await _iap.queryProductDetails({
      monthlyId,
      yearlyId,
    });

    print('IAP FOUND -> ${response.productDetails.map((e) => e.id).toList()}');
    print('IAP NOT FOUND -> ${response.notFoundIDs}');
    print('IAP RESPONSE ERROR -> ${response.error}');

    for (final product in response.productDetails) {
      print('PRODUCT -> ${product.id}');
      print('PRICE -> ${product.price}');
      print('RAW PRICE -> ${product.rawPrice}');
      print('CURRENCY CODE -> ${product.currencyCode}');
    }

    _products = response.productDetails;

    _subscription = _iap.purchaseStream.listen(
      (purchases) async {
        _purchases = purchases;

        for (final purchase in purchases) {
          print('IAP STATUS -> ${purchase.productID} | ${purchase.status}');
          print('IAP ERROR -> ${purchase.error}');

          switch (purchase.status) {
            case PurchaseStatus.pending:
              print('Acquisto in attesa...');
              break;

            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              await _handlePurchase(purchase, state);
              break;

            case PurchaseStatus.error:
              print('Errore acquisto: ${purchase.error}');
              break;

            case PurchaseStatus.canceled:
              print('Acquisto annullato');
              break;
          }

          if (purchase.pendingCompletePurchase) {
            print('Completo acquisto pendente...');
            await _iap.completePurchase(purchase);
          }
        }
      },
      onError: (e) {
        print('PURCHASE STREAM ERROR -> $e');
      },
      onDone: () {
        print('PURCHASE STREAM CHIUSO');
      },
    );
  }

  Future<void> _handlePurchase(
    PurchaseDetails purchase,
    AppState state,
  ) async {
    final now = DateTime.now();

    print('HANDLE PURCHASE -> ${purchase.productID}');

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

    print('Prodotto acquistato non riconosciuto: ${purchase.productID}');
  }

  PurchaseDetails? _findOwnedSubscription(String productId) {
    try {
      return _purchases.firstWhere(
        (p) =>
            p.productID == productId &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> buyMonthly() async {
    final product = monthlyProduct;
    print('BUY MONTHLY -> ${product?.id}');

    if (product == null) {
      print('Prodotto mensile non trovato');
      return;
    }

    PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      final oldYearly = _findOwnedSubscription(yearlyId);
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: oldYearly is GooglePlayPurchaseDetails
            ? ChangeSubscriptionParam(
                oldPurchaseDetails: oldYearly,
                replacementMode: ReplacementMode.withTimeProration,
              )
            : null,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    final started = await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    print('BUY MONTHLY STARTED -> $started');
  }

  Future<void> buyYearly() async {
    final product = yearlyProduct;
    print('BUY YEARLY -> ${product?.id}');

    if (product == null) {
      print('Prodotto annuale non trovato');
      return;
    }

    PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      final oldMonthly = _findOwnedSubscription(monthlyId);
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: oldMonthly is GooglePlayPurchaseDetails
            ? ChangeSubscriptionParam(
                oldPurchaseDetails: oldMonthly,
                replacementMode: ReplacementMode.withTimeProration,
              )
            : null,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    final started = await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    print('BUY YEARLY STARTED -> $started');
  }

  Future<void> restorePurchases() async {
    print('RESTORE PURCHASES -> avvio');
    await _iap.restorePurchases();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}