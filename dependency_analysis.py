#!/usr/bin/env python3
import yaml
import subprocess
import json
from pathlib import Path

def analyze_dependencies():
    """Analyze pubspec.yaml for potential optimizations"""
    print("📦 Analyzing dependencies...\n")
    
    with open('pubspec.yaml', 'r') as f:
        pubspec = yaml.safe_load(f)
    
    dependencies = pubspec.get('dependencies', {})
    dev_dependencies = pubspec.get('dev_dependencies', {})
    
    # Heavy dependencies that might have lighter alternatives
    heavy_deps = {
        'google_maps_flutter': 'Heavy mapping - consider alternatives like map_launcher',
        'firebase_messaging': 'Check if all Firebase features are needed',
        'webview_flutter': 'Large WebView implementation',
        'image_picker': 'Consider file_picker if only file selection needed',
        'geolocator': 'Heavy location package',
        'permission_handler': 'Large permission management'
    }
    
    # Dependencies that might be unused
    potentially_unused = []
    
    print("🔍 Current dependencies analysis:")
    for dep, version in dependencies.items():
        if dep == 'flutter':
            continue
            
        size_impact = "📦"
        notes = ""
        
        if dep in heavy_deps:
            size_impact = "⚠️"
            notes = f" - {heavy_deps[dep]}"
        
        print(f"{size_impact} {dep}: {version}{notes}")
    
    # Check for commented dependencies
    print("\n💭 Found commented dependencies in pubspec.yaml:")
    with open('pubspec.yaml', 'r') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines):
        if line.strip().startswith('#') and any(x in line for x in ['google_maps', 'webview_universal']):
            print(f"  Line {i+1}: {line.strip()}")
    
    return dependencies

def find_unused_dependencies():
    """Find potentially unused dependencies by scanning import statements"""
    print("\n🔍 Scanning for unused dependencies...\n")
    
    # Read all Dart files
    dart_files = list(Path('lib').rglob('*.dart'))
    import_statements = set()
    
    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('import \'package:') and not line.startswith('import \'package:marketplace_app'):
                        # Extract package name
                        package = line.split('package:')[1].split('/')[0].replace('\'', '').replace(';', '')
                        import_statements.add(package)
        except:
            continue
    
    # Load dependencies from pubspec
    with open('pubspec.yaml', 'r') as f:
        pubspec = yaml.safe_load(f)
    
    dependencies = set(pubspec.get('dependencies', {}).keys())
    dependencies.discard('flutter')
    
    # Find unused dependencies
    unused = dependencies - import_statements
    
    if unused:
        print("⚠️  Potentially unused dependencies:")
        for dep in sorted(unused):
            print(f"  📦 {dep}")
        print(f"\n💾 Consider removing {len(unused)} unused dependencies")
    else:
        print("✅ All dependencies appear to be in use")
    
    # Find imports without dependencies (shouldn't happen)
    missing_deps = import_statements - dependencies
    if missing_deps:
        print(f"\n⚠️  Imports without dependencies (check dev_dependencies):")
        for dep in sorted(missing_deps):
            print(f"  📦 {dep}")

def suggest_optimizations():
    """Suggest specific optimizations"""
    print("\n💡 Optimization suggestions:\n")
    
    optimizations = [
        {
            "category": "🖼️ Assets",
            "suggestions": [
                "Convert PNG images to WebP (20-50% size reduction)",
                "Optimize WebP compression quality (current images can be compressed further)",
                "Remove .DS_Store files (18KB saved)",
                "Consider using SVG for simple icons instead of PNG"
            ]
        },
        {
            "category": "📦 Dependencies",
            "suggestions": [
                "Review if all Firebase features are needed",
                "Consider lighter alternatives for heavy packages",
                "Remove commented dependencies from pubspec.yaml",
                "Use pub deps to analyze dependency tree"
            ]
        },
        {
            "category": "🏗️ Build Optimization",
            "suggestions": [
                "Use --split-per-abi for smaller APKs per architecture",
                "Enable proguard/R8 optimization in release builds",
                "Use --target-platform to build for specific architectures only",
                "Consider App Bundle (.aab) instead of APK for Play Store"
            ]
        },
        {
            "category": "📱 Code Optimization",
            "suggestions": [
                "Remove unused Dart files and imports",
                "Use tree shaking for icons (already enabled)",
                "Minimize use of reflection and dynamic code",
                "Use const constructors where possible"
            ]
        }
    ]
    
    for opt in optimizations:
        print(f"{opt['category']}")
        for suggestion in opt['suggestions']:
            print(f"  • {suggestion}")
        print()

def create_optimization_commands():
    """Create shell commands for quick optimization"""
    print("🚀 Quick optimization commands:\n")
    
    commands = [
        "# Remove .DS_Store files",
        "find . -name '.DS_Store' -delete",
        "",
        "# Build optimized APK for specific architecture",
        "flutter build apk --target-platform android-arm64 --obfuscate --split-debug-info=build/debug-info",
        "",
        "# Build App Bundle (recommended for Play Store)",
        "flutter build appbundle --obfuscate --split-debug-info=build/debug-info",
        "",
        "# Analyze dependencies",
        "flutter pub deps --style=compact",
        "",
        "# Clean and rebuild",
        "flutter clean && flutter pub get && flutter build apk --target-platform android-arm64 --analyze-size"
    ]
    
    for cmd in commands:
        print(cmd)

if __name__ == "__main__":
    print("🔍 Dependency Analysis & Optimization Guide\n")
    
    analyze_dependencies()
    find_unused_dependencies()
    suggest_optimizations()
    create_optimization_commands()
    
    print("\n✨ Analysis complete! Run the asset optimization script next.") 