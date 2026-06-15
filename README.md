# BIT4107 Mobile Development - Retail Analytics Engine

## Week 3 — Flutter UI & Architecture
- Built complete retail analytics app in Flutter
- Created 5 screens: Catalog, Stock Entry, P&L Dashboard, Advisory Engine, Setup Wizard
- Implemented dynamic inventory management
- Added predictive advisory engine with business recommendations

## Week 4 — Local Database & Data Persistence
Practical: Create an app that stores and retrieves data using SQLite

- Integrated SQLite database using sqflite package for mobile
- Integrated Sembast database for web support
- All products, sales and transactions persist after app restart
- P&L Dashboard pulls live data from local database
- Full CRUD operations implemented

Key files:
- lib/services/database_helper.dart
- lib/models/inventory_item.dart

## Week 5 — Networking & REST API Integration
Practical: Create an app that retrieves data from a public API and displays it

- Added http package for network requests
- Open Exchange Rates API — live KES/USD/EUR/GBP rates
- World Bank API — Kenya inflation and GDP data
- KES to USD conversion on every product card
- Smart business advice generated from live economic data

Key files:
- lib/services/currency_service.dart
- lib/services/world_bank_service.dart
- lib/screens/currency_screen.dart
- lib/api_config.dart

## How to Run
Mobile: flutter run
Web: flutter run -d chrome --web-browser-flag "--disable-web-security"

## GitHub Tags
- Week4-SQLite-Database — Week 4 submission
- Week5-API-Networking — Week 5 submission