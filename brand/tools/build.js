const sharp = require('sharp');
const toIco = require('to-ico');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SVG = path.join(ROOT, 'svg');
const OUT = path.join(ROOT, 'png');

const ICON_MASTER = fs.readFileSync(path.join(SVG, 'icon-master.svg'));
const ICON_TRANSPARENT = fs.readFileSync(path.join(SVG, 'icon-transparent.svg'));
const ICON_MONO_WHITE = fs.readFileSync(path.join(SVG, 'icon-mono-white.svg'));
const ICON_MONO_BLACK = fs.readFileSync(path.join(SVG, 'icon-mono-black.svg'));
const LOCKUP_FULL = fs.readFileSync(path.join(SVG, 'lockup-full.svg'));
const LOCKUP_HORIZONTAL = fs.readFileSync(path.join(SVG, 'lockup-horizontal.svg'));
const LOCKUP_LIGHT = fs.readFileSync(path.join(SVG, 'lockup-light.svg'));
const WORDMARK = fs.readFileSync(path.join(SVG, 'wordmark.svg'));
const ICON_ROUNDED_SQUARE = fs.readFileSync(path.join(SVG, 'icon-rounded-square.svg'));
const ICON_SQUARE_FLAT = fs.readFileSync(path.join(SVG, 'icon-square-flat.svg'));

async function png(svgBuffer, size, outPath, opts = {}) {
  await sharp(svgBuffer, { density: 384 })
    .resize(size, size, { fit: 'contain', background: opts.background ?? { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile(outPath);
  console.log('wrote', outPath, `${size}x${size}`);
}

async function pngWH(svgBuffer, width, height, outPath) {
  await sharp(svgBuffer, { density: 384 })
    .resize(width, height, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile(outPath);
  console.log('wrote', outPath, `${width}x${height}`);
}

async function main() {
  // --- App icons (rounded-square, dark navy bg, safe-zone padded) ---
  // Android/web/PWA/general use — rounded corners baked in.
  const appIconSizes = [512, 256, 192, 152, 144, 120, 96, 72, 60, 48, 40, 36, 32, 29, 16];
  for (const size of appIconSizes) {
    await png(ICON_ROUNDED_SQUARE, size, path.join(OUT, 'app-icons', `icon-${size}.png`));
  }
  // iOS App Store icon — flat square, no pre-applied corner rounding or
  // transparency (Apple masks it themselves; a rounded/transparent 1024 gets
  // rejected by App Store Connect).
  await png(ICON_SQUARE_FLAT, 1024, path.join(OUT, 'app-icons', 'icon-1024-ios-appstore.png'), {
    background: { r: 11, g: 20, b: 32, alpha: 1 },
  });
  await png(ICON_ROUNDED_SQUARE, 180, path.join(OUT, 'app-icons', 'icon-180.png'));

  // --- Favicon PNGs + multi-res .ico ---
  const faviconSizes = [16, 32, 48];
  for (const size of faviconSizes) {
    await png(ICON_ROUNDED_SQUARE, size, path.join(OUT, 'favicon', `favicon-${size}.png`));
  }
  const icoBuffers = await Promise.all(
    faviconSizes.map((s) =>
      sharp(ICON_ROUNDED_SQUARE, { density: 384 })
        .resize(s, s)
        .png()
        .toBuffer(),
    ),
  );
  const ico = await toIco(icoBuffers);
  fs.writeFileSync(path.join(OUT, 'favicon', 'favicon.ico'), ico);
  console.log('wrote favicon.ico (16/32/48 multi-res)');

  // PWA/manifest icons
  await png(ICON_ROUNDED_SQUARE, 192, path.join(OUT, 'favicon', 'icon-192.png'));
  await png(ICON_ROUNDED_SQUARE, 512, path.join(OUT, 'favicon', 'icon-512.png'));
  await png(ICON_TRANSPARENT, 192, path.join(OUT, 'favicon', 'icon-192-maskable.png'));
  await png(ICON_TRANSPARENT, 512, path.join(OUT, 'favicon', 'icon-512-maskable.png'));

  // --- Social avatars (square, icon centered on brand bg) ---
  for (const size of [1024, 512, 400]) {
    await png(ICON_ROUNDED_SQUARE, size, path.join(OUT, 'social', `avatar-${size}.png`));
  }

  // --- Icon on transparent background, various sizes (flexible placement) ---
  for (const size of [1024, 512, 256, 128]) {
    await png(ICON_TRANSPARENT, size, path.join(OUT, 'app-icons', `icon-transparent-${size}.png`));
  }

  // --- Full vertical lockup (icon + wordmark + tagline), dark bg ---
  await pngWH(LOCKUP_FULL, 1200, 1200, path.join(OUT, 'lockup', 'lockup-full-dark@2x.png'));
  await pngWH(LOCKUP_FULL, 600, 600, path.join(OUT, 'lockup', 'lockup-full-dark@1x.png'));

  // --- Full vertical lockup, light background variant ---
  await pngWH(LOCKUP_LIGHT, 1200, 1200, path.join(OUT, 'lockup', 'lockup-full-light@2x.png'));
  await pngWH(LOCKUP_LIGHT, 600, 600, path.join(OUT, 'lockup', 'lockup-full-light@1x.png'));

  // --- Horizontal lockup (icon left, wordmark right) — for headers/nav bars ---
  await pngWH(LOCKUP_HORIZONTAL, 2000, 500, path.join(OUT, 'lockup', 'lockup-horizontal-dark@2x.png'));
  await pngWH(LOCKUP_HORIZONTAL, 1000, 250, path.join(OUT, 'lockup', 'lockup-horizontal-dark@1x.png'));

  // --- Wordmark only (no icon) — for letterhead/documents ---
  await pngWH(WORDMARK, 1600, 320, path.join(OUT, 'lockup', 'wordmark-dark@2x.png'));
  await pngWH(WORDMARK, 800, 160, path.join(OUT, 'lockup', 'wordmark-dark@1x.png'));

  // --- Monochrome versions (icon only) ---
  for (const size of [512, 256, 128]) {
    await png(ICON_MONO_WHITE, size, path.join(OUT, 'monochrome', `icon-white-${size}.png`));
    await png(ICON_MONO_BLACK, size, path.join(OUT, 'monochrome', `icon-black-${size}.png`));
  }

  console.log('\nAll assets generated.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
