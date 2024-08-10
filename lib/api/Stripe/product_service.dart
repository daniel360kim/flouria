
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flourish_web/api/Stripe/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

StripeDatabaseProduct _$StripeProductFromJson(
    Map<String, dynamic> json, String docId) {
  int numFeatures = int.tryParse(json['metadata']['num_features'] ?? '0') ?? 0;

  List<String?> featureList = [];
  for (int i = 1; i <= numFeatures; i++) {
    String key = 'feature$i';
    featureList.add(json['metadata'][key] as String?);
  }

  int color = int.parse(json['metadata']['color'], radix: 16);

  return StripeDatabaseProduct(
    docId: docId,
    description: json['description'] as String?,
    images: (json['images'] as List<dynamic>?)
        ?.map((image) => image as String)
        .toList(), // Handling the list
    name: json['name'] as String?,
    role: json['role'] as String?,
    taxCode: json['tax_code'] as String?,
    displayOrder: int.tryParse(json['metadata']['display_order'] ?? '0'),
    featureList: featureList,
    color: Color.fromARGB(255, color >> 16, color >> 8, color >> 0),
  );
}

@JsonSerializable()
class StripeDatabaseProduct {
  final String? docId;
  final String? description;
  final List<String>? images;
  final String? name;
  final String? role;
  final String? taxCode;
  final int? displayOrder;
  final List<String?>? featureList;
  final Color? color;

  const StripeDatabaseProduct({
    this.docId,
    this.description,
    this.images,
    this.name,
    this.role,
    this.taxCode,
    this.displayOrder,
    this.featureList,
    this.color,
  });

  factory StripeDatabaseProduct.fromJson(
          Map<String, dynamic> json, String docId) =>
      _$StripeProductFromJson(json, docId);
}

enum PricingInterval {
  day,
  week,
  month,
  year,
}

Map<String, PricingInterval> pricingIntervalMap = {
  'day': PricingInterval.day,
  'week': PricingInterval.week,
  'month': PricingInterval.month,
  'year': PricingInterval.year,
};

ProductPrice _$ProductPriceFromJson(Map<String, dynamic> json, String docId) {
  return ProductPrice(
    docId: docId,
    interval: pricingIntervalMap[json['interval'] as String?],
    taxBehavior: json['tax_behavior'] as String?,
    unitAmount: json['unit_amount'] as int?,
  );
}

@JsonSerializable()
class ProductPrice {
  final String? docId;
  final PricingInterval? interval;
  final String? taxBehavior;
  final int? unitAmount;

  const ProductPrice({
    this.docId,
    this.interval,
    this.taxBehavior,
    this.unitAmount,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json, String docId) =>
      _$ProductPriceFromJson(json, docId);
}

class Product {
  StripeDatabaseProduct product;
  List<ProductPrice> prices;

  Product({required this.product, required this.prices});
}

class StripeProductService extends StripeService {
  late final CollectionReference<Map<String, dynamic>> _collection;
  StripeProductService() : super() {
    _collection = FirebaseFirestore.instance.collection('products');
  }

  Future<List<StripeDatabaseProduct>> _getActiveDatabaseProducts() async {
    logger.i('Getting active products');
    try {
      final querySnapshot =
          await _collection.where('active', isEqualTo: true).get();

      final products = querySnapshot.docs.map((doc) {
        logger.i('Found product: ${doc.id}');
        return StripeDatabaseProduct.fromJson(doc.data(), doc.id);
      }).toList();

      return products;
    } catch (e) {
      logger.e('Unexpected error while getting active products. $e');
      rethrow;
    }
  }

  Future<List<ProductPrice>> _getActivePrices(
      StripeDatabaseProduct product) async {
    logger.i('Getting active prices for ${product.name}');
    try {
      final querySnapshot = await _collection
          .doc(product.docId)
          .collection('prices')
          .where('active', isEqualTo: true)
          .get();

      logger.i(
          'Found ${querySnapshot.docs.length} active prices for ${product.docId}');
      final prices = querySnapshot.docs.map((doc) {
        logger.i('Found price: ${doc.id}');
        return ProductPrice.fromJson(doc.data(), doc.id);
      }).toList();

      return prices;
    } catch (e) {
      logger.e(
          'Unexpected error while getting active prices for ${product.docId}');
      rethrow;
    }
  }

  Future<List<Product>> getActiveProducts() async {
    try {
      final activeProducts = await _getActiveDatabaseProducts();

      List<Product> products = [];
      for (final product in activeProducts) {
        final prices = await _getActivePrices(product);

        // Check for duplicate prices with the same interval
        final seenIntervals = <PricingInterval>{};
        for (final price in prices) {
          if (price.interval != null && !seenIntervals.add(price.interval!)) {
            logger.e(
                'Duplicate price found for product ${product.name} with interval ${price.interval}.');
            throw Exception();
          }
        }

        products.add(Product(product: product, prices: prices));
      }

      products.sort((a, b) =>
          a.product.displayOrder!.compareTo(b.product.displayOrder as num));
      return products;
    } catch (e) {
      // Logging handled by private methods
      rethrow;
    }
  }
}