// Central API keys + minimal global app state used by screens.
// Replace placeholder values with your real app settings as needed.

// ── GEMINI AI ──────────────────────────────────────────────────────────────
// API key is stored in a local .env file (not committed to GitHub)
// Run: flutter pub add flutter_dotenv, then create .env with GEMINI_API_KEY=your_key
const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

class ApiConfig {
  // Open Exchange Rates
  static const String openExchangeAppId = '46231008999b422399191af3964900eb';
  static const String openExchangeUrl =
      'https://openexchangerates.org/api/latest.json';
}

/// Mutable global settings structure referenced by UI screens.
/// main.dart expects to assign to these fields at startup.
class GlobalSettings {
  String businessName;
  String businessType;
  String currency;
  bool setupComplete;

  GlobalSettings({
    this.businessName = 'My Business',
    this.businessType = 'Retail',
    this.currency = 'KES',
    this.setupComplete = false,
  });
}

/// Application-wide settings instance (mutable so main.dart can set values).
GlobalSettings globalSettings = GlobalSettings();

/// Runtime session map for authenticated operator (null when signed out).
/// Screens read/write simple keys like 'email', 'fullName', 'role', etc.
Map<String, dynamic>? currentUserSession;

/// Helper to clear runtime session.
void clearCurrentUserSession() {
  currentUserSession = null;
}
