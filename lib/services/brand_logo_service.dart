class BrandLogoService {
  static const Map<String, String> _brandLogos = {
    // Popular Fashion Brands
    'Nike': 'assets/brand_logos/nike.png',
    'Adidas': 'assets/brand_logos/adidas.png',
    'Puma': 'assets/brand_logos/puma.png',
    'Converse': 'assets/brand_logos/converse.png',
    'Vans': 'assets/brand_logos/vans.png',
    'Supreme': 'assets/brand_logos/supreme.png',
    'Champion': 'assets/brand_logos/champion.png',
    'Tommy Hilfiger': 'assets/brand_logos/tommy_hilfiger.png',
    'Calvin Klein': 'assets/brand_logos/calvin_klein.png',
    'Ralph Lauren': 'assets/brand_logos/ralph_lauren.png',
    'Polo Ralph Lauren': 'assets/brand_logos/polo_ralph_lauren.png',
    'Lacoste': 'assets/brand_logos/lacoste.png',
    'Hugo Boss': 'assets/brand_logos/hugo_boss.png',
    'Armani': 'assets/brand_logos/armani.png',
    'Versace': 'assets/brand_logos/versace.png',
    'Gucci': 'assets/brand_logos/gucci.png',
    'Prada': 'assets/brand_logos/prada.png',
    'Louis Vuitton': 'assets/brand_logos/louis_vuitton.png',
    'Chanel': 'assets/brand_logos/chanel.png',
    'Dior': 'assets/brand_logos/dior.png',
    
    // Streetwear & Urban
    'Off-White': 'assets/brand_logos/off_white.png',
    'Stone Island': 'assets/brand_logos/stone_island.png',
    'A Bathing Ape': 'assets/brand_logos/bape.png',
    'Kenzo': 'assets/brand_logos/kenzo.png',
    'Billionaire Boys Club': 'assets/brand_logos/bbc.png',
    'Stussy': 'assets/brand_logos/stussy.png',
    'Carhartt': 'assets/brand_logos/carhartt.png',
    'Dickies': 'assets/brand_logos/dickies.png',
    
    // Vintage/Retro Brands
    'Vintage Adidas': 'assets/brand_logos/vintage_adidas.png',
    'Vintage Nike': 'assets/brand_logos/vintage_nike.png',
    'Vintage Champion': 'assets/brand_logos/vintage_champion.png',
    'Vintage Tommy': 'assets/brand_logos/vintage_tommy.png',
    'Harley Davidson': 'assets/brand_logos/harley_davidson.png',
    'Levi\'s': 'assets/brand_logos/levis.png',
    'Wrangler': 'assets/brand_logos/wrangler.png',
    'Lee': 'assets/brand_logos/lee.png',
    
    // Sports Brands
    'Under Armour': 'assets/brand_logos/under_armour.png',
    'Reebok': 'assets/brand_logos/reebok.png',
    'New Balance': 'assets/brand_logos/new_balance.png',
    'ASICS': 'assets/brand_logos/asics.png',
    'Jordan': 'assets/brand_logos/jordan.png',
    'Yeezy': 'assets/brand_logos/yeezy.png',
    
    // Contemporary Brands
    'H&M': 'assets/brand_logos/hm.png',
    'Zara': 'assets/brand_logos/zara.png',
    'Uniqlo': 'assets/brand_logos/uniqlo.png',
    'Forever 21': 'assets/brand_logos/forever21.png',
    'Gap': 'assets/brand_logos/gap.png',
    'Old Navy': 'assets/brand_logos/old_navy.png',
    
    // Luxury Brands
    'Balenciaga': 'assets/brand_logos/balenciaga.png',
    'Givenchy': 'assets/brand_logos/givenchy.png',
    'Saint Laurent': 'assets/brand_logos/saint_laurent.png',
    'Burberry': 'assets/brand_logos/burberry.png',
    'Fendi': 'assets/brand_logos/fendi.png',
    'Hermès': 'assets/brand_logos/hermes.png',
  };

  static const String _defaultLogo = 'assets/brand_logos/default_brand.png';

  /// Get brand logo path for a given brand name
  static String getBrandLogo(String brandName) {
    if (brandName.isEmpty) return _defaultLogo;
    
    // Try exact match first
    if (_brandLogos.containsKey(brandName)) {
      return _brandLogos[brandName]!;
    }
    
    // Try case-insensitive match
    final lowerBrand = brandName.toLowerCase();
    for (final entry in _brandLogos.entries) {
      if (entry.key.toLowerCase() == lowerBrand) {
        return entry.value;
      }
    }
    
    // Try partial matches for vintage/era-specific brands
    if (lowerBrand.contains('vintage')) {
      final baseBrand = lowerBrand.replaceAll('vintage', '').trim();
      final vintageKey = 'Vintage ${_capitalizeFirst(baseBrand)}';
      if (_brandLogos.containsKey(vintageKey)) {
        return _brandLogos[vintageKey]!;
      }
    }
    
    return _defaultLogo;
  }

  /// Check if brand has a logo
  static bool hasBrandLogo(String brandName) {
    return getBrandLogo(brandName) != _defaultLogo;
  }

  /// Get all available brand names
  static List<String> getAllBrands() {
    return _brandLogos.keys.toList()..sort();
  }

  /// Get brands by category
  static List<String> getBrandsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'luxury':
        return _brandLogos.keys.where((brand) => 
          ['Gucci', 'Prada', 'Louis Vuitton', 'Chanel', 'Dior', 'Balenciaga', 
           'Givenchy', 'Saint Laurent', 'Burberry', 'Fendi', 'Hermès'].contains(brand)
        ).toList();
      case 'streetwear':
        return _brandLogos.keys.where((brand) => 
          ['Supreme', 'Off-White', 'Stone Island', 'A Bathing Ape', 'Stussy', 
           'Billionaire Boys Club', 'Kenzo'].contains(brand)
        ).toList();
      case 'sports':
        return _brandLogos.keys.where((brand) => 
          ['Nike', 'Adidas', 'Puma', 'Under Armour', 'Reebok', 'New Balance', 
           'ASICS', 'Jordan', 'Yeezy'].contains(brand)
        ).toList();
      case 'vintage':
        return _brandLogos.keys.where((brand) => 
          brand.toLowerCase().contains('vintage') || 
          ['Harley Davidson', 'Levi\'s', 'Wrangler', 'Lee'].contains(brand)
        ).toList();
      default:
        return _brandLogos.keys.toList();
    }
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}