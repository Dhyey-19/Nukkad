# Nukkad

Nukkad is a Flutter-based local business discovery and enquiry platform.
It supports customer, business, and admin experiences with Supabase as the backend.

## What This App Does

- Lets customers discover nearby businesses by category and search filters.
- Allows businesses to register, manage profiles, publish offers, and receive enquiries.
- Includes a connects/subscription model for enquiry access.
- Provides emergency contact listings for quick local help.
- Offers admin dashboards for users, businesses, categories, and analytics.

## Core Features

### Authentication and Roles
- Email/password login and signup.
- User type selection and role-based dashboards:
	- Customer
	- Business
	- Admin

### Customer Experience
- Business discovery and search.
- Offers browsing.
- Saved businesses.
- Profile and settings screens.
- Help and support screens.

### Business Experience
- Business onboarding and profile management.
- Enquiry inbox.
- Offer creation and management.
- Analytics and subscription pages.
- Public business landing page.

### Admin Experience
- Admin dashboard.
- Manage users.
- Manage businesses.
- Manage categories.
- View analytics.

## Tech Stack

- Flutter (Dart)
- Supabase (auth + database)
- GetX (navigation/state helpers)
- Shared Preferences (local persistence)
- Geolocator (location)
- FL Chart (analytics)
- PDF + Printing + Share Plus (exports/sharing)

## Project Structure

```text
lib/
	auth/                 # Login, signup, forgot password, user type selection
	dashboard/            # Customer, business, and admin screens
	onboarding/           # Onboarding flow modules
	services/             # Supabase-backed business logic/services
	utils/                # Colors, strings, toast helpers
	widgets/              # Reusable UI components
	main.dart             # App entry and Supabase initialization
```

## Prerequisites

- Flutter SDK (stable)
- Android Studio or VS Code with Flutter/Dart extensions
- Running emulator or physical device
- Supabase project

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Set up the database schema in Supabase SQL Editor:
- Use `supabase_complete_schema_clean.sql` (recommended)
- Or use `supabase_complete_schema.sql` if needed

3. Configure Supabase credentials in `lib/main.dart`:
- `url`
- `anonKey`

4. Run the app:

```bash
flutter run
```

## Build

Build Android APK:

```bash
flutter build apk
```

## Connects and Subscription Model

- Businesses start with limited connects.
- Posting/responding to enquiries consumes connects.
- Subscription unlocks expanded or unlimited enquiry usage.

## Documentation

- Main docs: `documentation/README.md`
- SRS (IEEE 830): `documentation/SRS_IEEE830.md`
- SRS (ISO/IEC/IEEE 29148): `documentation/SRS_29148.md`

## Notes

- Android, iOS, web, desktop folder scaffolds are present.
- If you face Android native build lock issues on Windows, clean build artifacts and rerun:

```bash
flutter clean
flutter pub get
flutter run
```
