class BrandLogoService {
  static const Map<String, String> _brandColors = {
    // Popular Fashion Brands
    'Nike': 'FF6B35',
    'Adidas': '000000',
    'Puma': '000000',
    'Converse': '000000',
    'Vans': '000000',
    'Supreme': 'FF0000',
    'Champion': 'C8102E',
    'Tommy Hilfiger': '003087',
    'Calvin Klein': '000000',
    'Ralph Lauren': '000080',
    'Polo Ralph Lauren': '000000',
    'Lacoste': '000000',
    'Hugo Boss': '000000',
    'Armani': '000000',
    'Versace': '000000',
    'Gucci': '006B3C',
    'Prada': '000000',
    'Louis Vuitton': '8B4513',
    'Chanel': '000000',
    'Dior': '000000',
    
    // Streetwear & Urban
    'Off-White': '000000',
    'Stone Island': '4A4A4A',
    'A Bathing Ape': '000000',
    'Kenzo': '000000',
    'Billionaire Boys Club': '000000',
    'Stussy': '000000',
    'Carhartt': '000000',
    'Dickies': '000000',
    
    // Vintage/Retro Brands
    'Vintage Adidas': '000000',
    'Vintage Nike': '000000',
    'Vintage Champion': '000000',
    'Vintage Tommy': '000000',
    'Harley Davidson': '8B0000',
    'Levi\'s': '003087',
    'Wrangler': '000000',
    'Lee': '000000',
    
    // Sports Brands
    'Under Armour': '000000',
    'Reebok': '000000',
    'New Balance': '000000',
    'ASICS': '000000',
    'Jordan': '000000',
    'Yeezy': '000000',
    
    // Contemporary Brands
    'H&M': 'E50000',
    'Zara': '000000',
    'Uniqlo': '000000',
    'Forever 21': '000000',
    'Gap': '000000',
    'Old Navy': '000000',
    
    // Luxury Brands
    'Balenciaga': '000000',
    'Givenchy': '000000',
    'Saint Laurent': '000000',
    'Burberry': 'A0522D',
    'Fendi': '000000',
    'Hermès': '000000',
  };

  static String getBrandLogo(String brandName) {
    return brandName;
  }

  static bool hasBrandLogo(String brandName) {
    return _brandColors.containsKey(brandName);
  }

  static List<String> getAllBrands() {
    return _brandColors.keys.toList();
  }

  static List<String> getBrandsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'luxury':
        return ['Gucci', 'Prada', 'Louis Vuitton', 'Balenciaga', 'Burberry'];
      case 'streetwear':
        return ['Supreme', 'Off-White', 'Stone Island'];
      case 'sports':
        return ['Nike', 'Adidas', 'Puma', 'Champion'];
      case 'vintage':
        return ['Levi\'s', 'Dr. Martens', 'Hanes'];
      default:
        return getAllBrands();
    }
  }
}