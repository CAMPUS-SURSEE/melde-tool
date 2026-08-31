# Hinweise zum Quellcode

**Stand:** 28.08.2026

Der Ordner `frontend` enthält **die ganze Anwendung**: eine einzige HTML-Datei. Es gibt keinen Bauprozess, keine Abhängigkeiten zum Installieren und keinen Zwischenschritt. Was dort liegt, ist die Webseite – und genau dieser Ordner wird auf GitHub Pages veröffentlicht.

---

## Dateien

| Datei | Aufgabe |
|---|---|
| `frontend\index.html` | die komplette Anwendung: HTML, CSS und JavaScript in einer Datei, rund 1580 Zeilen |
| `frontend\.nojekyll` | verhindert, dass GitHub Pages die Dateien durch Jekyll schickt |
| `code\serve.ps1` | kleiner Server zum lokalen Anschauen |

Von aussen geladen wird nur Zierrat: die Schrift «Inter» von Google Fonts und das Campus-Sursee-Logo direkt von `www.campus-sursee.ch`. Beides ist optional – fällt es aus, sieht die Seite anders aus, funktioniert aber vollständig.

---

## Lokal anschauen

Aus dem Wurzelverzeichnis der Ablage heraus:

```
powershell -ExecutionPolicy Bypass -File code\serve.ps1
```

Danach im Browser `http://localhost:8123/` öffnen.

> **Port 8123 wird auch von der Menüwahl benutzt.** Läuft dort bereits ein `serve.ps1`, meldet der Browser «Bad Request - Invalid Hostname» oder die Seite bleibt aus. Dann den anderen Server beenden oder im Skript beide Vorkommen von `8123` auf eine freie Nummer ändern, etwa 8124.

> **Nicht über `file:///` öffnen.** Das schlägt fehl, und der `localStorage` verhält sich anders. Immer über den kleinen Server gehen.

> **Es gibt keinen Mock-Modus.** Anders als bei der Menüwahl spricht die Seite auch lokal mit den **echten** Flows. Ein Testdurchlauf erzeugt also eine echte E-Mail an `servicedesk@campus-sursee.ch` und verbraucht Copilot-Guthaben. Testmeldungen deshalb mit «TEST» im Titel kennzeichnen.

Wer nur das Backend prüfen will, ruft die beiden Flows direkt mit PowerShell auf. Die fertigen Befehle stehen in `..\02_Betriebshandbuch_Support.md`, Abschnitt 4.3.

---

## Wo was steht

Ganz oben im `<script>` stehen alle veränderlichen Werte:

```js
var FLOW_A_URL = "…";   // Analyse
var FLOW_B_URL = "…";   // Absenden
var MAX_KANTE = 1600;   // längste Bildkante nach dem Verkleinern
var JPEG_QUALITAET = 0.8;
var TIMEOUT_MS = 30000; // Abbruch beider Aufrufe
var MAX_FOTOS = 6;
var LS_KEY = "problemMelder.email";
```

Danach folgen in dieser Reihenfolge: Hilfsfunktionen, Navigation zwischen den vier Abschnitten, E-Mail-Verwaltung, Abteilungs-Radios, Bildverarbeitung, der Netzwerkaufruf und zuletzt die Ereignisbehandlung je Knopf.

Die vier Abschnitte heissen im HTML `screen1` (Kontakt), `screen2` (Fotos), `screen3` (Übersicht) und `screenErfolg`.

---

## Bevor du etwas änderst

- **Die Fehlertoleranz nicht wegoptimieren.** Der Ablauf ist so gebaut, dass eine gescheiterte Analyse **nie** den Meldeweg blockiert: fehlgeschlagener Aufruf, Zeitüberschreitung, unlesbare Antwort oder leere Felder führen alle auf Schritt 3 mit dem Hinweis «Automatische Analyse nicht verfügbar». Wer diese Zweige zusammenfasst, macht aus einer Bequemlichkeit eine Voraussetzung.
- **`jsonParsenWeich` ist absichtlich nachsichtig.** Es nimmt reines JSON, ein Array mit einem Objekt und ein verschachteltes oder als Zeichenkette eingebettetes Objekt. Grund: Die Antwortform der AI-Builder-Aktion hat sich beim Aufbau mehrfach geändert.
- **`abteilungNormieren` schützt die Auswahlfelder.** Die KI-Antwort wird gegen die vier erlaubten Werte abgeglichen, alles andere ergibt keine Vorauswahl. Ohne diese Prüfung könnte ein Modellwort wie «Keine» ein Auswahlfeld erzeugen, das es gar nicht gibt.
- **Die vier Abteilungsnamen stehen an zwei Orten** – in dieser Datei und im KI-Prompt. Wer sie ändert, muss beides anfassen, sonst passt der Vorschlag nicht mehr zur Auswahl.
- **`Content-Type` muss `application/json` bleiben.** Der Flow-Trigger nimmt kein `text/plain` an und antwortet dann mit `TriggerInputSchemaMismatch`. Der CORS-Preflight ist kein Problem: Das Power-Platform-Gateway beantwortet ihn selbst.
- **Bildverkleinerung nicht abschalten.** Ohne sie gehen mehrere Megabyte pro Foto über Mobilfunk, und die Meldung läuft in die Zeitüberschreitung.
- **Neue fremde Adressen mitdenken.** Wird am Zielort eine Content Security Policy gesetzt, muss jede neue Quelle dort freigegeben werden, sonst blockiert der Browser den Aufruf stillschweigend.

Ausführlich steht das in `..\03_Technische_Dokumentation.md`, Abschnitte 3, 4 und 9.

---

## Verhältnis zum Arbeitsverzeichnis

Der Stand in `frontend\` ist eine **Momentaufnahme** vom 28.08.2026. Gearbeitet wurde in `C:\Claude\problem-melder\`. Wer dort etwas ändert und veröffentlicht, sollte die Datei anschliessend nach `frontend\` zurückspielen, damit Dokumentation und Wirklichkeit nicht auseinanderlaufen.

Veröffentlicht wird über GitHub Pages beziehungsweise von Hand. Zum Vorgehen siehe `..\04_Einrichtung_und_Deployment.md`, Abschnitte 2 und 3.
