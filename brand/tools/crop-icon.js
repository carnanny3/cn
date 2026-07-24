const sharp = require('sharp');
const path = require('path');

const SRC = path.resolve(__dirname, '..', 'CarNanny Black.png');
const OUT = path.resolve(__dirname, '..', 'final', 'icon-only');

// Determined from pixel analysis: icon content spans x:178-331, y:120-292;
// wordmark starts at y:304. Crop a 210x210 square (149,90)-(359,300) that
// centers the icon horizontally with ~28-29px side padding and stays a
// few px clear of the wordmark below.
const CROP = { left: 149, top: 90, width: 210, height: 210 };

async function main() {
  const cropped = await sharp(SRC).extract(CROP).png().toBuffer();

  await sharp(cropped).png().toFile(path.join(OUT, 'icon-only-master.png'));
  console.log('wrote icon-only-master.png (210x210, uncompressed crop)');

  const sizes = [1024, 512, 256, 192, 180, 152, 144, 120, 96, 72, 60, 48, 40, 36, 32, 29, 16];
  for (const size of sizes) {
    await sharp(cropped).resize(size, size).png().toFile(path.join(OUT, `icon-${size}.png`));
    console.log('wrote', `icon-${size}.png`, `${size}x${size}`);
  }

  const toIco = require('to-ico');
  const icoSizes = [16, 32, 48];
  const icoBuffers = await Promise.all(
    icoSizes.map((s) => sharp(cropped).resize(s, s).png().toBuffer()),
  );
  const fs = require('fs');
  fs.writeFileSync(path.join(OUT, 'favicon.ico'), await toIco(icoBuffers));
  console.log('wrote favicon.ico (16/32/48 multi-res)');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
