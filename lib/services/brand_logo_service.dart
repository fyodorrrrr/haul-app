class BrandLogoService {
  // Known brands with logos
  static const Map<String, Map<String, dynamic>> _knownBrands = {
    // Sports & Athletic Brands
    'Nike': {'category': 'sports', 'hasLogo': true},
    'Adidas': {'category': 'sports', 'hasLogo': true},
    'Puma': {'category': 'sports', 'hasLogo': true},
    'Champion': {'category': 'sports', 'hasLogo': true},
    'Under Armour': {'category': 'sports', 'hasLogo': true},
    'Reebok': {'category': 'sports', 'hasLogo': true},
    'New Balance': {'category': 'sports', 'hasLogo': true},
    'Converse': {'category': 'sports', 'hasLogo': true},
    'Vans': {'category': 'sports', 'hasLogo': true},
    'Jordan': {'category': 'sports', 'hasLogo': true},
    
    // Luxury & Designer Brands
    'Gucci': {'category': 'luxury', 'hasLogo': true},
    'Prada': {'category': 'luxury', 'hasLogo': true},
    'Louis Vuitton': {'category': 'luxury', 'hasLogo': true},
    'Chanel': {'category': 'luxury', 'hasLogo': true},
    'Dior': {'category': 'luxury', 'hasLogo': true},
    'Balenciaga': {'category': 'luxury', 'hasLogo': true},
    'Versace': {'category': 'luxury', 'hasLogo': true},
    'Armani': {'category': 'luxury', 'hasLogo': true},
    'Burberry': {'category': 'luxury', 'hasLogo': true},
    'Fendi': {'category': 'luxury', 'hasLogo': true},
    
    // Streetwear Brands
    'Supreme': {'category': 'streetwear', 'hasLogo': true},
    'Off-White': {'category': 'streetwear', 'hasLogo': true},
    'Stone Island': {'category': 'streetwear', 'hasLogo': true},
    'A Bathing Ape': {'category': 'streetwear', 'hasLogo': true},
    'Stussy': {'category': 'streetwear', 'hasLogo': true},
    'Kenzo': {'category': 'streetwear', 'hasLogo': true},
    
    // Classic Fashion Brands
    'Levi\'s': {'category': 'classic', 'hasLogo': true},
    'Tommy Hilfiger': {'category': 'classic', 'hasLogo': true},
    'Calvin Klein': {'category': 'classic', 'hasLogo': true},
    'Ralph Lauren': {'category': 'classic', 'hasLogo': true},
    'Lacoste': {'category': 'classic', 'hasLogo': true},
    'Hugo Boss': {'category': 'classic', 'hasLogo': true},
    'Dr. Martens': {'category': 'classic', 'hasLogo': true},
    
    // Contemporary Brands
    'Zara': {'category': 'contemporary', 'hasLogo': true},
    'H&M': {'category': 'contemporary', 'hasLogo': true},
    'Uniqlo': {'category': 'contemporary', 'hasLogo': true},
    'Gap': {'category': 'contemporary', 'hasLogo': true},
    'Forever 21': {'category': 'contemporary', 'hasLogo': true},
    
    // Generic/Other
    'Hanes': {'category': 'basic', 'hasLogo': true},
    'Fruit of the Loom': {'category': 'basic', 'hasLogo': true},
    'Gildan': {'category': 'basic', 'hasLogo': true},
  };

  static const String _defaultLogo = 'assets/brand_logos/default_brand.png';

  /// Get brand logo path for a given brand name
  static String getBrandLogo(String brandName) {
    if (brandName.isEmpty) return _defaultLogo;
    
    // Check if it's a known brand with logo
    if (isKnownBrand(brandName) && _knownBrands[brandName]!['hasLogo'] == true) {
      return 'assets/brand_logos/${brandName.toLowerCase().replaceAll(' ', '_').replaceAll('\'', '').replaceAll('-', '_')}.png';
    }
    
    return _defaultLogo;
  }

  /// Check if brand is in our known brands list
  static bool isKnownBrand(String brandName) {
    return _knownBrands.containsKey(brandName);
  }

  /// Check if brand has a logo asset
  static bool hasBrandLogo(String brandName) {
    return isKnownBrand(brandName) && _knownBrands[brandName]!['hasLogo'] == true;
  }

  /// Get all known brand names
  static List<String> getAllKnownBrands() {
    return _knownBrands.keys.toList()..sort();
  }

  /// Get brands by category
  static List<String> getBrandsByCategory(String category) {
    return _knownBrands.entries
        .where((entry) => entry.value['category'] == category)
        .map((entry) => entry.key)
        .toList()..sort();
  }

  /// Get all brand categories
  static List<String> getBrandCategories() {
    return ['sports', 'luxury', 'streetwear', 'classic', 'contemporary', 'vintage', 'basic'];
  }

  /// Normalize brand name for comparison
  static String normalizeBrandName(String brandName) {
    return brandName.trim().toLowerCase();
  }

  /// Check if a brand should be categorized as "Other"
  static bool isOtherBrand(String brandName) {
    return !isKnownBrand(brandName);
  }

  /// Get brand category
  static String getBrandCategory(String brandName) {
    if (isKnownBrand(brandName)) {
      return _knownBrands[brandName]!['category'];
    }
    return 'other';
  }

  /// Get display name for brand (handles "Other" brands)
  static String getDisplayBrandName(String brandName) {
    if (isOtherBrand(brandName)) {
      return 'Other Brands';
    }
    return brandName;
  }
}