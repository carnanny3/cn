const sharp = require('sharp');
const path = require('path');

const MASTER = path.resolve(__dirname, '..', 'final', 'icon-only', 'icon-only-master.png');
const DEST = path.resolve(__dirname, '..', '..', 'mobile', 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');

// filename -> pixel size, derived from iOS's "Icon-App-{base}@{scale}x.png" convention
const FILES = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
};

async function main() {
  for (const [filename, size] of Object.entries(FILES)) {
    await sharp(MASTER).resize(size, size).png().toFile(path.join(DEST, filename));
    console.log('wrote', filename, `${size}x${size}`);
  }

  // App Store icon: must be fully opaque with no alpha channel at all.
  await sharp(MASTER)
    .flatten({ background: '#000000' })
    .resize(1024, 1024)
    .png({ palette: false })
    .toFile(path.join(DEST, 'Icon-App-1024x1024@1x.png'));
  console.log('wrote Icon-App-1024x1024@1x.png 1024x1024 (flattened, no alpha)');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
