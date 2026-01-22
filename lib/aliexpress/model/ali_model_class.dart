class Product {
  String originalPrice;
  List<String> productSmallImageUrls;
  String secondLevelCategoryName;
  String productDetailUrl;
  String targetSalePrice;
  int secondLevelCategoryId;
  String discount;
  String productMainImageUrl;
  int firstLevelCategoryId;
  String targetSalePriceCurrency;
  String originalPriceCurrency;
  String shopUrl;
  String targetOriginalPriceCurrency;
  int productId;
  int sellerId;
  String targetOriginalPrice;
  String productVideoUrl;
  String firstLevelCategoryName;
  String evaluateRate;
  String salePrice;
  String productTitle;
  int shopId;
  String salePriceCurrency;
  int lastestVolume;

  Product({
    this.originalPrice = '',
    this.productSmallImageUrls = const [],
    this.secondLevelCategoryName = '',
    this.productDetailUrl = '',
    this.targetSalePrice = '',
    this.secondLevelCategoryId = 0,
    this.discount = '',
    this.productMainImageUrl = '',
    this.firstLevelCategoryId = 0,
    this.targetSalePriceCurrency = '',
    this.originalPriceCurrency = '',
    this.shopUrl = '',
    this.targetOriginalPriceCurrency = '',
    this.productId = 0,
    this.sellerId = 0,
    this.targetOriginalPrice = '',
    this.productVideoUrl = '',
    this.firstLevelCategoryName = '',
    this.evaluateRate = '',
    this.salePrice = '',
    this.productTitle = '',
    this.shopId = 0,
    this.salePriceCurrency = '',
    this.lastestVolume = 0,
  });

  // Factory constructor to create a Product object from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      originalPrice: json['original_price'] as String? ?? '',
      productSmallImageUrls: List<String>.from(
          json['product_small_image_urls']['productSmallImageUrl'] ?? []),
      secondLevelCategoryName:
          json['second_level_category_name'] as String? ?? '',
      productDetailUrl: json['product_detail_url'] as String? ?? '',
      targetSalePrice: json['target_sale_price'] as String? ?? '',
      secondLevelCategoryId: json['second_level_category_id'] as int? ?? 0,
      discount: json['discount'] as String? ?? '',
      productMainImageUrl: json['product_main_image_url'] as String? ?? '',
      firstLevelCategoryId: json['first_level_category_id'] as int? ?? 0,
      targetSalePriceCurrency:
          json['target_sale_price_currency'] as String? ?? '',
      originalPriceCurrency: json['original_price_currency'] as String? ?? '',
      shopUrl: json['shop_url'] as String? ?? '',
      targetOriginalPriceCurrency:
          json['target_original_price_currency'] as String? ?? '',
      productId: json['product_id'] as int? ?? 0,
      sellerId: json['seller_id'] as int? ?? 0,
      targetOriginalPrice: json['target_original_price'] as String? ?? '',
      productVideoUrl: json['product_video_url'] as String? ?? '',
      firstLevelCategoryName:
          json['first_level_category_name'] as String? ?? '',
      evaluateRate: json['evaluate_rate'] as String? ?? '',
      salePrice: json['sale_price'] as String? ?? '',
      productTitle: json['product_title'] as String? ?? '',
      shopId: json['shop_id'] as int? ?? 0,
      salePriceCurrency: json['sale_price_currency'] as String? ?? '',
      lastestVolume: json['lastest_volume'] as int? ?? 0,
    );
  }

  // Method to convert a Product object to JSON
  Map<String, dynamic> toJson() {
    return {
      'original_price': originalPrice,
      'product_small_image_urls': {
        'productSmallImageUrl': productSmallImageUrls,
      },
      'second_level_category_name': secondLevelCategoryName,
      'product_detail_url': productDetailUrl,
      'target_sale_price': targetSalePrice,
      'second_level_category_id': secondLevelCategoryId,
      'discount': discount,
      'product_main_image_url': productMainImageUrl,
      'first_level_category_id': firstLevelCategoryId,
      'target_sale_price_currency': targetSalePriceCurrency,
      'original_price_currency': originalPriceCurrency,
      'shop_url': shopUrl,
      'target_original_price_currency': targetOriginalPriceCurrency,
      'product_id': productId,
      'seller_id': sellerId,
      'target_original_price': targetOriginalPrice,
      'product_video_url': productVideoUrl,
      'first_level_category_name': firstLevelCategoryName,
      'evaluate_rate': evaluateRate,
      'sale_price': salePrice,
      'product_title': productTitle,
      'shop_id': shopId,
      'sale_price_currency': salePriceCurrency,
      'lastest_volume': lastestVolume,
    };
  }
}

class AeItemSkuInfoDTO {
  final String skuAttr;
  final String offerSalePrice;
  final int ipmSkuStock;
  final bool skuStock;
  final String skuId;
  final bool priceIncludeTax;
  final String currencyCode;
  final String skuPrice;
  final String offerBulkSalePrice;
  final int skuAvailableStock;
  final String id;
  final String skuCode;
  final List<AeSkuPropertyDTO> aeSkuPropertyDtos;

  AeItemSkuInfoDTO({
    required this.skuAttr,
    required this.offerSalePrice,
    required this.ipmSkuStock,
    required this.skuStock,
    required this.skuId,
    required this.priceIncludeTax,
    required this.currencyCode,
    required this.skuPrice,
    required this.offerBulkSalePrice,
    required this.skuAvailableStock,
    required this.id,
    required this.skuCode,
    required this.aeSkuPropertyDtos,
  });

  factory AeItemSkuInfoDTO.fromJson(Map<String, dynamic> json) {
    return AeItemSkuInfoDTO(
      skuAttr: json['sku_attr'],
      offerSalePrice: json['offer_sale_price'],
      ipmSkuStock: json['ipm_sku_stock'],
      skuStock: json['sku_stock'],
      skuId: json['sku_id'],
      priceIncludeTax: json['price_include_tax'],
      currencyCode: json['currency_code'],
      skuPrice: json['sku_price'],
      offerBulkSalePrice: json['offer_bulk_sale_price'],
      skuAvailableStock: json['sku_available_stock'],
      id: json['id'],
      skuCode: json['sku_code'],
      aeSkuPropertyDtos:
          (json['ae_sku_property_dtos']['ae_sku_property_d_t_o'] as List)
              .map((item) => AeSkuPropertyDTO.fromJson(item))
              .toList(),
    );
  }
}

class AeSkuPropertyDTO {
  final String skuPropertyValue;
  final String? skuImage;
  final String skuPropertyName;
  final String? propertyValueDefinitionName;
  final int propertyValueId;
  final int skuPropertyId;

  AeSkuPropertyDTO({
    required this.skuPropertyValue,
    this.skuImage,
    required this.skuPropertyName,
    required this.propertyValueDefinitionName,
    required this.propertyValueId,
    required this.skuPropertyId,
  });

  // Convert user data to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'sku_property_value': skuPropertyValue,
      'sku_image': skuImage,
      'sku_property_name': skuPropertyName,
      'property_value_definition_name': propertyValueDefinitionName,
      'property_value_id': propertyValueId,
      'sku_property_id': skuPropertyId,
    };
  }

  factory AeSkuPropertyDTO.fromJson(Map<String, dynamic> json) {
    return AeSkuPropertyDTO(
      skuPropertyValue: json['sku_property_value'] ?? 'Unknown',
      skuImage: json['sku_image'],
      skuPropertyName: json['sku_property_name'] ?? 'Unnamed',
      propertyValueDefinitionName: json['property_value_definition_name'],
      // ?? 'No definition',
      propertyValueId: json['property_value_id'] ?? 0,
      skuPropertyId: json['sku_property_id'] ?? 0,
    );
  }
}

// New class for store information
class AeStoreInfo {
  final int storeId;
  final String shippingSpeedRating;
  final String communicationRating;
  final String storeName;
  final String storeCountryCode;
  final String itemAsDescribedRating;

  AeStoreInfo({
    required this.storeId,
    required this.shippingSpeedRating,
    required this.communicationRating,
    required this.storeName,
    required this.storeCountryCode,
    required this.itemAsDescribedRating,
  });

  // Convert the object to JSON
  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'shipping_speed_rating': shippingSpeedRating,
      'communication_rating': communicationRating,
      'store_name': storeName,
      'store_country_code': storeCountryCode,
      'item_as_described_rating': itemAsDescribedRating,
    };
  }

  // Factory constructor to create a AeStoreInfo object from JSON
  factory AeStoreInfo.fromJson(Map<String, dynamic> json) {
    return AeStoreInfo(
      storeId: json['store_id'] ?? 0,
      shippingSpeedRating: json['shipping_speed_rating'] ?? '0.0',
      communicationRating: json['communication_rating'] ?? '0.0',
      storeName: json['store_name'] ?? 'Unknown Store',
      storeCountryCode: json['store_country_code'] ?? 'Unknown',
      itemAsDescribedRating: json['item_as_described_rating'] ?? '0.0',
    );
  }
}

class AeItemBaseInfoDto {
  String mobileDetail;
  String subject;
  String evaluationCount;
  String salesCount;
  String productStatusType;
  String avgEvaluationRating;

  AeItemBaseInfoDto({
    required this.mobileDetail,
    required this.subject,
    required this.evaluationCount,
    required this.salesCount,
    required this.productStatusType,
    required this.avgEvaluationRating,
  });

  // Factory method to parse the mobileDetail string to its original format
  factory AeItemBaseInfoDto.fromJson(Map<String, dynamic> json) {
    return AeItemBaseInfoDto(
      mobileDetail: json['mobile_detail'],
      subject: json['subject'],
      evaluationCount: json['evaluation_count'],
      salesCount: json['sales_count'],
      productStatusType: json['product_status_type'],
      avgEvaluationRating: json['avg_evaluation_rating'],
    );
  }
}

class AeItemProperty {
  final int attrNameId;
  final int attrValueId;
  final String attrName;
  final String attrValue;

  AeItemProperty({
    required this.attrNameId,
    required this.attrValueId,
    required this.attrName,
    required this.attrValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'attr_name_id': attrNameId,
      'attr_value_id': attrValueId,
      'attr_name': attrName,
      'attr_value': attrValue,
    };
  }

  factory AeItemProperty.fromJson(Map<String, dynamic> json) {
    return AeItemProperty(
      attrNameId: json['attr_name_id'] ?? -1,
      attrValueId: json['attr_value_id'] ?? -1,
      attrName: json['attr_name'] ?? 'Unknown',
      attrValue: json['attr_value'] ?? 'Unknown',
    );
  }
}


/* class Product {
  String originalPrice;
  List<String> productSmallImageUrls;
  String secondLevelCategoryName;
  String productDetailUrl;
  String targetSalePrice;
  int secondLevelCategoryId;
  String discount;
  String productMainImageUrl;
  int firstLevelCategoryId;
  String targetSalePriceCurrency;
  String originalPriceCurrency;
  String shopUrl;
  String targetOriginalPriceCurrency;
  int productId;
  int sellerId;
  String targetOriginalPrice;
  String productVideoUrl;
  String firstLevelCategoryName;
  String evaluateRate;
  String salePrice;
  String productTitle;
  int shopId;
  String salePriceCurrency;
  int lastestVolume;

  Product({
    required this.originalPrice,
    required this.productSmallImageUrls,
    required this.secondLevelCategoryName,
    required this.productDetailUrl,
    required this.targetSalePrice,
    required this.secondLevelCategoryId,
    required this.discount,
    required this.productMainImageUrl,
    required this.firstLevelCategoryId,
    required this.targetSalePriceCurrency,
    required this.originalPriceCurrency,
    required this.shopUrl,
    required this.targetOriginalPriceCurrency,
    required this.productId,
    required this.sellerId,
    required this.targetOriginalPrice,
    required this.productVideoUrl,
    required this.firstLevelCategoryName,
    required this.evaluateRate,
    required this.salePrice,
    required this.productTitle,
    required this.shopId,
    required this.salePriceCurrency,
    required this.lastestVolume,
  });

  // Factory constructor to create a Product object from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      originalPrice: json['original_price'] as String,
      productSmallImageUrls: List<String>.from(
          json['product_small_image_urls']['productSmallImageUrl']),
      secondLevelCategoryName: json['second_level_category_name'] as String,
      productDetailUrl: json['product_detail_url'] as String,
      targetSalePrice: json['target_sale_price'] as String,
      secondLevelCategoryId: json['second_level_category_id'] as int,
      discount: json['discount'] as String,
      productMainImageUrl: json['product_main_image_url'] as String,
      firstLevelCategoryId: json['first_level_category_id'] as int,
      targetSalePriceCurrency: json['target_sale_price_currency'] as String,
      originalPriceCurrency: json['original_price_currency'] as String,
      shopUrl: json['shop_url'] as String,
      targetOriginalPriceCurrency:
          json['target_original_price_currency'] as String,
      productId: json['product_id'] as int,
      sellerId: json['seller_id'] as int,
      targetOriginalPrice: json['target_original_price'] as String,
      productVideoUrl: json['product_video_url'] ?? '',
      firstLevelCategoryName: json['first_level_category_name'] as String,
      evaluateRate: json['evaluate_rate'] as String,
      salePrice: json['sale_price'] as String,
      productTitle: json['product_title'] as String,
      shopId: json['shop_id'] as int,
      salePriceCurrency: json['sale_price_currency'] as String,
      lastestVolume: json['lastest_volume'] as int,
    );
  }

  // Method to convert a Product object to JSON
  Map<String, dynamic> toJson() {
    return {
      'original_price': originalPrice,
      'product_small_image_urls': {
        'productSmallImageUrl': productSmallImageUrls,
      },
      'second_level_category_name': secondLevelCategoryName,
      'product_detail_url': productDetailUrl,
      'target_sale_price': targetSalePrice,
      'second_level_category_id': secondLevelCategoryId,
      'discount': discount,
      'product_main_image_url': productMainImageUrl,
      'first_level_category_id': firstLevelCategoryId,
      'target_sale_price_currency': targetSalePriceCurrency,
      'original_price_currency': originalPriceCurrency,
      'shop_url': shopUrl,
      'target_original_price_currency': targetOriginalPriceCurrency,
      'product_id': productId,
      'seller_id': sellerId,
      'target_original_price': targetOriginalPrice,
      'product_video_url': productVideoUrl,
      'first_level_category_name': firstLevelCategoryName,
      'evaluate_rate': evaluateRate,
      'sale_price': salePrice,
      'product_title': productTitle,
      'shop_id': shopId,
      'sale_price_currency': salePriceCurrency,
      'lastest_volume': lastestVolume,
    };
  }
} */