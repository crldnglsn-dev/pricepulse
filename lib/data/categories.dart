/// Approved category list for the chip row (design/03a §1.2).
/// "All" is the default single-select state; concrete categories route to
/// the Search Results screen (category mode).
const List<String> kCategories = [
  'All',
  'Smartphones',
  'Laptops & Tablets',
  'Audio',
  'Wearables',
  'Gaming',
  'PC Parts',
  'Home & Living',
  'Kitchen',
  'Beauty',
  'Accessories',
  // Added once real catalog data arrived — the original 10-category guess in
  // design/04 §2 did not cover these.
  'Television',
  'Hair Care',
];
