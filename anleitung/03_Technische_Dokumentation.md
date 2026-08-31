# Technische Dokumentation: Melde-Tool

**Stand:** 28.08.2026
**Gilt für:** die statische Webseite «Problem melden» samt Anbindung an Power Automate und den Power-Platform-KI-Hub

---

## Inhalt

1. [Zweck und Ablauf](#1-zweck-und-ablauf)
2. [Architektur](#2-architektur)
3. [Die Webseite](#3-die-webseite)
4. [Bildverarbeitung im Browser](#4-bildverarbeitung-im-browser)
5. [Flow A: Analyse](#5-flow-a-analyse)
6. [Flow B: Absenden](#6-flow-b-absenden)
7. [Der KI-Prompt](#7-der-ki-prompt)
8. [CORS und Aufrufe aus dem Browser](#8-cors-und-aufrufe-aus-dem-browser)
9. [Fallstricke, die Zeit kosten](#9-fallstricke-die-zeit-kosten)
10. [Lokale Entwicklung und Test](#10-lokale-entwicklung-und-test)
11. [Alle Kennungen auf einen Blick](#11-alle-kennungen-auf-einen-blick)

---

## 1. Zweck und Ablauf

Mitarbeitende am Campus Sursee melden Mängel und Schäden mit dem Handy statt per Telefon oder E-Mail.

1. Die meldende Person gibt einmalig ihre E-Mail-Adresse an; sie bleibt im Browser gespeichert.
2. Sie fotografiert das Problem, bis zu sechs Bilder.
3. Die Bilder werden im Browser verkleinert; das erste geht an **Flow A**, der es von der KI beschreiben und einer Abteilung zuordnen lässt.
4. Titel, Beschreibung und Abteilung erscheinen vorausgefüllt zur Kontrolle.
5. Beim Absenden schickt **Flow B** alles als E-Mail mit den Fotos im Anhang an `servicedesk@campus-sursee.ch`.

---

## 2. Architektur

Das ganze System ist **eine einzige HTML-Datei plus zwei Power-Automate-Flows**. Es gibt keinen eigenen Server, keine Datenbank und keine Ablage.

```
       Browser der meldenden Person
       (Handy oder PC, keine Anmeldung)
                    |
                    |  index.html, eine Datei
                    |
        +-----------+------------+
        |                        |
   POST fotos               POST ganze Meldung
        |                        |
        v                        v
 Flow A «Analyse»          Flow B «Absenden»
        |                        |
        v                        +--> Auswählen: fotos -> Anhänge
 AI Builder Prompt               |
 «Problem-Melder Analyse»        v
 Modell GPT-5 chat        E-Mail senden (V2)
        |                        |  Verbindung servicedesk@
        v                        v
 JSON {titel, beschreibung, servicedesk@campus-sursee.ch
       abteilung}
```

**Warum zwei Flows und nicht einer:** Die Analyse passiert zwischen Schritt 2 und 3, das Absenden am Ende. Wer den Fotoschritt überspringt, ruft Flow A gar nie auf. Ein einziger Flow müsste beide Fälle unterscheiden und würde die Analyse auch dann bezahlen, wenn niemand sie braucht.

**Warum überhaupt Flows:** Die meldenden Personen sollen sich nicht anmelden müssen. Ohne Anmeldung gibt es kein Token für Microsoft Graph, und die KI-Aktion des AI Builders lässt sich ohnehin nicht aus dem Browser aufrufen. Anonym erreichbare Flows sind der einzige Weg, der ohne Konto auskommt.

**Warum kein SharePoint:** Es gibt bewusst keine Ablage. Die E-Mail an den Servicedesk **ist** die Meldung. Siehe `05_Entscheide_und_Verlauf.md`, Abschnitt 4.

---

## 3. Die Webseite

Alles liegt in `frontend\index.html`, rund 1580 Zeilen: HTML, CSS und JavaScript in einer Datei. Keine Frameworks, kein Bauprozess, keine `.js`-Module.

**Von aussen geladen wird nur Zierrat:**

| Was | Woher | Wenn es fehlt |
|---|---|---|
| Schrift «Inter» | Google Fonts | Systemschrift, sonst alles gleich |
| Logo und Favicon | `www.campus-sursee.ch/wp-content/themes/campus-sursee/assets/images/Campus_Sursee_Hauptlogo_RGB.svg` | Bild fehlt, Seite voll benutzbar |

Beide Adressen stehen direkt im Quelltext, es wird nichts kopiert oder zwischengespeichert. Das war ausdrücklicher Wunsch.

### 3.1 Aufbau

Vier Abschnitte im HTML, von denen immer genau einer sichtbar ist:

| ID | Schritt | Überschrift |
|---|---|---|
| `screen1` | 1, «Kontakt» | «Wer meldet?» |
| `screen2` | 2, «Fotos» | «Foto aufnehmen» |
| `screen3` | 3, «Übersicht» | «Meldung prüfen» |
| `screenErfolg` | «Gesendet» | «Vielen Dank!» |

Der Wechsel läuft über `geheZu(nr)`. Die Funktion setzt die Klasse `sichtbar`, erzwingt mit `void el.offsetWidth` einen Reflow, damit die Einblend-Animation neu startet, und führt den Fortschrittsbalken sowie die Beschriftung «Schritt X von 3» nach.

### 3.2 Konfiguration

Ganz oben im `<script>` stehen alle veränderlichen Werte:

```js
var FLOW_A_URL   = "…/workflows/3d711734…/triggers/manual/paths/invoke?…&sig=…";
var FLOW_B_URL   = "…/workflows/97037b20…/triggers/manual/paths/invoke?…&sig=…";
var MAX_KANTE     = 1600;      // längste Bildkante nach dem Verkleinern
var JPEG_QUALITAET = 0.8;      // JPEG-Qualität beim Neukodieren
var TIMEOUT_MS    = 30000;     // Abbruch beider Aufrufe nach 30 Sekunden
var MAX_FOTOS     = 6;         // mehr Bilder werden abgeschnitten
var LS_KEY        = "problemMelder.email";
```

Die beiden Aufrufadressen enthalten eine Signatur und gehören nicht in Tickets, Mails oder Chats. Sie stehen im Quelltext jeder ausgelieferten Seite; das ist eine bewusst in Kauf genommene Schwäche, siehe `02_Betriebshandbuch_Support.md`, Abschnitt 6, Punkt 1.

Steht bei `FLOW_B_URL` noch ein Platzhalter mit `%%`, verweigert die Seite das Absenden mit einer eigenen Meldung, statt einen sinnlosen Aufruf zu machen.

### 3.3 Wichtige Funktionen

```js
emailLesen() / emailSchreiben(wert)   // localStorage, Schlüssel problemMelder.email
emailGueltig(wert)                    // einfache Formprüfung
abteilungLesen() / abteilungSetzen()  // liest und setzt die vier Radio-Felder
abteilungNormieren(wert)              // KI-Antwort auf die vier erlaubten Werte abbilden
jsonParsenWeich(text)                 // toleranter JSON-Leser, siehe unten
hatAnalyseFelder(objekt)              // hat die Antwort überhaupt Inhalt?
verkleinern(datei)                    // Canvas-Verkleinerung, liefert Base64
sendePlainText(url, nutzlast)         // POST mit Timeout, liefert den Antworttext
screen3Vorbereiten(analyse, hinweis)  // Formular füllen, Hinweis ein- oder ausblenden
```

**`jsonParsenWeich`** ist bewusst nachsichtig. Es nimmt reines JSON, ein Array mit einem Objekt darin und ein Objekt, das die Analyse unter `body`, `result`, `analyse`, `output` oder `data` verschachtelt oder als Zeichenkette eingebettet enthält. Grund: Die Antwortform der AI-Builder-Aktion hat sich beim Aufbau mehrfach geändert. Wenn nichts davon greift, gilt die Antwort als leer und die Seite arbeitet ohne Vorschläge weiter.

**`abteilungNormieren`** vergleicht ohne Rücksicht auf Gross- und Kleinschreibung gegen die vier erlaubten Werte. Alles andere – auch das häufige «Keine» – ergibt eine leere Vorauswahl. So kann die KI nie ein Auswahlfeld erzeugen, das es in der Oberfläche gar nicht gibt.

### 3.4 Fehlertoleranz

Der Ablauf ist so gebaut, dass eine gescheiterte Analyse **nie** den Meldeweg blockiert. Fehlgeschlagener Aufruf, Zeitüberschreitung, unlesbare Antwort, leere Felder: In jedem Fall landet die Person auf Schritt 3, sieht den Hinweis «Automatische Analyse nicht verfügbar – bitte manuell ausfüllen.» und kann von Hand ausfüllen. Der einzige Schritt, der wirklich fehlschlagen kann, ist das Absenden.

Beim Absenden gilt: `sendetGerade` sperrt den Knopf gegen Doppelklicks; bei einem Fehler wird er wieder freigegeben und das Formular bleibt vollständig ausgefüllt stehen.

### 3.5 Gestaltung

Rein weiss, keine Schlagschatten, vertikal zentrierte Karte statt Kopf- und Fusszeile. Die Farbtoken stehen als CSS-Variablen im `:root`: `--blau #003C64` als Akzent, `--rot #C22B33` nur für Fehler und den Proof-of-Concept-Hinweis, dazu drei Grautöne für Text und Linien.

Übrig gebliebene `box-shadow`-Regeln sind ausschliesslich Fokusringe für die Tastaturbedienung und die Umrandung des gewählten Abteilungsfeldes, keine Schlagschatten. Alle Animationen respektieren `prefers-reduced-motion`. Icons sind Inline-SVG; es wird nichts nachgeladen.

---

## 4. Bildverarbeitung im Browser

Die Fotos werden **vor** dem Versand auf dem Gerät verkleinert. Das spart Übertragungszeit im Mobilfunk und hält die Anhänge klein.

1. `FileReader` liest die Datei als Data-URL.
2. Ein `Image` lädt sie; Breite und Höhe werden ausgelesen.
3. `faktor = Math.min(1, 1600 / längste Kante)` – kleinere Bilder werden **nicht** vergrössert.
4. Ein `canvas` in der Zielgrösse, `drawImage`, dann `toDataURL("image/jpeg", 0.8)`.
5. Vom Ergebnis wird der Präfix `data:image/jpeg;base64,` abgeschnitten; übrig bleibt reines Base64.

Die Bilder heissen immer `foto1.jpg`, `foto2.jpg` und so weiter. Nach dem Entfernen eines Bildes wird neu durchnummeriert, es gibt also keine Lücken. Ein Bild, das sich nicht lesen oder dekodieren lässt, wird gezählt und übersprungen; der Ablauf bricht nicht ab.

Zu beachten: HEIC-Bilder von iPhones wandelt Safari beim Zugriff über ein `<input type="file">` selbst in JPEG um. Ein Gerät, das das nicht tut, landet bei der Meldung «Die Fotos konnten nicht verarbeitet werden.»

---

## 5. Flow A: Analyse

**Name:** `Problem-Melder - Analyse`
**ID:** `9d38c54c-f92b-4ac1-8f99-85f8db8b7f10`
**Aufbau:** Trigger → Einen Prompt ausführen → Antwort

### 5.1 Trigger

«Beim Empfang einer HTTP-Anforderung», **Wer kann den Flow auslösen? = Jeder**.

Schema des Anforderungstexts:

```json
{"type":"object","properties":{
  "email":{"type":"string"},
  "fotos":{"type":"array","items":{"type":"object","properties":{
    "name":{"type":"string"},
    "contentBase64":{"type":"string"}}}}}}
```

### 5.2 Aktion «Einen Prompt ausführen»

AI-Builder-Aktion, Verbindung **Microsoft Dataverse** (Konto `powerplatform@campus-sursee.ch`).

| Feld | Wert |
|---|---|
| Eingabeaufforderung | `Problem-Melder Analyse` |
| Foto | siehe unten |
| AdditionalContext | leer |

Das Feld **Foto** erwartet ein Power-Platform-Dateiobjekt, nicht eine Zeichenkette:

```
json(concat('{"$content-type":"image/jpeg","$content":"', triggerBody()?['fotos']?[0]?['contentBase64'], '"}'))
```

> **Das ist die wichtigste Zeile des ganzen Flows.** Weder ein nackter Base64-String noch eine `data:image/jpeg;base64,…`-URI funktionieren. Beide führen zu `InvalidPredictionInput` mit dem irreführenden Text «Image url cannot be accessed», weil die Aktion den Wert als Bildadresse zu öffnen versucht. Diese Zeile war der teuerste Fehlversuch beim Aufbau, siehe Abschnitt 9.

Verarbeitet wird ausschliesslich `fotos[0]`, also das erste Bild.

### 5.3 Aktion «Antwort»

| Feld | Wert |
|---|---|
| Statuscode | 200 |
| Überschriften | `Access-Control-Allow-Origin: *`, `Content-Type: application/json` |
| Text | die Ausgabe **Text** der Prompt-Aktion, unverändert |

Der Body ist also genau das JSON, das das Modell erzeugt hat. Es wird im Flow **nicht** geprüft oder umgeformt; das übernimmt `jsonParsenWeich` im Browser.

**Erwartete Antwort an die Seite:**

```json
{ "titel": "Drucker mit Papierstau",
  "beschreibung": "Auf dem Foto ist ein Druckerdisplay zu sehen, das den Fehler 'Paper Jam' anzeigt. Der Drucker befindet sich im Buero B2.14 und kann aktuell nicht genutzt werden. Es liegt ein Papierstau vor, der behoben werden muss.",
  "abteilung": "ICT-Servicedesk" }
```

Bei einem Bild ohne erkennbares Problem kommen dieselben drei Felder leer zurück. Das ist kein Fehler, sondern gewolltes Verhalten des Prompts.

---

## 6. Flow B: Absenden

**Name:** `Problem-Melder - Absenden`
**ID:** `31581404-1a5a-46da-a9ad-a7f47e5209f9`
**Aufbau:** Trigger → Auswählen → E-Mail senden (V2) → Antwort

### 6.1 Trigger

«Beim Empfang einer HTTP-Anforderung», **Wer kann den Flow auslösen? = Jeder**.

```json
{"type":"object","properties":{
  "email":{"type":"string"},
  "titel":{"type":"string"},
  "beschreibung":{"type":"string"},
  "abteilung":{"type":"string"},
  "fotos":{"type":"array","items":{"type":"object","properties":{
    "name":{"type":"string"},
    "contentBase64":{"type":"string"}}}}}}
```

> **Achtung beim Testen:** Wird der Flow mit `Content-Type: text/plain` aufgerufen, weist der Trigger die Anfrage mit `TriggerInputSchemaMismatch … Expected Object but got String` ab. Er will echtes JSON. Der ursprüngliche Plan, mit `text/plain` den CORS-Preflight zu umgehen, ist genau daran gescheitert – und war unnötig, siehe Abschnitt 8.

### 6.2 Aktion «Auswählen»

Wandelt das Foto-Array in das Format, das der Outlook-Konnektor für Anhänge erwartet.

| Feld | Wert |
|---|---|
| Von | `triggerBody()?['fotos']` |
| Zuordnung `Name` | `item()?['name']` |
| Zuordnung `ContentBytes` | `item()?['contentBase64']` |

Ist `fotos` leer, ist auch das Ergebnis leer und die E-Mail geht ohne Anhang. Das ist der Fall «Überspringen und manuell beschreiben».

### 6.3 Aktion «E-Mail senden (V2)»

Office-365-Outlook-Konnektor, Verbindung **`servicedesk@campus-sursee.ch`**.

| Feld | Wert |
|---|---|
| An | `servicedesk@campus-sursee.ch` |
| Betreff | `concat('Problemmeldung: ', coalesce(triggerBody()?['titel'],'ohne Titel'), ' - ', coalesce(triggerBody()?['abteilung'],'keine Abteilung'))` |
| Text | `concat('<p><strong>Titel:</strong> ', coalesce(triggerBody()?['titel'],''), '<br><strong>Abteilung:</strong> ', coalesce(triggerBody()?['abteilung'],''), '<br><strong>Gemeldet von:</strong> ', coalesce(triggerBody()?['email'],''), '</p><p><strong>Beschreibung:</strong><br>', coalesce(triggerBody()?['beschreibung'],''), '</p>')` |
| Anlagen (erweiterte Optionen) | `body('Auswählen')` |

Die `coalesce`-Aufrufe sind Absicht: Der Flow soll auch dann eine brauchbare Mail erzeugen, wenn ein Feld fehlt, statt mit einem Ausdrucksfehler abzubrechen.

> **Warum die Verbindung auf `servicedesk@` läuft und nicht auf `powerplatform@`:** Das Konto `powerplatform@campus-sursee.ch` hat kein nutzbares Exchange-Postfach. Mit ihm erstellte Outlook-Verbindungen wurden vom Designer dauerhaft als «Ungültige Verbindung» geführt, und der Flow liess sich nicht speichern. Die Meldungen kommen deshalb vom Servicedesk-Postfach an sich selbst. Die meldende Person steht im Text unter «Gemeldet von», nicht im Absenderfeld.

### 6.4 Aktion «Antwort»

| Feld | Wert |
|---|---|
| Statuscode | 200 |
| Überschriften | `Access-Control-Allow-Origin: *`, `Content-Type: application/json` |
| Text | `{"ok":true}` |

Die Seite wertet den Inhalt nicht aus. Sie zeigt die Bestätigung, sobald der Aufruf mit einem Erfolgsstatus zurückkommt.

---

## 7. Der KI-Prompt

**Name:** `Problem-Melder Analyse`, im Power-Platform-KI-Hub unter **Eingabeaufforderungen**
**Modell:** GPT-5 chat (Stufe «Standard»)
**Eingabe:** eine Dokumenteingabe mit der Bezeichnung `Foto`
**Ausgabeformat:** JSON

### 7.1 Anweisungstext

> Du analysierst ein Foto, das ein Problem oder einen Schaden auf dem Campus Sursee (Baubildungszentrum) zeigt. Beschreibe sachlich, was zu sehen ist, und ordne die zustaendige Abteilung zu. Abteilungs-Zuordnung: Umgebungsdienst = Aussenbereich, Gruenflaechen, Wege, Parkplaetze, Abfall, Signaletik aussen. Technischer Dienst = Gebaeude, Sanitaer, Elektrik, Heizung, Lueftung, Tueren, Fenster, Mobiliar, Reparaturen innen. ICT-Servicedesk = Computer, Bildschirme, Drucker, Netzwerk, WLAN, Telefonie, AV-Technik. Seminarsupport = Seminarraeume, Bestuhlung, Tagungstechnik, Raumausstattung fuer Kurse. Antworte auf Deutsch (Schweiz, kein scharfes S). **[Foto]** Gib das Ergebnis als JSON mit genau diesen Feldern zurueck: {"titel": "kurzer praegnanter Titel des Problems, max. 60 Zeichen", "beschreibung": "2 bis 4 Saetze: was ist zu sehen und was ist das Problem", "abteilung": "genau einer dieser vier Werte: Umgebungsdienst, Technischer Dienst, ICT-Servicedesk, Seminarsupport"}

Der Text ist bewusst **ohne Umlaute** geschrieben, um Kodierungsproblemen beim Übertragen in den Editor aus dem Weg zu gehen. Die Antworten des Modells enthalten sehr wohl Umlaute.

### 7.2 Zur Modellwahl

Die Auswahl im Prompt-Editor bietet mehrere Stufen:

| Modell | Stufe | Bemerkung |
|---|---|---|
| GPT-4.1 mini | Basic | anfangs eingesetzt, rund 0.3 Guthaben pro Lauf, kurze Beschreibungen |
| GPT-4.1 | Standard | |
| **GPT-5 chat** | Standard | **aktuell eingestellt**, rund 3 Guthaben, rund 4 Sekunden |
| GPT-5 reasoning | Premium | deutlich teurer und langsamer, für diese Aufgabe unnötig |
| Claude Sonnet 4.6 | experimentell, kostenpflichtig | nicht geprüft |

> **Eine Microsoft-365-Copilot-Lizenz ändert daran nichts.** Der AI Builder hat seine eigene Modellliste und rechnet über Copilot-Guthaben der Umgebung ab, unabhängig davon, welche Copilot-Lizenzen Personen besitzen.

Der Wechsel des Modells geschieht **nur im Prompt**; am Flow ist nichts zu ändern, weil er den Prompt referenziert. Zum Vorgehen siehe `02_Betriebshandbuch_Support.md`, Abschnitt 5.2 – dort steht auch die Warnung, dass ein Speichern still verloren gehen kann.

### 7.3 Beobachtetes Verhalten

- Bilder mit lesbarem Text (Displaymeldung, Raumnummer, Typenschild) ergeben deutlich bessere Titel und Beschreibungen.
- Bilder ohne erkennbares Problem ergeben leere Felder statt erfundener Inhalte. Das ist gewollt und wird von der Seite abgefangen.
- Die Abteilungszuordnung war in den Tests zuverlässig, sobald das Problem überhaupt erkannt wurde.
- GPT-5 chat liefert längere, brauchbarere Beschreibungen als GPT-4.1 mini und war in den Messungen sogar schneller (rund 4 statt rund 8 Sekunden).

---

## 8. CORS und Aufrufe aus dem Browser

Die Seite ruft die Flows über Domänengrenzen hinweg auf. Der Browser schickt deshalb zuerst eine Preflight-Anfrage mit `OPTIONS`.

**Erfreulicher Befund:** Das Power-Platform-Gateway beantwortet diesen Preflight **von sich aus** – ohne dass im Flow etwas dafür gebaut werden müsste:

```
HTTP/1.1 204
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET,POST,PUT,DELETE,PATCH,HEAD
Access-Control-Allow-Headers: content-type
Access-Control-Max-Age: 7200
```

Deshalb sendet die Seite ganz normal `Content-Type: application/json`.

**Der ursprüngliche Plan war ein anderer** und ist es wert, festgehalten zu werden: Vorgesehen war, mit `Content-Type: text/plain` zu senden, weil das als «einfache Anfrage» gilt und gar keinen Preflight auslöst. Das hätte funktioniert, wenn der Trigger den Text angenommen hätte – tut er aber nicht. Er verlangt echtes JSON und antwortet sonst mit `TriggerInputSchemaMismatch`. Der Umweg war also unnötig und wäre auch gescheitert. Die `Access-Control-Allow-Origin: *`-Kopfzeile in den Antwort-Aktionen beider Flows bleibt trotzdem stehen; sie schadet nicht und deckt die eigentliche Antwort ab.

---

## 9. Fallstricke, die Zeit kosten

**Die Bildübergabe an den AI Builder.** Das Feld «Foto» braucht ein Dateiobjekt in der Form `{"$content-type":…,"$content":…}`. Base64 pur und `data:`-URI scheitern beide mit «Image url cannot be accessed». Der Fehlertext führt in die Irre, weil er nach einem Netzwerkproblem klingt. Siehe Abschnitt 5.2.

**Der Trigger will JSON.** `text/plain` ergibt `TriggerInputSchemaMismatch … Expected Object but got String`. Siehe Abschnitt 8.

**Unsichtbare Browser-Dialoge im Power-Automate-Designer.** Ein ungültiger Ausdruck erzeugt einen nativen Dialog («Dieser Ausdruck ist ungültig»). Wer den Designer über eine Automation oder aus einem Hintergrund-Tab bedient, sieht ihn nicht – die Seite wirkt eingefroren und reagiert minutenlang auf gar nichts. Wenn der Designer plötzlich hängt: nach einem offenen Dialogfenster suchen.

**Der neue Designer speichert nicht immer.** Beim Aufbau von Flow B verweigerte der neue Designer das Speichern wiederholt mit dem Hinweis auf eine unterbrochene Verbindung, obwohl die Verbindungsübersicht alles als verbunden auswies. Der klassische Designer (`?v3=false` an die Flow-Adresse hängen) speicherte anstandslos. **Empfehlung: für Änderungen an diesen Flows immer den klassischen Designer verwenden.**

**«Flow wiederherstellen» ist zuverlässig.** Der Browser merkt sich eine ungespeicherte Fassung. Nach einem Neuladen erscheint oben rechts der Knopf «Flow wiederherstellen» und holt den kompletten Zwischenstand zurück. Das hat beim Aufbau mehrfach eine halbe Stunde Arbeit gerettet. Umgekehrt gilt: Ein Entwurf, der **nie** gespeichert wurde und dessen Browser-Kopie verloren geht, ist unwiederbringlich weg.

**Ein Speichern kann still verloren gehen.** Beim Wechsel des KI-Modells auf GPT-5 chat schloss sich der Dialog nach dem Klick auf «Speichern» ohne Fehlermeldung, das Modell stand danach aber wieder auf dem alten Wert. Erst der zweite Anlauf mit sichtbarem Bestätigungsbanner griff. **Nach jeder Änderung nachkontrollieren**, am besten mit einem echten Aufruf.

**OAuth-Fenster öffnen nur im Vordergrund.** Verlangt eine Verbindung eine Anmeldung, öffnet Chrome das Fenster nur, wenn der Tab im Vordergrund liegt und der Klick von einer Person kommt. Aus dem Hintergrund heraus hängt die Anzeige endlos bei «Anmeldung wird ausgeführt…», ohne dass je ein Fenster erscheint.

**Das Konto powerplatform hat kein Postfach.** Outlook-Verbindungen mit diesem Konto werden vom Designer als ungültig geführt. Für den Versand die Verbindung `servicedesk@campus-sursee.ch` verwenden. Siehe Abschnitt 6.3.

**Ausdrücke nach dem Einfügen kontrollieren.** Der Ausdruckseditor übernimmt Eingaben nicht immer. Nach dem Setzen eines Ausdrucks über **… → Vorschaucode** die Codeansicht öffnen und den Wert im Klartext gegenlesen. Das ist der einzige verlässliche Beleg.

---

## 10. Lokale Entwicklung und Test

Auf dem Arbeitsplatz ist Node nicht installiert; Python ist vorhanden, dessen `http.server` liess sich aber nicht zuverlässig starten. Der beiliegende PowerShell-Server ist der Weg der Wahl.

```
powershell -ExecutionPolicy Bypass -File code\serve.ps1
```

Danach `http://localhost:8123/` oder `http://127.0.0.1:8123/` öffnen.

> **Port 8123 wird auch von der Menüwahl benutzt.** Läuft dort bereits ein `serve.ps1`, meldet der Browser «Bad Request - Invalid Hostname» oder die Seite bleibt aus. Dann den anderen Server beenden oder im Skript beide Vorkommen von `8123` auf eine freie Nummer ändern, etwa 8124.

> **`file:///`-Aufrufe funktionieren nicht.** Der eingebaute Browser lehnt sie ab, und über `file://` verhielte sich auch der `localStorage` anders. Immer über den kleinen Server gehen.

**Es gibt keinen Mock-Modus.** Anders als bei der Menüwahl spricht die Seite auch lokal mit den echten Flows. Ein Testdurchlauf erzeugt also eine echte E-Mail an den Servicedesk und verbraucht Copilot-Guthaben. Testmeldungen deshalb mit «TEST» im Titel kennzeichnen.

Wer nur das Backend prüfen will, ruft die Flows direkt mit PowerShell auf; die fertigen Befehle stehen in `02_Betriebshandbuch_Support.md`, Abschnitt 4.3.

---

## 11. Alle Kennungen auf einen Blick

| Was | Wert |
|---|---|
| Webseite | noch nicht veröffentlicht, vorgesehen bei Netlify |
| Quelldatei | `frontend\index.html`, rund 1580 Zeilen |
| Arbeitsverzeichnis beim Bau | `C:\Claude\problem-melder\` |
| Power-Automate-Umgebung | `Default-2553fb74-5dcc-4072-8bb5-399d18f72af9` («CAMPUS SURSEE (default)») |
| Mandanten-ID | `2553fb74-5dcc-4072-8bb5-399d18f72af9` |
| Flow A «Problem-Melder - Analyse» | `9d38c54c-f92b-4ac1-8f99-85f8db8b7f10` |
| Flow B «Problem-Melder - Absenden» | `31581404-1a5a-46da-a9ad-a7f47e5209f9` |
| KI-Prompt | `Problem-Melder Analyse`, Modell GPT-5 chat |
| Betriebskonto der Flows | `powerplatform@campus-sursee.ch` |
| Outlook-Verbindung | `servicedesk@campus-sursee.ch` |
| Empfänger der Meldungen | `servicedesk@campus-sursee.ch` |
| Logo und Favicon | `https://www.campus-sursee.ch/wp-content/themes/campus-sursee/assets/images/Campus_Sursee_Hauptlogo_RGB.svg` |
| Schrift | Inter von Google Fonts |
| Lokaler Testserver | `http://localhost:8123/` |

Die Aufrufadressen der beiden Flows samt Signatur stehen bewusst nicht hier, sondern im Quelltext von `frontend\index.html`.
