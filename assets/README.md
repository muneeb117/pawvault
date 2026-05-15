# PawVault — Asset Directory Guide

Drop your image files in the folders below. The app will pick them up automatically. If a file is missing, the code falls back to a Lucide icon so nothing breaks.

All images: **PNG with transparent background** unless otherwise noted.

---

## `avatars/` — Static pet avatars
Used everywhere a pet is shown (home hero, pet switcher chips, profile, etc.) as a fallback for Lottie.

| Filename       | Size       | Notes                       |
|----------------|------------|-----------------------------|
| `dog.png`      | 512 × 512  | Default dog avatar          |
| `cat.png`      | 512 × 512  | Default cat avatar          |
| `rabbit.png`   | 512 × 512  | Default rabbit avatar       |
| `bird.png`     | 512 × 512  | Default bird avatar         |

---

## `illustrations/` — Onboarding hero illustrations
Optional. If present, replaces the Lottie animation on each welcome slide.

| Filename         | Size       | Slide                                  |
|------------------|------------|----------------------------------------|
| `welcome_1.png`  | 600 × 600  | "A vault for every wag, purr & nuzzle" |
| `welcome_2.png`  | 600 × 600  | "Never miss a booster again"           |
| `welcome_3.png`  | 600 × 600  | "One tap to share with your vet"       |

---

## `icons/care/` — Care category icons (Home → Quick Care row)
Used in the Quick Care row, Today timeline tiles, and category chips.

| Filename       | Size      | Where used                           |
|----------------|-----------|--------------------------------------|
| `vet.png`      | 128 × 128 | "Vet" quick-care tile, vet records   |
| `meds.png`     | 128 × 128 | "Meds" tile, medication tiles        |
| `walk.png`     | 128 × 128 | "Walk" tile, activity events         |
| `meal.png`     | 128 × 128 | "Meal" tile, feeding events          |
| `vaccine.png`  | 128 × 128 | Vaccine list rows, next-booster card |
| `grooming.png` | 128 × 128 | Grooming bookings                    |
| `record.png`   | 128 × 128 | Health records                       |

---

## `icons/auth/` — Auth provider logos
Used on the auth landing screen buttons. If missing, falls back to Lucide glyphs.

| Filename      | Size      | Notes                                |
|---------------|-----------|--------------------------------------|
| `google.png`  | 64 × 64   | Official Google "G" mark             |
| `apple.png`   | 64 × 64   | Apple logo (white on transparent)    |

---

## `icons/onboarding/` — Question screen icons
Optional. Used on each onboarding question screen if you want richer iconography than Lucide.

Suggested filenames:
- `priorities/vaccines.png`, `priorities/meds.png`, `priorities/records.png`, etc.
- `time/morning.png`, `time/afternoon.png`, `time/evening.png`, `time/anytime.png`
- `referral/app_store.png`, `referral/friend.png`, etc.

---

## Where to source images

If you want consistent quality without making them yourself:
- **3D-rendered pet avatars**: https://www.flaticon.com (search "pet 3D"), https://undraw.co, https://blush.design
- **Onboarding illustrations**: https://undraw.co (configurable colors), https://storyset.com
- **Flat icons**: https://lucide.dev (already wired in code), https://heroicons.com, https://phosphoricons.com
- **Auth logos**: https://google.com/identity (official Google G), https://developer.apple.com/design/resources

Match the warm bone/clay palette: `#FAF7F0` (bone) backgrounds, `#B85C32` (clay) accents, `#14130F` (ink) strokes.

---

After adding files, hot-restart the app (not hot-reload — Flutter caches the asset manifest at startup).
