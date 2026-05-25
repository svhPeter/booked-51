#!/usr/bin/env python3
"""
Generate iOS 18 dark/tinted app icon variants from source icon.

Usage: python3 mobile/assets/icons/generate_icons.py

Output:
  - mobile/assets/icons/app_icon_light.png   (default, 1024x1024)
  - mobile/assets/icons/app_icon_dark.png    (dark variant, 1024x1024)
  - mobile/assets/icons/app_icon_tinted.png  (tinted variant, 1024x1024)
  - Resized PNGs placed in AppIcon.appiconset/ with appearance variants
  - Updated Contents.json
"""

import os
import json
import math

from PIL import Image, ImageFilter, ImageChops

SRC = 'mobile/assets/icons/app_icon.png'
ASSETS_DIR = 'mobile/assets/icons'
IOS_ICON_DIR = 'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset'

# iOS required sizes: (size_pt, scale, idiom)
IOS_SIZES = [
    (20, 2, 'iphone'),
    (20, 3, 'iphone'),
    (29, 1, 'iphone'),
    (29, 2, 'iphone'),
    (29, 3, 'iphone'),
    (40, 2, 'iphone'),
    (40, 3, 'iphone'),
    (60, 2, 'iphone'),
    (60, 3, 'iphone'),
    (20, 1, 'ipad'),
    (20, 2, 'ipad'),
    (29, 1, 'ipad'),
    (29, 2, 'ipad'),
    (40, 1, 'ipad'),
    (40, 2, 'ipad'),
    (76, 1, 'ipad'),
    (76, 2, 'ipad'),
    (83.5, 2, 'ipad'),
    (1024, 1, 'ios-marketing'),
]


def make_filename(base_size_pt, scale, suffix=''):
    name = f'Icon-App-{base_size_pt}x{base_size_pt}'
    name += f'@{scale}x'
    if suffix:
        name += f'_{suffix}'
    name += '.png'
    return name


def create_light_1024(src):
    """Upscale source 512x512 to 1024x1024 (default variant - keep as-is)."""
    return src.resize((1024, 1024), Image.LANCZOS)


def create_dark_1024(src):
    """
    Dark variant: invert white bg → dark slate, map blue → light blue.
    """
    img = src.resize((1024, 1024), Image.LANCZOS)
    pixels = img.load()
    w, h = img.size

    DARK_BG = (30, 41, 59)       # #1E293B
    LIGHT_BLUE = (96, 165, 250)  # #60A5FA
    WHITE = (255, 255, 255)

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 10:
                continue
            lum = 0.299 * r + 0.587 * g + 0.114 * b

            # White/light background → dark bg
            if lum > 200 and r > 200 and g > 200 and b > 200:
                pixels[x, y] = (*DARK_BG, a)
            else:
                # Dark blue areas → light blue + brighten
                nr = min(255, int(r * 1.4 + 20))
                ng = min(255, int(g * 1.4 + 20))
                nb = min(255, int(b * 1.4 + 20))
                # Boost blue channel
                nb = min(255, nb + 30)
                pixels[x, y] = (nr, ng, nb, a)
    return img


def create_tinted_1024(src):
    """
    Tinted variant: high-contrast grayscale for iOS tinting.
    Background → white, symbol → near-black.
    Handles transparency properly.
    """
    img = src.resize((1024, 1024), Image.LANCZOS)
    pixels = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 10:
                continue
            lum = 0.299 * r + 0.587 * g + 0.114 * b

            # Background (light) → white
            if lum > 200:
                pixels[x, y] = (255, 255, 255, a)
            else:
                # Symbol → dark gray/black for contrast
                gray = max(0, int(lum * 0.3))
                pixels[x, y] = (gray, gray, gray, a)
    return img


def write_resized_pngs(base_img, dir_path, suffix, appearance):
    """
    Resize base_img (1024x1024) to all iOS sizes and write PNGs.
    Returns list of image entries for Contents.json.
    """
    os.makedirs(dir_path, exist_ok=True)

    entries = []
    for size_pt, scale, idiom in IOS_SIZES:
        px = int(size_pt * scale)
        resized = base_img.resize((px, px), Image.LANCZOS)
        fname = make_filename(size_pt, scale, suffix)

        # Ensure directory exists
        os.makedirs(dir_path, exist_ok=True)
        filepath = os.path.join(dir_path, fname)
        resized.save(filepath, 'PNG')

        entry = {
            'size': f'{size_pt}x{size_pt}',
            'idiom': idiom,
            'filename': fname,
            'scale': f'{scale}x',
        }
        if appearance:
            entry['appearances'] = [appearance]
        entries.append(entry)
    return entries


def main():
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(IOS_ICON_DIR, exist_ok=True)

    src = Image.open(SRC).convert('RGBA')
    print(f'Source: {SRC} ({src.size})')

    # Generate 1024px base variants
    light_img = create_light_1024(src)
    dark_img = create_dark_1024(src)
    tinted_img = create_tinted_1024(src)

    # Save source assets
    light_img.save(os.path.join(ASSETS_DIR, 'app_icon_light.png'), 'PNG')
    dark_img.save(os.path.join(ASSETS_DIR, 'app_icon_dark.png'), 'PNG')
    tinted_img.save(os.path.join(ASSETS_DIR, 'app_icon_tinted.png'), 'PNG')
    print('Saved source assets: app_icon_light/dark/tinted.png')

    # Clean up old PNGs once before writing all variants
    for f in os.listdir(IOS_ICON_DIR):
        if f.endswith('.png') and f != 'Contents.json':
            os.remove(os.path.join(IOS_ICON_DIR, f))

    # Resize and write all iOS sizes + collect Contents.json entries
    light_entries = write_resized_pngs(light_img, IOS_ICON_DIR, '', None)
    dark_entries = write_resized_pngs(dark_img, IOS_ICON_DIR, 'dark',
        {'appearance': 'luminosity', 'value': 'dark'})
    tinted_entries = write_resized_pngs(tinted_img, IOS_ICON_DIR, 'tinted',
        {'appearance': 'luminosity', 'value': 'tinted'})

    print(f'Wrote {len(light_entries)} light, {len(dark_entries)} dark, {len(tinted_entries)} tinted PNGs')

    # Write Contents.json
    contents = {
        'images': light_entries + dark_entries + tinted_entries,
        'info': {'version': 1, 'author': 'xcode'},
    }

    # Clean up old PNGs that don't have suffixes - they're replaced by light_entries
    for f in os.listdir(IOS_ICON_DIR):
        if f.endswith('.png') and f != '.gitkeep':
            # Keep files that match our new naming (no suffix = light, or have _dark/_tinted)
            pass  # We'll overwrite/keep all

    with open(os.path.join(IOS_ICON_DIR, 'Contents.json'), 'w') as f:
        json.dump(contents, f, indent=2)
    print('Updated Contents.json with dark/tinted appearance variants')

    # Summary
    print('\n=== Generated ===')
    print(f'Default (any): {len(light_entries)} sizes')
    print(f'Dark:          {len(dark_entries)} sizes')
    print(f'Tinted:        {len(tinted_entries)} sizes')
    print(f'Total entries: {len(light_entries) + len(dark_entries) + len(tinted_entries)}')
    print('Done.')


if __name__ == '__main__':
    main()
