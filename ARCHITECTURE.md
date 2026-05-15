# PawVault — Architecture & Handoff Guide

## Tech Stack
- Flutter 3.x · Dart 3.x
- State management: flutter_bloc 8.x (BLoC pattern)
- Navigation: go_router 14.x
- Backend: Supabase (Auth + Postgres + Storage)
- Animations: Lottie + flutter_animate
- Charts: fl_chart
- Calendar: table_calendar

## Project Structure
```
lib/
├── core/
│   ├── theme/          # AppColors, AppTheme (design tokens from PDF)
│   ├── constants/      # AppConstants (Supabase keys, sizing)
│   └── router/         # GoRouter config + auth guard
├── data/
│   ├── models/         # Pet, Vaccine, Medication, HealthRecord, CareEvent
│   └── repositories/   # AuthRepository, PetRepository, VaccineRepository, etc.
├── features/
│   ├── onboarding/     # 3-step carousel with Lottie hero
│   ├── auth/           # Sign in / Sign up with BLoC
│   ├── add_pet/        # Multi-step pet creation (species → avatar → basics)
│   ├── home/           # Daily landing: pet hero, quick care, today checklist
│   ├── pet_profile/    # Tabs: Overview / Health / Photos
│   ├── vaccines/       # Booster card, status badges, filterable list
│   ├── records/        # Annual spend, timeline grouped by month
│   ├── medications/    # Progress ring, active meds, refill alerts
│   ├── care_calendar/  # TableCalendar + vertical event rail
│   ├── ai_assistant/   # Chat UI with triage cards
│   ├── notifications/  # Grouped + filtered notifications
│   └── pro_upgrade/    # Paywall: monthly/yearly toggle
└── shared/
    └── widgets/        # PetAvatarWidget, MoodSelectorRow, MainShell (nav)
```

## BLoC Conventions
Each feature follows: `event → bloc → state`
- Events: named as `FeatureAction` (e.g. `HomeLoaded`, `AddPetSubmitted`)
- States: sealed base class + subtypes (Loading, Ready, Error)
- Blocs are provided at the page level via `BlocProvider`

## Lottie Avatar System
Lottie files follow naming: `assets/animations/{species}_{mood}.json`
- species: dog, cat, rabbit, bird
- mood: idle, happy, running, sleeping
Total: 16 animation files needed

## Supabase Setup
Run `supabase/schema.sql` in your Supabase SQL editor.
Update `AppConstants.supabaseUrl` and `AppConstants.supabaseAnonKey`.

## What's Next
- [ ] Wire VaccineRepository into VaccinesPage BLoC
- [ ] Wire MedicationRepository into MedicationsPage BLoC  
- [ ] Wire RecordsRepository into RecordsPage BLoC
- [ ] Add push notifications (supabase_flutter + local_notifications)
- [ ] Pro upgrade: integrate RevenueCat
- [ ] AI Assistant: wire to Claude API or OpenAI
- [ ] Download Lottie animation files for all 16 species/mood combos
- [ ] Add BricolageGrotesque font files to assets/fonts/
