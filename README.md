# GymTracker

App Flutter per tracciare allenamenti in modo rapido, con storico, libreria esercizi, progressi e backup automatico su file.

## Funzionalita principali

- Allenamento del giorno con aggiunta esercizi e serie
- Libreria esercizi modificabile (aggiunta, modifica, ricerca)
- Storico allenamenti con dettaglio per data
- Grafici progressi (peso massimo e volume)
- Temi chiaro/scuro e colore principale personalizzabile
- Supporto multilingua (Italiano/English)
- Esportazione dati in JSON e CSV

## Stack tecnico

- Flutter + Dart
- State management: `provider`
- Grafici: `fl_chart`
- Persistenza file: `path_provider` + JSON/CSV

## Avvio rapido (sviluppo)

1. Installa Flutter SDK e Android Studio (con Android SDK).
2. Verifica ambiente:

```bash
flutter doctor
```

3. Scarica dipendenze:

```bash
flutter pub get
```

4. Avvia in debug:

```bash
flutter run
```

## Build APK

Build debug:

```bash
flutter build apk --debug
```

Build release:

```bash
flutter build apk --release
```

Output APK:

`build/app/outputs/flutter-apk/`

## Dati salvati sul dispositivo

I dati vengono salvati in una cartella `gymTracker` interna all'app.

Su Android, tipicamente il path e simile a:

`/storage/emulated/0/Android/data/com.example.gymtracker/files/gymTracker`

File generati:

- `preferences.json` (impostazioni app)
- `storico.json` (storico completo allenamenti)
- `storico.csv` (storico in formato tabellare)
- `esercizi.json` (libreria esercizi)
- `esercizi.csv` (libreria in formato tabellare)

## Struttura progetto (principale)

```text
lib/
  main.dart
  models/
  services/
  screens/
  widgets/
  l10n/
```

## Troubleshooting veloce

- `flutter: command not found`
  - Aggiungi `flutter/bin` al PATH e riapri il terminale.
- Errori SDK Android
  - Apri Android Studio > SDK Manager e installa i componenti mancanti.
- Build fallisce dopo cambio dipendenze
  - Esegui:

```bash
flutter clean
flutter pub get
```
