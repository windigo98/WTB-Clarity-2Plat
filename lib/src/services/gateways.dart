import '../logic/clarity_logic.dart';
import '../models/app_data.dart';

/// Phase 2 will sync crew notes to a backend. Phase 1 only queues them
/// on the device. Nothing here opens a network connection.
class CrewGateway {
  const CrewGateway();

  static const phase = 2;
  static const available = false;

  Future<bool> sync(List<CrewNote> notes) async => false;
}

/// Real-money purchases are a hook only. [buyWithRealMoney] never charges
/// a card and never grants items.
class PurchaseGateway {
  const PurchaseGateway();

  Future<PurchaseResult> buyWithRealMoney(String sku) async {
    return PurchaseResult(
      ok: false,
      channel: 'real_money',
      message:
          'Real-money purchases are not available yet. SKU $sku is reserved for a later release.',
    );
  }
}
