#!/usr/bin/env dart

import 'dart:io';

/// Script to load environment variables from .env files and set them for build processes
/// This is particularly useful for CI/CD environments
void main(List<String> args) {
  final bool isProduction = args.contains('--production') || args.contains('--release');
  final String envFile = isProduction ? '.env.production' : '.env.development';
  
  print('Loading environment variables from: $envFile');
  
  try {
    final file = File(envFile);
    if (!file.existsSync()) {
      print('Warning: Environment file $envFile not found');
      return;
    }
    
    final lines = file.readAsLinesSync();
    
    for (final line in lines) {
      if (line.trim().isEmpty || line.trim().startsWith('#')) {
        continue; // Skip empty lines and comments
      }
      
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        
        // Remove quotes if present
        String cleanValue = value;
        if (value.startsWith('"') && value.endsWith('"')) {
          cleanValue = value.substring(1, value.length - 1);
        } else if (value.startsWith("'") && value.endsWith("'")) {
          cleanValue = value.substring(1, value.length - 1);
        }
        
        // Set environment variable
        Platform.environment[key] = cleanValue;
        print('Set $key');
      }
    }
    
    print('Environment variables loaded successfully!');
    
    // Special handling for Android keystore configuration
    if (isProduction) {
      _generateKeystoreProperties();
    }
    
  } catch (e) {
    print('Error loading environment variables: $e');
    exit(1);
  }
}

/// Generate Android keystore properties file with environment variables
void _generateKeystoreProperties() {
  try {
    final keystoreFile = File('android/key.properties');
    final storePassword = Platform.environment['ANDROID_KEYSTORE_PASSWORD'] ?? '';
    final keyPassword = Platform.environment['ANDROID_KEY_PASSWORD'] ?? '';
    final keyAlias = Platform.environment['ANDROID_KEY_ALIAS'] ?? '';
    final storeFile = Platform.environment['ANDROID_KEYSTORE_PATH'] ?? '';
    
    final content = '''
# Generated keystore configuration
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=$storeFile
''';
    
    keystoreFile.writeAsStringSync(content);
    print('Generated android/key.properties with environment variables');
  } catch (e) {
    print('Warning: Could not generate keystore properties: $e');
  }
} 