/// Currencies that can be selected for a product price.
///
/// Each entry is an ISO 4217 code, the same value persisted with the product
/// (`FIELD_REQUIREMENTS.md` §11).
abstract final class AppCurrencies {
  /// Currency used by default for new products.
  static const String defaultCode = 'EUR';

  /// Currencies offered in the product form.
  static const List<String> supported = [
    'EUR',
    'USD',
    'GBP',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
    'SEK',
    'NOK',
    'DKK',
    'PLN',
    'MXN',
    'BRL',
    'INR',
    'CNY',
  ];
}
