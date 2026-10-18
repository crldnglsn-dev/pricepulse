/// SEED DATA — five hand-curated products, each with the same brand, model and
/// variant sold across Shopee, Lazada and TikTok Shop.
///
/// - Prices were read off the live listing pages by driving a real phone, so
///   they are real recorded prices, not guesses. They go stale — re-check
///   before a demo.
/// - Every URL was opened on the device, not just fetched. Shopee and Lazada
///   links land on the product page. TikTok Shop links land on its search
///   results with the product as the top "Best match" — reachable in one tap,
///   but not a direct product page. See the `_t` note below.
/// - `logitech_g102` has no TikTok offer on purpose: that row renders the
///   designed "no recorded offer yet" state.
/// - `bench_pomade_20g` is `comparable: false` — its Lazada listing sells both
///   the 20g and 80g sizes, so a savings figure across it and the 20g-only
///   records would compare different quantities.
library;

import '../models/offer.dart';
import '../models/product.dart';

/// Freshness stamp shared by every offer in this dataset.
///
/// 2026-10-18: every URL was opened on a connected phone and the prices
/// re-read off the listing. Three had drifted and were corrected — Logitech
/// Shopee 1076 -> 1195, Logitech Lazada 1049 -> 1019, Xiaomi TV Lazada
/// 9490 -> 9540.
final DateTime verifiedCheckedAt = DateTime(2026, 10, 18);

final List<Product> seedProducts = [
  Product(
    id: 'logitech_g102',
    name: 'Logitech G102 LIGHTSYNC Gaming Mouse',
    category: 'PC Parts',
    description:
        'Wired optical gaming mouse with 8,000 DPI sensor, six programmable '
        'buttons, and LIGHTSYNC RGB. The identical G102 model is sold by '
        'several authorized retailers, so prices differ without the items '
        'differing.',
    imageUrl: 'assets/products/logitech_g102.png',
    featured: true,
    offers: [
      Offer(
        store: Store.shopee,
        price: 1195,
        productUrl: 'https://shopee.ph/product/124930893/9544986414',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.lazada,
        price: 1019,
        productUrl:
            'https://www.lazada.com.ph/products/i1059718604-s3599640767.html',
        lastCheckedAt: verifiedCheckedAt,
      ),
    ],
  ),
  Product(
    id: 'orashare_hs05',
    name: 'Orashare HS05 Wireless Headphones Bluetooth 6.0',
    category: 'Audio',
    description:
        'Over-ear wireless headphones with Bluetooth 6.0, low-latency gaming '
        'mode, foldable design, and up to 17 hours of playback.',
    imageUrl: 'assets/products/orashare_hs05.jpg',
    featured: true,
    offers: [
      Offer(
        store: Store.shopee,
        price: 679,
        productUrl:
            'https://shopee.ph/Orashare-HS05-Wireless-Headphones-Bluetooth-6.0-'
            'Low-Latency-Gaming-17H-Playtime-Foldable-Bass-i.264015657.26286035790',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.lazada,
        price: 679,
        productUrl: 'https://www.lazada.com.ph/products/pdp-i5073347000-s29887086160.html',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.tiktok,
        price: 588,
        productUrl: 'https://shop.tiktok.com/ph/pdp/1731605640790116113',
        lastCheckedAt: verifiedCheckedAt,
      ),
    ],
  ),
  Product(
    id: 'xiaomi_tv_a32',
    name: 'Xiaomi TV A 32" 2026 HD Google TV',
    category: 'Television',
    description:
        '32-inch HD smart television running Google TV, with built-in apps '
        'and voice remote. Same model number across all three stores.',
    imageUrl: 'assets/products/xiaomi_tv_a32.jpg',
    featured: true,
    offers: [
      Offer(
        store: Store.shopee,
        price: 9590,
        productUrl: 'https://shopee.ph/Xiaomi-TV-A-32-Inch-2026-HD-Google-TV-i.133211801.42762718945',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.lazada,
        price: 9540,
        productUrl: 'https://www.lazada.com.ph/products/pdp-i4573619650-s26308659225.html',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.tiktok,
        price: 9013.65,
        productUrl: 'https://shop.tiktok.com/ph/pdp/1729397916647198605',
        lastCheckedAt: verifiedCheckedAt,
      ),
    ],
  ),
  Product(
    id: 'redmi_watch_5',
    name: 'Xiaomi Redmi Watch 5 Active 2.0',
    category: 'Wearables',
    description:
        'LCD fitness watch with Bluetooth calling, 5ATM water resistance, '
        'built-in Alexa, and a free extra strap in the box.',
    imageUrl: 'assets/products/redmi_watch_5.jpg',
    offers: [
      Offer(
        store: Store.shopee,
        price: 2199,
        productUrl:
            'https://shopee.ph/-Free-Strap-Xiaomi-Redmi-Watch-5-Active-2.0'
            '%27%27-LCD-Display-Bluetooth-Phone-Call-5ATM-Alexa-Built-In-'
            'i.1035296590.27960907170',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.lazada,
        price: 2099,
        productUrl: 'https://www.lazada.com.ph/products/pdp-i15522136270.html',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.tiktok,
        price: 2041.54,
        productUrl: 'https://shop.tiktok.com/ph/pdp/1729709945974328205',
        lastCheckedAt: verifiedCheckedAt,
      ),
    ],
  ),
  // `comparable: false` — the Lazada listing for this pomade offers both the
  // 20g and 80g sizes, so a "Save ₱38" figure across it and the 20g-only
  // Shopee/TikTok records would be comparing different quantities. Per
  // design/03a §2.4 no savings is computed and the offers are captioned
  // "shown for reference only". Flip to `true` once the Lazada listing is
  // confirmed to be the 20g variant.
  Product(
    id: 'bench_pomade_20g',
    name: 'Bench Barbers Pomade 20g',
    category: 'Hair Care',
    description:
        'Matte-hold hair pomade from Bench Barbers, original 20g tin. '
        'Strong hold with no shine; a little water re-works it.',
    imageUrl: 'assets/products/bench_pomade_20g.jpg',
    comparable: false,
    offers: [
      Offer(
        store: Store.shopee,
        price: 65,
        productUrl: 'https://shopee.ph/TCR1020Q-BENCH-Bench-Barbers-Pomade-20g-i.81843945.7152937999',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.lazada,
        price: 98,
        productUrl:
            'https://www.lazada.com.ph/products/bench-barbers-pomade-20g-80g-'
            'fix-professional-i15659289911-s133774211330.html',
        lastCheckedAt: verifiedCheckedAt,
      ),
      Offer(
        store: Store.tiktok,
        price: 59.80,
        productUrl: 'https://shop.tiktok.com/ph/pdp/1730193732982835746',
        lastCheckedAt: verifiedCheckedAt,
      ),
    ],
  ),
];
