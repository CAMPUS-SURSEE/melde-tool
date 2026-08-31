# Einrichtung und Veröffentlichung

**Stand:** 28.08.2026

Dieses Dokument beschreibt, wie das Melde-Tool aufgeschaltet wird und wie eine Änderung live geht. Wer nur eine laufende Installation betreut, findet die häufigen Fälle in `02_Betriebshandbuch_Support.md`.

---

## Inhalt

1. [Stand der Bausteine](#1-stand-der-bausteine)
2. [Die Webseite aufschalten](#2-die-webseite-aufschalten)
3. [Eine Änderung veröffentlichen](#3-eine-änderung-veröffentlichen)
4. [Am Backend etwas ändern](#4-am-backend-etwas-ändern)
5. [Vor dem Dauerbetrieb zu entscheiden](#5-vor-dem-dauerbetrieb-zu-entscheiden)
6. [Von Null wieder aufbauen](#6-von-null-wieder-aufbauen)

---

## 1. Stand der Bausteine

| Baustein | Zustand | Wer |
|---|---|---|
| Webseite `index.html` | fertig, durchgetestet | ICT |
| Flow A «Problem-Melder - Analyse» | fertig, aktiv, getestet | ICT |
| Flow B «Problem-Melder - Absenden» | fertig, aktiv, getestet | ICT |
| KI-Prompt «Problem-Melder Analyse» | fertig, Modell GPT-5 chat, getestet | ICT |
| Dataverse-Verbindung für den AI Builder | vorhanden | ICT |
| Outlook-Verbindung für den Versand | vorhanden, Konto `servicedesk@` | Servicedesk |
| **Veröffentlichung der Seite** | **offen** | ICT |
| **Adresse und Verteilung an die Mitarbeitenden** | **offen** | ICT |
| **Entscheid zum Missbrauchsschutz** | **offen** | ICT |

Das Backend ist also vollständig in Betrieb. Was fehlt, ist die Seite an einer erreichbaren Adresse.

---

## 2. Die Webseite aufschalten

Die Seite ist eine einzige Datei ohne Abhängigkeiten. Sie läuft überall, wo sich eine HTML-Datei über `https://` ausliefern lässt.

### 2.1 Voraussetzungen

- `https://` ist Pflicht. Über `http://` sperren die Browser den Kamerazugriff auf dem Handy, und der Fotoschritt funktioniert nicht.
- Ein eigener Webserver ist nicht nötig, ebenso wenig eine Datenbank.
- Es braucht keine Anmeldung und keine App-Registrierung in Entra ID. Das ist der grosse Unterschied zur Menüwahl.

### 2.2 Weg A: Netlify, wie bei der Menüwahl

Der naheliegende Weg, weil dort bereits eine Site betrieben wird und das Vorgehen bekannt ist.

1. `https://app.netlify.com` öffnen und eine neue Site anlegen, oder die Datei in eine bestehende Site legen.
2. Einen Ordner anlegen, der **nur** die `index.html` aus `Quellcode\site\` enthält.
3. Diesen Ordner im Reiter **Deploys** in das Feld für Drag & Drop ziehen.
4. Warten, bis der Deploy als «Published» markiert ist.
5. Gewünschte Adresse einrichten, zum Beispiel `melden.campus-sursee.ch`, und den DNS-Eintrag setzen lassen.

Anders als bei der Menüwahl gibt es hier **keine** `_headers`-Datei und keine Content Security Policy. Wer eine setzen will, muss vier Quellen zulassen: den Power-Automate-Host für die beiden Flows, `fonts.googleapis.com` und `fonts.gstatic.com` für die Schrift sowie `www.campus-sursee.ch` für das Logo. Eine zu enge Regel blockiert die Aufrufe stillschweigend, und die Seite scheint grundlos nicht zu funktionieren.

### 2.3 Weg B: SharePoint oder Intranet

Denkbar, wenn die Seite nur intern erreichbar sein soll – das entschärft zugleich den Missbrauchspunkt aus Abschnitt 5.

Zu bedenken: Auf einer klassischen SharePoint-Seite wird eingebettetes JavaScript je nach Mandanteneinstellung blockiert. Ein Ablegen als Datei in einer Dokumentbibliothek liefert die Seite in der Regel zum Download aus statt sie darzustellen. Wer diesen Weg geht, prüft das vorher an einem Testgerät, und zwar mit dem Handy, nicht nur am PC.

### 2.4 Nach dem Aufschalten prüfen

Diese Prüfliste einmal vollständig durchgehen, am besten mit dem Handy im Mobilfunknetz, nicht nur im WLAN:

1. Seite öffnen. Logo erscheint, darunter der rote Hinweis «Proof of Concept», daneben «Schritt 1 von 3».
2. Eine falsche Adresse eingeben, «Weiter» tippen. Es muss «Bitte gib eine gültige E-Mail-Adresse ein.» erscheinen.
3. Richtige Adresse eingeben, «Weiter».
4. Foto aufnehmen. Die Kamera muss aufgehen. Geht sie nicht auf, wird die Seite nicht über `https://` ausgeliefert.
5. «Weiter». Erst «Fotos werden vorbereitet…», dann «Foto wird analysiert…». Nach wenigen Sekunden erscheint Schritt 3, idealerweise ausgefüllt.
6. Titel mit «TEST» beginnen, absenden. Die Bestätigung «Vielen Dank!» muss erscheinen.
7. Im Postfach `servicedesk@campus-sursee.ch` prüfen: Betreff `Problemmeldung: TEST … - …`, Foto als Anhang.
8. Seite schliessen und neu öffnen. Sie muss jetzt direkt bei Schritt 2 starten, weil die Adresse gemerkt wurde.
9. Denselben Durchlauf einmal mit «Überspringen und manuell beschreiben».

---

## 3. Eine Änderung veröffentlichen

Es gibt **keine** Git-Anbindung und keine automatische Veröffentlichung.

1. Änderung in `Quellcode\site\index.html` vornehmen.
2. Lokal prüfen:
   ```
   powershell -ExecutionPolicy Bypass -File Quellcode\serve.ps1
   ```
   Danach `http://localhost:8123/` öffnen und einmal ganz durchklicken. Die Seite spricht dabei mit den echten Flows; Testmeldungen also mit «TEST» im Titel kennzeichnen.
3. Datei veröffentlichen, siehe Abschnitt 2.2.
4. Mit Strg und F5 den Cache umgehen und die Prüfliste aus 2.4 zumindest in den Punkten 1, 5 und 6 wiederholen.

Bei Netlify lässt sich ein fehlerhafter Stand über den Deploy-Verlauf sofort zurücksetzen. Das ist der schnellste Ausweg, wenn nach einer Änderung nichts mehr geht.

> **Momentaufnahme im Blick behalten:** `Quellcode\site\index.html` ist eine Kopie vom 28.08.2026. Gearbeitet wurde in `C:\Claude\problem-melder\`. Wer dort ändert und veröffentlicht, spielt die Datei anschliessend hierher zurück, damit Dokumentation und Wirklichkeit nicht auseinanderlaufen.

---

## 4. Am Backend etwas ändern

Alle Wege dorthin sind ausführlich in `02_Betriebshandbuch_Support.md` beschrieben. Kurzübersicht:

| Ich will … | Wo | Abschnitt dort |
|---|---|---|
| das KI-Modell oder die Anweisung ändern | KI-Hub, Eingabeaufforderungen | 5.2 |
| den Empfänger der Meldungen ändern | Flow B, Aktion «E-Mail senden (V2)» | 5.4 |
| eine neue Aufrufadresse holen | Flow-Trigger | 5.5 |
| eine Verbindung erneuern | Flow-Aktion oder Verbindungsübersicht | 3.7 |

**Zwei Regeln für jede Arbeit an den Flows:**

1. **Immer den klassischen Designer verwenden.** An die Flow-Adresse `?v3=false` anhängen. Der neue Designer verweigerte in diesem Projekt wiederholt das Speichern.
2. **Jede Änderung nachkontrollieren.** Ausdrücke über **… → Vorschaucode** gegenlesen und danach einen echten Testaufruf machen (`02_Betriebshandbuch_Support.md`, Abschnitt 4.3). Speicherungen können still verloren gehen.

---

## 5. Vor dem Dauerbetrieb zu entscheiden

Diese Punkte sind für einen Proof of Concept vertretbar, gehören aber auf den Tisch, bevor das Tool offiziell wird. Ausführlich in `05_Entscheide_und_Verlauf.md`, Abschnitt 8.

### 5.1 Missbrauchsschutz

Beide Flows sind anonym aufrufbar, ihre Adressen stehen im Quelltext jeder ausgelieferten Seite. Wer sie ausliest, kann beliebig E-Mails an den Servicedesk auslösen und Copilot-Guthaben verbrauchen. Es gibt weder Anmeldung noch Rate-Limit.

Mögliche Wege, mit steigendem Aufwand:

| Weg | Aufwand | Wirkung |
|---|---|---|
| Seite nur intern erreichbar machen | gering | verhindert den Zugriff von aussen, nicht den von innen |
| gemeinsames Geheimnis in einem Kopffeld der Anfrage prüfen | mittel, Bedingung im Flow | hält Gelegenheitsmissbrauch ab; das Geheimnis steht ebenfalls im Quelltext |
| Anmeldung mit dem Geschäftskonto wie bei der Menüwahl | hoch, App-Registrierung nötig | echter Schutz, aber die Hürde beim Melden steigt |
| Rate-Limit im Flow, etwa über eine Zählerliste | mittel bis hoch | begrenzt den Schaden, verhindert ihn nicht |

Die Abwägung hängt daran, wie öffentlich die Adresse wird.

### 5.2 Kosten

Rund 3 Copilot-Guthaben pro Fotoanalyse mit GPT-5 chat. Vor der Freigabe an alle Mitarbeitenden eine grobe Mengenschätzung machen und den Verbrauch in den ersten Wochen beobachten (`02_Betriebshandbuch_Support.md`, Abschnitt 5.3). Ein Wechsel auf GPT-4.1 mini senkt die Kosten auf etwa ein Zehntel, kostet aber an Qualität.

### 5.3 Umgang mit den Meldungen

Zu klären, bevor die ersten echten Meldungen eintreffen:

- Wer im Servicedesk schaut wie oft ins Postfach?
- Werden die Meldungen von Hand weitergeleitet oder über eine Outlook-Regel nach Abteilung sortiert? Der Betreff enthält die Abteilung im Klartext und eignet sich dafür.
- Braucht es eine Rückmeldung an die meldende Person? Heute gibt es keine.
- Soll daraus ein Ticket in Freshdesk entstehen? Dann wäre eine Anbindung der nächste Ausbauschritt.

### 5.4 Datenschutz

Es entstehen Fotos vom Campus und E-Mail-Adressen von Mitarbeitenden. Beides landet ausschliesslich im Postfach des Servicedesk; es gibt keine weitere Ablage. Die Aufbewahrung richtet sich damit nach den Regeln für dieses Postfach. Die Fotos werden zur Analyse an den Microsoft-KI-Dienst im eigenen Power-Platform-Mandanten übermittelt. In der Anleitung steht der Hinweis, keine Personen und keine vertraulichen Bildschirminhalte zu fotografieren.

---

## 6. Von Null wieder aufbauen

Falls die Umgebung verloren geht, in dieser Reihenfolge:

### 6.1 KI-Prompt anlegen

1. `https://make.powerautomate.com` mit `powerplatform@campus-sursee.ch` öffnen, Umgebung **CAMPUS SURSEE (default)**.
2. Links **KI-Hub → Eingabeaufforderungen → Eigenen Prompt erstellen**.
3. Anweisungstext aus `03_Technische_Dokumentation.md`, Abschnitt 7.1 einsetzen.
4. Über **«Inhalt hinzufügen» → Bild oder Dokument** eine Eingabe anlegen und auf `Foto` umbenennen.
5. Rechts oben **Ausgabe** auf **JSON** stellen.
6. Modell auf **GPT-5 chat** stellen.
7. Ein Beispielbild bei der Eingabe hochladen und **Test** klicken. Das Testen ist Pflicht, sonst bleibt «Speichern» grau.
8. Prompt auf `Problem-Melder Analyse` umbenennen und speichern. Auf das Bestätigungsbanner warten.

### 6.2 Flow A anlegen

1. **Erstellen → Sofortiger Cloud-Flow**, Trigger «Beim Empfang einer HTTP-Anforderung».
2. Auf den klassischen Designer wechseln (`?v3=false`).
3. Trigger: **Wer kann den Flow auslösen? = Jeder**, Schema aus `03_Technische_Dokumentation.md`, Abschnitt 5.1 einfügen.
4. Aktion **«Einen Prompt ausführen»** (AI Builder) hinzufügen, Dataverse-Verbindung herstellen.
5. Eingabeaufforderung `Problem-Melder Analyse` wählen. Das Feld **Foto** erscheint danach.
6. In **Foto** den Ausdruck aus Abschnitt 5.2 der technischen Dokumentation setzen. **Genau diesen, nicht vereinfachen.**
7. Aktion **«Antwort»**: Status 200, Überschriften `Access-Control-Allow-Origin: *` und `Content-Type: application/json`, Text = Ausgabe **Text** der Prompt-Aktion.
8. Auf `Problem-Melder - Analyse` umbenennen und speichern.
9. HTTP-POST-URL kopieren und in der `index.html` bei `FLOW_A_URL` eintragen.

### 6.3 Flow B anlegen

1. Neuer sofortiger Cloud-Flow, gleicher Trigger, **Jeder**, Schema aus Abschnitt 6.1 der technischen Dokumentation.
2. Aktion **«Auswählen»**: Von = `triggerBody()?['fotos']`, Zuordnung `Name` → `item()?['name']`, `ContentBytes` → `item()?['contentBase64']`.
3. Aktion **«E-Mail senden (V2)»** mit der Verbindung **`servicedesk@campus-sursee.ch`**. Felder aus Abschnitt 6.3 der technischen Dokumentation. Die Anlagen stehen unter **«Erweiterte Optionen anzeigen»**; dort das Feld auf die Ausgabe der Auswählen-Aktion setzen.
4. Aktion **«Antwort»**: Status 200, dieselben Überschriften, Text `{"ok":true}`.
5. Auf `Problem-Melder - Absenden` umbenennen und speichern.
6. HTTP-POST-URL kopieren und in der `index.html` bei `FLOW_B_URL` eintragen.

### 6.4 Prüfen

1. Beide Flows von Hand aufrufen, siehe `02_Betriebshandbuch_Support.md`, Abschnitt 4.3.
2. Seite lokal starten und einmal ganz durchklicken.
3. Seite veröffentlichen und die Prüfliste aus Abschnitt 2.4 abarbeiten.

> Rechnen Sie beim Neuaufbau der Flows Zeit für die Eigenheiten des Designers ein. Die Sammlung in `03_Technische_Dokumentation.md`, Abschnitt 9, entstand genau dabei und erspart die meisten Sackgassen.
