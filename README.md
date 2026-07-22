# Isaac Codex

An unofficial companion app for **The Binding of Isaac: Repentance**. Browse the full
item database offline, search by name or effect, and keep a list of your favourite seeds.
Built with Flutter.

> Unofficial fan project. Not affiliated with, endorsed by, or sponsored by Nicalis, Inc.
> or Edmund McMillen.

## Features

- **Search** - find items, trinkets, cards and consumables by name or effect text
- **Categories** - browse everything grouped (Rebirth / Afterbirth / Afterbirth+ / Repentance
  items, trinkets, cards, consumables)
- **Item detail** - quality, pickup method, in-game ID and the full effect description
- **Seed tracker** - save your own seeds locally, plus a set of curated preset seeds to try
- Dark, Isaac-flavoured Material 3 theme, fully offline (all data is bundled)

## Data & attribution

Item data (1000+ entries) is sourced from [Platinum God](https://platinumgod.co.uk/repentance),
the community item reference for The Binding of Isaac. All item names, descriptions and game
content belong to their respective owners. Big thanks to the Platinum God contributors.

The `scraper/` folder contains the Python script used to build `assets/data/items.json`.

> Note: the app interface is currently in Turkish. Item text is in English (from the source).

## Tech

- Flutter (Material 3, dark theme)
- `shared_preferences` for saved seeds
- No backend, no tracking, works fully offline

## Run

```bash
flutter pub get
flutter run
```

## Disclaimer

The Binding of Isaac and all related names, artwork and content are trademarks and copyright
of Nicalis, Inc. and Edmund McMillen. This is a non-commercial, fan-made reference tool and is
not affiliated with the official product. Item data is provided by Platinum God; if you are a
rights holder and would like content removed, please open an issue.

## License

The application **source code** is released under the [MIT License](LICENSE). The MIT license
covers the code only, not the bundled game data, which remains the property of its respective
owners.
