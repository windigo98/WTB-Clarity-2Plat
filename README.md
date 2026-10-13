# WTB Clarity 2plat

A WingsCrew habit and routine game. Check in on habits, keep streaks, earn XP, and climb levels. Run a morning or evening routine, sit a focus timer, and spend Clarity (streak points) building a sandcastle. Memory games drop pieces of original fantasy pictures. Finished pictures hang in a Memory Tower that also holds photos you add yourself.

The name nods to old MMO trade chat ("want to buy Clarity for 2 platinum"). The gamer flavor is our own.

WTB Clarity 2plat is an independent WingsCrew app and is not affiliated with or endorsed by EverQuest or Daybreak Game Company.

Phase 1 stores everything on this device. There is no account and no backend. Crew invites, shared goals, and sign-in are left as on-device hooks for a later phase. Real-money shop items are reserved SKUs only; nothing is charged.

## Run it

Install [Flutter](https://docs.flutter.dev/get-started/install) (this project was built with the stable channel, Dart 3.13). Then:

```bash
flutter pub get
flutter run -d chrome
```

Web server, if you would rather not launch a browser yourself:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 47221
```

Open `http://127.0.0.1:47221`.

Production web build:

```bash
flutter build web --release
```

Preview hosted under `/wtb-clarity-preview/` (for example wingscrew.com/wtb-clarity-preview/):

```bash
flutter build web --release --base-href /wtb-clarity-preview/
```

The output is in `build/web`. `web/index.html` includes `<meta name="robots" content="noindex, nofollow">`. The same project includes `android/` and `ios/` so a later store build can start from this codebase. Camera and photo-library usage strings are already in the mobile manifests. This phase is verified on the web.

## Tests

```bash
flutter test
```

## What you can do

- **Today.** Add habits, schedule them daily or on chosen weekdays, and check in once per day.
- **Streaks, XP, and levels.** Check-ins, focus bouts, and game clears feed one level bar. A streak freeze in the shop protects a missed day.
- **Routines.** Order morning and evening steps, then run them as a checklist. A habit step checks that habit in.
- **Focus timer.** Start, pause, and reset a work bout (default 25 minutes), then take a short break. Finished bouts earn XP. The screen can open a one-minute Tide Breath before or after.
- **Sandcastle.** Spend Clarity piece by piece. When it is finished, take a selfie with the device camera or upload a photo. The app composites you with the castle, saves it on the device, and can download it. A wave then washes the castle away so you can build another. Past selfies stay in the gallery.
- **Memory Tower.** Add a photo and an optional caption. Each one is a floor. Tap a floor to open it. The tower is permanent. Completed picture albums appear as display floors.
- **Arcade.** Pairwell, Beacon Relay, Rune Lattice, Twice Lit, Wordwell, Digit Drift, Oddling, Inkwise, Waymark, a daily riddle, and Tide Breath. Levels, star ratings, and a level map. The daily riddle counts toward your streak. Wins earn XP and a picture piece.
- **Lives and boosters.** Arcade games spend a life on a failed attempt. Lives refill on a timer. Peek, extra time, hint, and shuffle are bought with Clarity.
- **Albums.** Six original pictures, one for each rarity: Common, Uncommon, Rare, Epic, Legendary, and Mythic. Duplicates become Clarity.
- **Shop.** Free defaults and premium avatars, themes, card backs, and play mats. A purchase gateway keeps real-money SKUs for later and does not take payment.
- **Settings.** Name, a stored reminder time, data export, the about text, and the copyright notice.

## License

This project is proprietary and All Rights Reserved. The source is viewable but may not be copied, modified, or reused without written permission. See `LICENSE`. Contact: dovewingsbusiness@gmail.com.
