# Product images

Product photos live here as `assets/products/<product-id>.jpg` (or `.png`).

Five images are bundled, one per seed product, at demo-appropriate resolution
(max 720×720, ~175 KB total):

| File | Product |
|---|---|
| `logitech_g102.png` | Logitech G102 LIGHTSYNC Gaming Mouse |
| `orashare_hs05.jpg` | Orashare HS05 Wireless Headphones |
| `xiaomi_tv_a32.jpg` | Xiaomi TV A 32" 2026 HD Google TV |
| `redmi_watch_5.jpg` | Xiaomi Redmi Watch 5 Active 2.0 |
| `bench_pomade_20g.jpg` | Bench Barbers Pomade 20g |

A product with no file here renders the designed `MissingImage` placeholder
rather than a broken card, so adding a product without an image is safe.

**Provenance.** These are third-party marketplace and retailer product photos,
bundled with permission for this academic prototype. If you are reusing this
project commercially, replace them — do not assume the permission extends.

**Adding one:** drop the file in, point `Product.imageUrl` at
`assets/products/<id>.jpg`, and keep the size sensible. Five images are 175 KB;
fifty would be ~1.75 MB, which is the reason `assets/products` is worth keeping
tight.