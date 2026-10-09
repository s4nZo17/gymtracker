# Dati finti per l'emulatore

Servono a verificare l'app a mano sull'emulatore `core36`. L'emulatore parte
con `-no-snapshot-save`, quindi tutto quello che si scrive dentro sparisce allo
spegnimento: questi file sono la copia da ripushare ogni volta.

Coprono i casi del contesto giornata:

- **Push Day / Pull Day / Leg Day / Full Body express** con serie previste.
- La **Panca piana** sta sia in Push Day sia in Full Body express, e nel Full
  Body arriva dopo lo squat: pesi più bassi. È il caso che il confronto
  contestuale deve distinguere.
- Le **tre sessioni più vecchie non hanno contesto** (storico "vecchio", come
  quello vero prima della modifica): servono a vedere il fallback.
- Una sessione è **fuori ordine di data** (come quelle importate da testo).

## Come ricaricarli

```sh
~/Android/Sdk/emulator/emulator -avd core36 -no-snapshot-save -no-boot-anim &
# aspetta il boot, poi:
cd <repo> && PATH=~/flutter/bin:$PATH flutter install -d emulator-5554
adb -s emulator-5554 shell am start -n com.example.gymtracker2/.MainActivity
# il primo avvio crea la cartella; poi:
adb -s emulator-5554 shell am force-stop com.example.gymtracker2
for f in storico templates esercizi preferences; do
  adb -s emulator-5554 push design/emulator-seed/$f.json \
    /sdcard/Android/data/com.example.gymtracker2/files/gymTracker/$f.json
done
adb -s emulator-5554 shell am start -n com.example.gymtracker2/.MainActivity
```

L'orologio dell'emulatore può essere indietro: `adb -s emulator-5554 root` e
`adb -s emulator-5554 shell "date $(date +%m%d%H%M%Y.%S)"`.

Attenzione: usare sempre `-s emulator-5554`. Il telefono vero può essere
collegato allo stesso `adb` e non va toccato.
