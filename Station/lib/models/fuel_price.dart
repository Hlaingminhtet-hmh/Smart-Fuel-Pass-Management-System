class FuelPrice {
  final String fuelType;
  final double pricePerLiter;
  final String currency;
  final DateTime? effectiveFrom;

  const FuelPrice({
    required this.fuelType,
    required this.pricePerLiter,
    required this.currency,
    required this.effectiveFrom,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      fuelType: json['fuel_type']?.toString() ?? '',
      pricePerLiter:
          double.tryParse(json['price_per_liter']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'MMK',
      effectiveFrom:
          DateTime.tryParse(json['effective_from']?.toString() ?? ''),
    );
  }
}
