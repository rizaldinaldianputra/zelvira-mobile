class AppMidtransConfig {
  /// Toggle Midtrans production mode. Set to true for live transactions.
  static const bool isProduction = true;

  /// Midtrans Production Client Key matching backend MIDTRANS_SERVER_KEY and Merchant ID G404512774.
  /// Midtrans SDK automatically switches to Production mode when clientKey lacks 'SB-'.
  static const String clientKey = 'Mid-client-DDoZuhWWIzZo_1js';
  static const String merchantId = 'G404512774';
  static const String merchantBaseUrl = 'https://api.zelvira.my.id/';

  /// Generates the redirect URL for Snap based on the current environment.
  static String getSnapUrl(String token) {
    if (isProduction) {
      return 'https://app.midtrans.com/snap/v4/redirection/$token';
    }
    return 'https://app.sandbox.midtrans.com/snap/v4/redirection/$token';
  }

  /// Resolves the canonical payment URL for a given paymentUrl or paymentToken.
  /// Prioritizes the exact redirect_url returned by Midtrans API (`paymentUrl`),
  /// falling back to https://app.midtrans.com/snap/v4/redirection/$token if only token is present.
  static String resolvePaymentUrl({String? paymentUrl, String? paymentToken}) {
    if (paymentUrl != null && paymentUrl.trim().isNotEmpty) {
      String trimmed = paymentUrl.trim();
      if (isProduction && trimmed.contains('sandbox.midtrans.com')) {
        return trimmed.replaceAll('sandbox.midtrans.com', 'midtrans.com');
      }
      return trimmed;
    }
    if (paymentToken != null && paymentToken.trim().isNotEmpty) {
      return getSnapUrl(paymentToken.trim());
    }
    return '';
  }
}
