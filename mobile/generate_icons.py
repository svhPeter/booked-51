import os
import subprocess

def generate_icons():
    source_icon = "assets/icons/app_icon.png"
    if not os.path.exists(source_icon):
        print(f"Error: Source icon not found at {source_icon}")
        return

    # iOS Target Directory
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_icons = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024)
    ]

    print("Generating iOS icons...")
    os.makedirs(ios_dir, exist_ok=True)
    for name, size in ios_icons:
        dest = os.path.join(ios_dir, name)
        subprocess.run(["sips", "-z", str(size), str(size), source_icon, "--out", dest], check=True)
        print(f"Generated: {dest} ({size}x{size})")

    # Android Target Directory
    android_res_dir = "android/app/src/main/res"
    android_icons = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192)
    ]

    print("Generating Android mipmap icons...")
    for folder, size in android_icons:
        folder_path = os.path.join(android_res_dir, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Standard launcher icon
        dest = os.path.join(folder_path, "ic_launcher.png")
        subprocess.run(["sips", "-z", str(size), str(size), source_icon, "--out", dest], check=True)
        
        # Round launcher icon
        dest_round = os.path.join(folder_path, "ic_launcher_round.png")
        subprocess.run(["sips", "-z", str(size), str(size), source_icon, "--out", dest_round], check=True)
        
        print(f"Generated Android {folder} icons ({size}x{size})")

    print("All native app icons generated successfully!")

if __name__ == "__main__":
    generate_icons()
