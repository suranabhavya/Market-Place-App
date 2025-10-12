class AmenityEmojiMap {
  static const Map<String, String> _amenityEmojiMap = {
    // Fitness & Recreation
    "Gym": "🏋️",
    "Pool": "🏊",
    "Tennis Court": "🎾",
    "Basketball Court": "🏀",
    "Yoga Studio": "🧘",
    "Spa": "🧖",
    "Sauna": "🧖‍♂️",
    "Tub": "🛀",
    "Fitness Center": "💪",
    "Sports Court": "⚽",
    
    // Transportation & Parking
    "Garage": "🏠",
    "Bike Storage": "🚲",
    "EV Charging": "🔌",
    "Parking": "🚗",
    
    // Comfort & Convenience
    "Air Conditioning": "❄️",
    "Heating": "🔥",
    "Laundry": "🧺",
    "Dishwasher": "🍽️",
    "Microwave": "📡",
    "WiFi": "📶",
    "High Speed Internet": "🌐",
    "Cable TV": "📺",
    "Elevator": "🛗",
    "Grocery Store Nearby": "🛒",
    "School Nearby": "🏫",
    "Hospital Nearby": "🏥",
    "Shopping Nearby": "🛍️",
    "Restaurant Nearby": "🍔",
    "Bar Nearby": "🍺",
    "Coffee Shop Nearby": "☕",
    
    // Outdoor & Garden
    "Balcony / Terrace": "🏡",
    "Patio": "🪴",
    "Garden / Backyard": "🌱",
    "Rooftop": "🏢",
    "BBQ Area": "🔥",
    "Fire Pit": "🔥",
    "Outdoor Kitchen": "🍳",
    
    // Security & Safety
    "Security": "🔒",
    "Doorman": "🚪",
    "CCTV": "📹",
    "Intercom": "📞",
    "Key Card Access": "🗝️",
    "Gated Community": "🚧",
    
    // Social & Entertainment
    "Clubhouse": "🏠",
    "Lounge": "🛋️",
    "Game Room": "🎮",
    "Movie Theater": "🎬",
    "Library": "📚",
    "Co-working Space": "💻",
    "Conference Room": "👥",
    "Event Hall": "🎉",
    
    // Kitchen & Dining
    "Kitchen": "🍳",
    "Full Kitchen": "👨‍🍳",
    "Kitchenette": "🥘",
    "Dining Room": "🍽️",
    "Breakfast Bar": "☕",
    "Wine Cellar": "🍷",
    
    // Pets & Family
    "Pet Friendly": "🐕",
    "Dog Park": "🐕‍🦺",
    "Pet Wash": "🛁",
    "Playground": "🎠",
    "Kids Area": "👶",
    "Childcare": "👨‍👩‍👧‍👦",
    
    // Services
    "Concierge": "🛎️",
    "Maintenance": "🔧",
    "Housekeeping": "🧹",
    "Package Service": "📦",
    "Dry Cleaning": "👔",
    "Storage": "📦",
    
    // Utilities
    "Water Included": "💧",
    "Electricity Included": "⚡",
    "Gas Included": "🔥",
    "Trash Pickup": "🗑️",
    "Recycling": "♻️",
    "Private Bathroom": "🛁",
    "Smoke Detector": "🚨",
    
    // Default fallback
    "Other": "✨",
  };

  /// Get emoji for an amenity name
  /// Returns the corresponding emoji or a default emoji if not found
  static String getEmoji(String amenityName) {
    return _amenityEmojiMap[amenityName] ?? "✨";
  }

  /// Get formatted amenity text with emoji
  /// Returns "emoji amenityName" format
  static String getFormattedAmenity(String amenityName) {
    final emoji = getEmoji(amenityName);
    return "$emoji $amenityName";
  }

  /// Check if an amenity has a specific emoji mapping
  static bool hasMapping(String amenityName) {
    return _amenityEmojiMap.containsKey(amenityName);
  }

  /// Get all available amenity names
  static List<String> getAllAmenityNames() {
    return _amenityEmojiMap.keys.toList();
  }
} 