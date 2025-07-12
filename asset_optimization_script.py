#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

def optimize_images():
    """Optimize WebP and PNG images in assets folder"""
    assets_dir = Path("assets")
    
    print("🖼️  Optimizing images...")
    
    # Find all image files
    image_files = []
    for ext in ['*.webp', '*.png', '*.jpg', '*.jpeg']:
        image_files.extend(assets_dir.rglob(ext))
    
    total_before = 0
    total_after = 0
    
    for img_file in image_files:
        if img_file.name == '.DS_Store':
            continue
            
        before_size = img_file.stat().st_size
        total_before += before_size
        
        print(f"📁 {img_file.name}: {before_size / 1024:.1f} KB")
        
        # For WebP files, we can re-compress with higher compression
        if img_file.suffix == '.webp':
            temp_file = str(img_file) + "_temp"
            try:
                # Use cwebp for better compression (requires webp tools)
                subprocess.run([
                    'cwebp', '-q', '80', '-m', '6', str(img_file), '-o', temp_file
                ], check=True, capture_output=True)
                
                # Replace if smaller
                temp_size = Path(temp_file).stat().st_size
                if temp_size < before_size:
                    os.replace(temp_file, str(img_file))
                    print(f"  ✅ Reduced by {(before_size - temp_size) / 1024:.1f} KB")
                else:
                    os.remove(temp_file)
                    print(f"  ➡️  Already optimized")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"  ⚠️  WebP tools not available, skipping optimization")
                if os.path.exists(temp_file):
                    os.remove(temp_file)
        
        # For PNG files, suggest converting to WebP
        elif img_file.suffix == '.png':
            webp_file = str(img_file).replace('.png', '.webp')
            try:
                subprocess.run([
                    'cwebp', '-q', '85', str(img_file), '-o', webp_file
                ], check=True, capture_output=True)
                
                webp_size = Path(webp_file).stat().st_size
                if webp_size < before_size * 0.8:  # Only if significant reduction
                    print(f"  💡 Consider replacing with WebP: {webp_size / 1024:.1f} KB (save {(before_size - webp_size) / 1024:.1f} KB)")
                else:
                    os.remove(webp_file)
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"  ⚠️  WebP tools not available")
        
        after_size = img_file.stat().st_size
        total_after += after_size
    
    print(f"\n📊 Total assets: {total_before / 1024:.1f} KB → {total_after / 1024:.1f} KB")
    if total_before > total_after:
        print(f"💾 Saved: {(total_before - total_after) / 1024:.1f} KB")

def find_unused_assets():
    """Find assets that might not be used in the code"""
    print("\n🔍 Searching for unused assets...")
    
    assets_dir = Path("assets")
    lib_dir = Path("lib")
    
    # Get all asset files
    asset_files = []
    for file_path in assets_dir.rglob("*"):
        if file_path.is_file() and file_path.name != '.DS_Store':
            asset_files.append(file_path)
    
    # Read all Dart files
    dart_content = ""
    for dart_file in lib_dir.rglob("*.dart"):
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                dart_content += f.read()
        except:
            continue
    
    # Check resource.dart file
    resource_file = Path("lib/const/resource.dart")
    resource_content = ""
    if resource_file.exists():
        with open(resource_file, 'r', encoding='utf-8') as f:
            resource_content = f.read()
    
    unused_assets = []
    for asset_file in asset_files:
        asset_name = asset_file.name
        asset_path = str(asset_file).replace('\\', '/')
        
        # Check if referenced in code or resource file
        if (asset_name not in dart_content and 
            asset_path not in dart_content and 
            asset_name not in resource_content and
            asset_path not in resource_content):
            unused_assets.append(asset_file)
    
    if unused_assets:
        print("⚠️  Potentially unused assets:")
        total_unused_size = 0
        for asset in unused_assets:
            size = asset.stat().st_size
            total_unused_size += size
            print(f"  📁 {asset.relative_to(Path('.'))} ({size / 1024:.1f} KB)")
        print(f"💾 Total potentially unused: {total_unused_size / 1024:.1f} KB")
    else:
        print("✅ All assets appear to be in use")

def remove_ds_store_files():
    """Remove .DS_Store files"""
    print("\n🧹 Removing .DS_Store files...")
    ds_store_files = list(Path(".").rglob(".DS_Store"))
    for ds_file in ds_store_files:
        try:
            ds_file.unlink()
            print(f"🗑️  Removed {ds_file}")
        except:
            pass

if __name__ == "__main__":
    print("🚀 Starting asset optimization...\n")
    
    remove_ds_store_files()
    find_unused_assets()
    optimize_images()
    
    print("\n✨ Asset optimization complete!")
    print("\n💡 Next steps:")
    print("1. Install WebP tools: brew install webp (macOS) or apt-get install webp (Ubuntu)")
    print("2. Run this script again after installing WebP tools for better compression")
    print("3. Consider removing unused assets if confirmed they're not needed")
    print("4. Use flutter build apk --analyze-size to check new size") 