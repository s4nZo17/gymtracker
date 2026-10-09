# Guida operativa — revisione 2 del redesign minimal

Stesura 2 (definitiva). Rispetto alla prima ho preso le decisioni lasciate
aperte e aggiunto quello che serve perché le richieste funzionino bene
insieme. Le aggiunte mie sono segnate con **[+]**.

---

## 1. Via i cerchi

**Richiesta:** i cerchi non piacciono.

**Decisione:** "cerchi" può voler dire i pallini dei colori o le forme a
pillola (FAB, chip, bottoni). Le tolgo tutte: ogni forma tonda diventa un
rettangolo con angoli a 10 px, lo stesso raggio dei campi di testo.

| Elemento | Prima | Dopo |
|---|---|---|
| FAB "+ Esercizio", "+ Nuovo" | pillola | rettangolo arrotondato |
| Bottone in alto ("Finisci", "+ Nuovo") | pillola | rettangolo arrotondato |
| Chip categorie, tipo serie, preset recupero, serie previste | pillola | rettangolo arrotondato |
| Muscoli nell'editor esercizio | pillola | rettangolo arrotondato |
| Colore principale (Impostazioni e setup) | cerchi con anello | quadrati arrotondati con bordo di selezione |
| Pallini della mappa corpo (legenda ed elenco) | cerchi | quadratini |

La costante `kRadiusPill` sparisce dal codice: così non tornano per sbaglio.

## 2. Peso e reps senza stepper grandi

**Richiesta:** il ±2.5 sul peso serve a poco: si sale spesso di 1 e molte
macchine sono in libbre. Toglierlo, o renderlo piccolo e nascosto. Lo stesso
per le reps.

**Decisione:**
- I quattro bottoni quadrati spariscono.
- **[+]** Peso e reps stanno affiancati su una sola riga, con due numeri
  grandi. Lo sheet si accorcia e "Salva serie" resta visibile anche con la
  tastiera aperta.
- Ai lati di ogni numero ci sono un "−" e un "+" piccoli, solo icona e in
  grigio. Passo 1 per il peso (vale sia per i kg sia per le libbre) e 1 per
  le reps.
- **[+]** Toccando un numero il testo viene selezionato tutto: si scrive il
  valore nuovo senza prima cancellare. Senza gli stepper grandi la tastiera
  diventa il modo principale, quindi deve essere rapida.
- Libbre: i dati restano numeri come li scrivi. La conversione kg/lb è fuori
  da questo giro (vedi §7).

## 3. Tasto "Finisci allenamento"

**Richiesta:** manca un tasto per finire l'allenamento.

**Decisione:**
- "Nuovo giorno" si chiama **"Finisci"** (in alto, sempre visibile).
- **[+]** In fondo alla lista degli esercizi c'è anche un bottone pieno
  **"Finisci allenamento"**: è il punto in cui arrivi naturalmente a fine
  sessione.
- Il flusso:
  1. **Con almeno una serie** → valutazione 1–5 (§4). "Salta" salva senza
     voto; un tocco fuori annulla tutto.
  2. **[+] Senza nessuna serie** → "Non hai registrato serie: l'allenamento
     non verrà salvato" (Finisci / Annulla). Un allenamento vuoto non finisce
     più nello Storico come riga da 0 serie.
  3. Si apre una giornata nuova (Oggi vuota, con i giorni preimpostati
     pronti).
  4. **[+]** Snackbar "Allenamento salvato · Annulla": se hai toccato per
     sbaglio, Annulla riapre la sessione com'era.
- Anche l'avviso "Questo allenamento è di un altro giorno · Inizia oggi" usa
  questo flusso.

## 4. Valutazione da 1 a 5 con le faccine

**Richiesta:** da 1–10 a 1–5, con un indicatore da scorrere e una faccina che
cambia.

**Decisione:**

| Voto | Etichetta | Faccina |
|---|---|---|
| 1 | Malissimo | molto triste |
| 2 | Male | triste |
| 3 | Medio | neutra |
| 4 | Bene | contenta |
| 5 | Benissimo | molto contenta |

- Dialog "Com'è andata?": faccina grande e etichetta, sotto uno slider a 5
  scatti. Si parte da 3 (Medio). Ogni scatto dà un piccolo feedback tattile.
- **[+]** Anche toccare la faccina in sé fa avanzare il voto: con una mano si
  fa prima che spostando lo slider.
- Dove si vede il voto:
  - Storico: solo la faccina.
  - Oggi e sessione aperta: faccina + etichetta, toccabili per cambiarle.
- **[+] Dati:** il voto viene salvato in un campo nuovo, `mood` (1–5). I voti
  vecchi 1–10 (`rating`) si convertono alla lettura (1–2→1, 3–4→2, 5–6→3,
  7–8→4, 9–10→5), quindi lo storico e i backup vecchi restano validi.

## 5. Giorno preimpostato con un allenamento in corso

**Richiesta:** non aggiungere in coda. Chiudere l'allenamento in corso
chiedendo se salvarlo, non salvarlo o annullare e continuare; poi creare in
automatico un giorno nuovo con gli esercizi del giorno preimpostato.

**Decisione:** dipende da cosa c'è nella sessione in corso.

| Sessione in corso | Cosa succede toccando "Pull Day" |
|---|---|
| vuota | carica subito Pull Day (come oggi) |
| **[+]** esercizi ma nessuna serie | "Sostituire gli esercizi di oggi con Pull Day?" → *Sostituisci* / *Annulla*. Non c'è niente da salvare: chiedere "salvare?" confonderebbe |
| almeno una serie | "Hai un allenamento in corso" → **Salva e inizia** (passa dalla valutazione, §4) / **Non salvare** (in rosso) / **Continua** (annulla) |

Dopo Salva o Non salvare: nuova giornata di oggi, con Pull Day applicato e il
contesto del giorno impostato. Vale per tutti i punti da cui si carica un
giorno: la lista di Oggi vuota (lì la sessione è vuota, quindi niente
domanda) e "Carica un giorno preimpostato" in fondo alla lista.

## 6. Test e rifinitura

1. `flutter analyze`, test esistenti e **[+]** test nuovi:
   - conversione dei voti vecchi;
   - un allenamento finito senza serie non resta nello Storico;
   - "Annulla" dopo Finisci riapre la sessione;
   - il cambio giorno con "Salva" / "Non salvare".
2. Emulatore: tutti i flussi sopra, in tema scuro e chiaro.
3. Lista di errori e migliorie trovati, corretti, poi ricontrollati.
4. Screenshot finali.

## 7. Fuori da questo giro (proposte)

- **Unità kg/lb per esercizio:** ogni macchina ricorderebbe la sua unità, con
  la conversione solo nei grafici. Tocca il formato dei dati, quindi va
  deciso a parte.

---

## 8. Esito (9 ottobre 2026)

Tutto il piano qui sopra è implementato. `flutter analyze` è pulito e i
test passano: 32 in tutto, di cui 11 nuovi in `test/finish_workout_test.dart`
(voti vecchi, Finisci, Annulla, cambio giorno con Salva / Non salvare,
giornata vuota). Ogni flusso è stato provato sull'emulatore.

**Errori e migliorie trovati durante i test e corretti:**

1. Il FAB "+ Esercizio" restava nascosto se scorrevi in giù quando la lista
   era corta e non scorreva più: ora si nasconde solo se la pagina scorre
   davvero, e ricompare quando cambia la sessione.
2. Dopo Finisci o un cambio di giorno Oggi restava in fondo alla lista
   vecchia: ora riparte dall'alto.
3. Lo Storico mostrava l'allenamento in corso anche con 0 serie ("Pull Day ·
   0 serie · In corso"): ora ci entra solo quando ha almeno una serie.
4. A parità di data, quello in corso finiva sotto quello salvato: ora va per
   primo.
5. Lo slider del voto aveva ancora il cursore tondo: ora è una barretta, come
   il resto dell'app.
6. Gli scatti dello slider non cadevano sotto le cinque faccine: allineati.
7. In Impostazioni il backup diceva ancora "a ogni Nuovo giorno": ora dice
   "ogni volta che finisci un allenamento".

Screenshot in `img-minimal/r2-*.png`.
