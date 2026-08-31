# Betriebs- und Supporthandbuch: Melde-Tool

**Für:** ICT-Services Campus Sursee
**Stand:** 28.08.2026
**Gilt für:** die Webseite «Problem melden» samt den beiden Power-Automate-Flows und dem KI-Prompt im KI-Hub
**Verwandte Dokumente:** `03_Technische_Dokumentation.md` (Architektur und Kennungen), `04_Einrichtung_und_Deployment.md` (aufschalten und ändern)

Alle Zitate von Fehlermeldungen in diesem Handbuch stammen wortgetreu aus `frontend\index.html` beziehungsweise aus den Flow-Läufen.

---

## Inhaltsverzeichnis

1. [System in zwei Minuten](#1-system-in-zwei-minuten)
2. [Regelbetrieb](#2-regelbetrieb)
3. [Fehlerbilder](#3-fehlerbilder)
   - [3.1 Meldung lässt sich nicht absenden](#31-meldung-lässt-sich-nicht-absenden)
   - [3.2 «Backend noch nicht konfiguriert»](#32-backend-noch-nicht-konfiguriert)
   - [3.3 Analyse liefert nichts, Felder bleiben leer](#33-analyse-liefert-nichts-felder-bleiben-leer)
   - [3.4 Analyse bricht mit Fehler ab, Flow A rot](#34-analyse-bricht-mit-fehler-ab-flow-a-rot)
   - [3.5 Meldungen kommen nicht im Postfach an](#35-meldungen-kommen-nicht-im-postfach-an)
   - [3.6 E-Mail kommt ohne Fotos an](#36-e-mail-kommt-ohne-fotos-an)
   - [3.7 Verbindung im Designer als unterbrochen gemeldet](#37-verbindung-im-designer-als-unterbrochen-gemeldet)
   - [3.8 Copilot-Guthaben aufgebraucht](#38-copilot-guthaben-aufgebraucht)
   - [3.9 Seite bleibt leer oder ohne Logo](#39-seite-bleibt-leer-oder-ohne-logo)
   - [3.10 Fotos lassen sich nicht verarbeiten](#310-fotos-lassen-sich-nicht-verarbeiten)
   - [3.11 Weitere Meldungen im Wortlaut](#311-weitere-meldungen-im-wortlaut)
4. [Diagnose-Werkzeuge](#4-diagnose-werkzeuge)
5. [Wiederkehrende Aufgaben](#5-wiederkehrende-aufgaben)
6. [Grenzen und bekannte Schwächen](#6-grenzen-und-bekannte-schwächen)
7. [Eskalation](#7-eskalation)

---

## 1. System in zwei Minuten

### 1.1 Bestandteile

| Bestandteil | Was es ist | Wo |
|---|---|---|
| `index.html` | die ganze Webseite in einer Datei, ohne Anmeldung | vorgesehen: Netlify |
| Flow A «Problem-Melder - Analyse» | POST, nimmt Fotos entgegen, lässt sie von der KI beschreiben, gibt JSON zurück | Power Automate |
| Flow B «Problem-Melder - Absenden» | POST, verschickt die Meldung als E-Mail mit Fotos im Anhang | Power Automate |
| Prompt «Problem-Melder Analyse» | die KI-Anweisung samt Abteilungslogik, Modell GPT-5 chat | Power Platform KI-Hub |
| Verbindung Microsoft Dataverse | wird von der AI-Builder-Aktion in Flow A vorausgesetzt | Konto powerplatform@campus-sursee.ch |
| Verbindung Office 365 Outlook | verschickt die Meldungen | Konto servicedesk@campus-sursee.ch |

Es gibt **keine Datenbank, keine SharePoint-Liste und keine Ablage**. Die einzige Spur einer Meldung ist die E-Mail im Postfach des Servicedesk und der Flow-Lauf im Ausführungsverlauf (28 Tage).

### 1.2 Wer redet mit wem

```
Handy oder PC der meldenden Person
        |
        |  1. POST Fotos            2. POST ganze Meldung
        v                                    v
     Flow A  «Analyse»                  Flow B  «Absenden»
        |                                    |
        v                                    +--> Auswählen (Fotos zu Anhängen)
   AI Builder Prompt                         |
   «Problem-Melder Analyse»                  v
   Modell GPT-5 chat                    E-Mail senden (V2)
        |                                    |
        v                                    v
   JSON zurück an die Seite      servicedesk@campus-sursee.ch
```

Beide Flows sind **anonym aufrufbar** («Wer kann den Flow auslösen? = Jeder»). Es gibt kein Konto, kein Token und keine Anmeldung. Der Schutz besteht allein darin, dass die Aufrufadressen eine lange Signatur enthalten – und die steht im Quelltext jeder ausgelieferten Seite. Siehe Abschnitt 6, Punkt 1.

### 1.3 Zuständigkeiten

| Thema | Zuständig |
|---|---|
| Meldungen bearbeiten und weiterleiten | Servicedesk und die vier Abteilungen |
| Flows, Verbindungen, KI-Prompt | ICT-Services, Konto `powerplatform@campus-sursee.ch` |
| Outlook-Verbindung und Postfach | Servicedesk, Konto `servicedesk@campus-sursee.ch` |
| Webseite und Veröffentlichung | ICT-Services |
| Copilot-Guthaben der Umgebung | ICT-Services |

---

## 2. Regelbetrieb

Im Normalfall ist nichts zu tun. Es gibt keinen Server, keine geplante Wartung und keinen Aufräum-Flow, weil nichts gespeichert wird.

**Was von allein läuft:**

- **Die beiden Flows.** Sie werden nur aufgerufen, wenn jemand meldet. Ohne Meldungen laufen sie gar nicht und verbrauchen nichts.
- **Die Bildverkleinerung.** Sie läuft im Browser der meldenden Person, nicht auf einem Server. Jedes Foto wird auf höchstens 1600 Pixel längste Kante gebracht und als JPEG mit Qualität 0.8 kodiert, bevor es das Gerät verlässt.
- **Der Ausführungsverlauf.** Power Automate behält die Läufe 28 Tage. Danach sind sie weg; die E-Mails im Postfach bleiben.

**Was niemand anfassen muss:**

- Die beiden Flows im Designer. Sie sind fertig und laufen. Änderungen dort sind heikel, siehe Abschnitt 3.7 und die Fallstricke in `03_Technische_Dokumentation.md`, Abschnitt 9.
- Der Ausdruck im Feld «Foto» von Flow A. Er sieht umständlich aus und muss genau so bleiben, siehe Abschnitt 3.4.

**Regelmässig sinnvoll, aber nicht dringend:**

- Einmal im Quartal einen Blick auf den Verbrauch an Copilot-Guthaben, siehe Abschnitt 5.3.
- Bei auffällig vielen Meldungen prüfen, ob jemand die Schnittstelle missbraucht, siehe Abschnitt 6, Punkt 1.

---

## 3. Fehlerbilder

Aufbau je Abschnitt: **Symptom**, **wahrscheinliche Ursache**, **Prüfschritt**, **Behebung**.

Zum Verständnis der Meldungen: Die Seite unterscheidet drei Sorten. **Rote Texte direkt beim Feld** sind Eingabefehler der Person. Der **rote Kasten oben im Formular** meldet fehlende Pflichtfelder. Der **rote Kasten über dem Absenden-Knopf** meldet Übertragungsfehler. Der **graue Hinweis über dem Formular** («Automatische Analyse nicht verfügbar …») ist kein Fehler, sondern der Normalfall bei nicht erkanntem Bild.

### 3.1 Meldung lässt sich nicht absenden

**Symptom:** Über dem Knopf «Absenden» erscheint

> Die Verbindung hat zu lange gedauert. Bitte prüfe deine Netzwerkverbindung und versuche es nochmals.

oder

> Die Verbindung zum Server ist fehlgeschlagen. Bitte prüfe deine Netzwerkverbindung und versuche es nochmals.

**Wichtig vorweg:** In beiden Fällen wurde **nichts gesendet**. Es entsteht keine halbe Meldung und keine doppelte E-Mail. Das Formular bleibt ausgefüllt stehen.

| Ursache | Prüfschritt | Behebung |
|---|---|---|
| Schlechter Empfang beim Meldenden. Häufig auf dem Areal, in Kellern und Technikräumen. Die erste Meldung ist am anfälligsten, weil mit den Fotos einige Megabyte hochgehen. | Nachfragen, wo die Person steht und ob andere Seiten laden. | An einen Ort mit besserem Empfang gehen und nochmals auf «Absenden» tippen. |
| Zeitüberschreitung nach 30 Sekunden bei sehr vielen oder sehr grossen Fotos. | Anzahl Fotos erfragen. Bei sechs Bildern kommen leicht ein paar Megabyte zusammen. | Meldung mit weniger Fotos nochmals senden. |
| Flow B ist deaktiviert oder gelöscht. | In Power Automate den Flow «Problem-Melder - Absenden» öffnen, Feld **Status** prüfen. Muss «Ein» sein. | Flow aktivieren. Siehe Abschnitt 4.2. |
| Die Outlook-Verbindung ist ungültig geworden. | Ausführungsverlauf von Flow B ansehen, die Aktion «E-Mail senden (V2)» ist dann rot. | Verbindung erneuern, siehe Abschnitt 3.7. |
| Störung bei Microsoft. | `https://status.powerplatform.microsoft.com` prüfen. | Abwarten. Meldungen laufen so lange über Telefon oder E-Mail. |

**Achtung bei der Zuordnung:** Kommt der Fehler beim **Absenden**, geht es um Flow B. Kommt er beim **Weiter** nach den Fotos, geht es um Flow A – und dann erscheint gar keine Fehlermeldung, sondern die Seite geht mit leeren Feldern weiter, siehe 3.3.

### 3.2 «Backend noch nicht konfiguriert»

**Symptom:** Beim Absenden erscheint

> Backend noch nicht konfiguriert. Die Meldung kann aktuell nicht abgesendet werden – bitte den ICT-Servicedesk informieren.

**Ursache:** In der ausgelieferten `index.html` steht bei `FLOW_B_URL` noch der Platzhalter `%%FLOW_B_URL%%` statt der echten Aufrufadresse. Die Seite prüft das vor dem Senden und macht gar keinen Versuch. Das passiert, wenn eine unfertige Fassung veröffentlicht wurde.

**Prüfschritt:** Im Browser die Seite öffnen, Quelltext anzeigen (Strg + U), nach `FLOW_B_URL` suchen. Steht dort etwas mit `%%`, ist es dieser Fall.

**Behebung:** Die richtige Fassung aus `frontend\index.html` veröffentlichen (Abschnitt 5.1). Diese Fassung enthält beide Adressen fertig eingetragen.

### 3.3 Analyse liefert nichts, Felder bleiben leer

**Symptom:** Nach «Weiter» im Fotoschritt erscheint Schritt 3 mit leeren Feldern und dem Hinweis

> Automatische Analyse nicht verfügbar – bitte manuell ausfüllen.

**Das ist in den meisten Fällen kein Fehler.** Die Seite ist bewusst so gebaut, dass sie bei jedem Problem mit der Analyse einfach weitergeht. Die Meldung lässt sich vollständig von Hand ausfüllen und absenden; die Fotos gehen mit.

| Ursache | Prüfschritt | Behebung |
|---|---|---|
| Auf dem Bild ist kein Problem erkennbar. Das Modell gibt dann leere Felder zurück. Das ist der häufigste Fall. | Ausführungsverlauf von Flow A: Der Lauf ist **grün**, in der Ausgabe der Prompt-Aktion stehen leere Werte. | Nichts. Der meldenden Person erklären, dass sie von Hand ausfüllen kann und dass ein Bild mit erkennbarem Ausschnitt und Beschriftung bessere Vorschläge ergibt. |
| Zeitüberschreitung: Die Analyse dauert länger als 30 Sekunden. | Ausführungsverlauf: Die Dauer des Laufs liegt bei 30 Sekunden und mehr. Normal sind rund 4 Sekunden. | Meist eine kurze Verzögerung beim Dienst. Wiederholen. Häuft es sich, Modell prüfen: «GPT-5 reasoning» ist deutlich langsamer als «GPT-5 chat». |
| Flow A meldet einen Fehler. | Ausführungsverlauf: Der Lauf ist **rot**. | Siehe 3.4. |
| Copilot-Guthaben aufgebraucht. | Siehe 3.8. | Siehe 3.8. |

### 3.4 Analyse bricht mit Fehler ab, Flow A rot

**Symptom:** Im Ausführungsverlauf von «Problem-Melder - Analyse» ist die Aktion «Einen Prompt ausführen» rot. Für die meldende Person sieht das aus wie 3.3, die Seite geht also mit leeren Feldern weiter.

**Häufigster Fehlertext:**

> InvalidPredictionInput … Image url cannot be accessed … invalid_image_format … You uploaded an unsupported image. Please make sure your image has one of the following formats: ['png', 'webp', 'gif', 'jpeg']

**Ursache:** Das Feld **«Foto»** der Prompt-Aktion bekommt nicht das erwartete Dateiobjekt. Ein nackter Base64-String oder eine `data:`-URI reichen **nicht**; die Aktion versucht dann, den Wert als Bildadresse aufzurufen. Richtig ist ausschliesslich:

```
json(concat('{"$content-type":"image/jpeg","$content":"', triggerBody()?['fotos']?[0]?['contentBase64'], '"}'))
```

Dieser Ausdruck ist beim Aufbau des Flows in mehreren Anläufen entstanden und darf nicht «vereinfacht» werden.

**Prüfschritt:** Flow im **klassischen** Designer öffnen (`?v3=false`), Aktion «Einen Prompt ausführen» aufklappen. Im Feld «Foto» muss ein einzelnes Ausdrucks-Plättchen `json(...)` stehen. Zur Kontrolle über das Menü **… → Vorschaucode** die Codeansicht öffnen und den Ausdruck im Klartext vergleichen.

**Behebung:** Ausdruck neu setzen, Flow speichern und mit einem Testaufruf prüfen (Abschnitt 4.3).

**Weitere Fehlertexte an derselben Stelle:**

| Text im Lauf | Ursache | Behebung |
|---|---|---|
| «Verbindung wurde nicht gefunden» / «Ungültige Verbindung» | Die Dataverse-Verbindung der Aktion ist weg oder ungültig. | Siehe 3.7. |
| Meldung zu Guthaben oder Kontingent | Copilot-Guthaben aufgebraucht. | Siehe 3.8. |
| `TriggerInputSchemaMismatch … Expected Object but got String` | Der Aufrufer hat den Text nicht als JSON geschickt. Tritt bei der Seite nicht auf, wohl aber bei Tests von Hand mit `Content-Type: text/plain`. | Mit `application/json` aufrufen. Siehe `03_Technische_Dokumentation.md`, Abschnitt 6. |

### 3.5 Meldungen kommen nicht im Postfach an

**Symptom:** Jemand sagt, er habe die Bestätigung «Vielen Dank!» gesehen, im Postfach `servicedesk@campus-sursee.ch` liegt aber nichts.

Wichtig: Die Bestätigung erscheint erst, wenn Flow B mit `{"ok":true}` geantwortet hat. Die E-Mail war zu diesem Zeitpunkt also bereits verschickt.

| Ursache | Prüfschritt | Behebung |
|---|---|---|
| Die Mail liegt im Junk-Ordner oder wurde von einer Regel wegsortiert. Sie kommt vom Postfach an sich selbst, was manche Regeln irritiert. | Junk-Ordner und die Regeln des Postfachs durchsehen. Im Ausführungsverlauf von Flow B prüfen, ob der Lauf grün ist. | Regel anpassen, Absender als sicher einstufen. |
| Der Lauf ist grün, aber die Aktion «E-Mail senden (V2)» meldet einen Fehler von Exchange. | Aktion im Lauf aufklappen und die Ausgabe lesen. | Meist ein Problem mit dem Postfach oder der Verbindung, siehe 3.7. |
| Der Flow wurde gar nicht aufgerufen. | Ausführungsverlauf: Zum genannten Zeitpunkt existiert kein Lauf. | Dann kann die Bestätigung nicht erschienen sein. Rückfrage bei der meldenden Person, gegebenenfalls Bildschirmfoto verlangen. |
| Flow B ist deaktiviert. | Feld **Status** des Flows. | Aktivieren. |

### 3.6 E-Mail kommt ohne Fotos an

**Symptom:** Die Meldung ist da, Titel und Beschreibung stimmen, es fehlen aber die Anhänge.

| Ursache | Prüfschritt | Behebung |
|---|---|---|
| Die Person hat «Überspringen und manuell beschreiben» benutzt. Das ist der Normalfall. | Kein Prüfschritt nötig; im Flow-Lauf ist `fotos` ein leeres Array. | Nichts. |
| Die Aktion «Auswählen» ist beschädigt oder ihre Zuordnung wurde verändert. | Flow B im klassischen Designer öffnen, Aktion «Auswählen» prüfen: **Von** muss `triggerBody()?['fotos']` sein, die Zuordnung `Name` → `item()?['name']` und `ContentBytes` → `item()?['contentBase64']`. | Zuordnung wiederherstellen, speichern, testen. |
| Im Feld «Anlagen» der E-Mail-Aktion fehlt der Bezug `body('Auswählen')`. | Erweiterte Optionen der Aktion «E-Mail senden (V2)» aufklappen. | Bezug neu setzen. Das Feld muss auf die Ausgabe der Auswählen-Aktion zeigen, nicht auf einzelne Unterfelder. |

### 3.7 Verbindung im Designer als unterbrochen gemeldet

**Symptom:** Beim Öffnen oder Speichern eines Flows erscheint «Die Verbindung für … wurde unterbrochen» oder in der Aktion «Ungültige Verbindung. Aktualisieren Sie Ihre Verbindung, um vollständige Details zu laden.» Das Speichern schlägt fehl.

**Ursache und Eigenheit:** Diese Meldung ist häufig **veraltet**. Beim Aufbau dieses Projekts zeigte die Verbindungsübersicht alle Verbindungen als «Verbunden», während der Designer sie hartnäckig als ungültig führte und das Speichern verweigerte.

**Prüfschritte, in dieser Reihenfolge:**

1. In der Umgebung unter **Verbindungen** nachsehen, ob die betroffene Verbindung wirklich einen Fehler zeigt. Ist sie dort «Verbunden», ist die Meldung im Designer stale.
2. Prüfen, ob es trotzdem funktioniert: Im Feld «An» der E-Mail-Aktion eine Adresse eintippen. Wird sie zu einem Kontakt aufgelöst, ist die Verbindung in Ordnung.

**Behebung, in dieser Reihenfolge:**

1. **Auf den klassischen Designer wechseln.** An die Flow-Adresse `?v3=false` anhängen. Der neue Designer konnte den Flow in diesem Projekt wiederholt nicht speichern, der klassische schon.
2. **Verbindung in der Aktion neu auswählen.** Über **… → Meine Verbindungen** die gewünschte Verbindung anklicken.
3. **Designer neu laden.** Die ungespeicherte Fassung wird vom Browser gemerkt; nach dem Neuladen bietet die Seite oben rechts **«Flow wiederherstellen»** an. Das funktioniert zuverlässig und hat beim Aufbau mehrfach die Arbeit gerettet.
4. Hilft alles nichts: betroffene Aktion löschen und neu einfügen.

> **Zur Outlook-Verbindung:** Sie läuft bewusst über `servicedesk@campus-sursee.ch` und **nicht** über `powerplatform@campus-sursee.ch`. Das Konto powerplatform hat kein nutzbares Postfach; mit ihm erstellte Outlook-Verbindungen werden vom Designer dauerhaft als ungültig geführt. Wer sie «repariert», indem er eine powerplatform-Verbindung auswählt, bricht den Versand.

> **Zu OAuth-Fenstern:** Wird beim Erneuern einer Verbindung ein Anmeldefenster verlangt, öffnet Chrome es nur, wenn der Power-Automate-Tab im Vordergrund ist und der Klick von Hand kommt. Bleibt die Anzeige minutenlang bei «Anmeldung wird ausgeführt…», ist das Fenster gar nie aufgegangen: Tab in den Vordergrund holen und den Knopf selbst anklicken.

### 3.8 Copilot-Guthaben aufgebraucht

**Symptom:** Alle Analysen scheitern gleichzeitig, für die Meldenden sieht es aus wie 3.3. Im Ausführungsverlauf ist die Prompt-Aktion rot mit einem Hinweis auf Guthaben oder Kontingent.

**Ursache:** Die AI-Builder-Aktion rechnet über Copilot-Guthaben ab. Ein Lauf mit dem Modell **GPT-5 chat** kostet rund **3 Guthaben**, mit GPT-4.1 mini rund 0.3.

**Prüfschritt:** Im Power Platform Admin Center unter **Ressourcen → Kapazität** den Verbrauch der Umgebung ansehen.

**Behebung:** Guthaben aufstocken, oder im Prompt auf ein günstigeres Modell wechseln (Abschnitt 5.2). Bis dahin funktioniert das Melden weiter, nur ohne Vorschläge.

### 3.9 Seite bleibt leer oder ohne Logo

**Symptom A:** Die Seite lädt gar nicht oder zeigt nur weisse Fläche.

**Ursache:** Die Datei wurde unvollständig oder gar nicht veröffentlicht. Die Seite hat keine Abhängigkeiten ausser den Schriften; wenn sie leer bleibt, fehlt sie selbst.

**Behebung:** `frontend\index.html` neu veröffentlichen (Abschnitt 5.1).

**Symptom B:** Die Seite läuft, aber oben fehlt das Campus-Sursee-Logo, und im Browsertab fehlt das Symbol.

**Ursache:** Logo und Favicon werden direkt von `https://www.campus-sursee.ch/wp-content/themes/campus-sursee/assets/images/Campus_Sursee_Hauptlogo_RGB.svg` geladen. Ist die Hauptseite nicht erreichbar, wurde die Datei dort umbenannt oder verschoben, fehlt das Bild.

**Prüfschritt:** Die Adresse direkt im Browser aufrufen. Erscheint das Logo nicht, liegt es an der Quelle, nicht am Melde-Tool.

**Behebung:** Warten, bis die Hauptseite wieder erreichbar ist. Ist die Datei dauerhaft weggezogen: neue Adresse im Quelltext eintragen, an beiden Stellen (`<link rel="icon">` im Kopf und `<img>` im Körper). Die Anwendung ist voll benutzbar, auch ohne Logo.

**Symptom C:** Die Schrift sieht anders aus als gewohnt.

**Ursache:** Google Fonts (Inter) ist nicht erreichbar. Die Seite fällt dann auf die Systemschrift zurück. Kein Handlungsbedarf.

### 3.10 Fotos lassen sich nicht verarbeiten

**Symptom:** Im Fotoschritt erscheint

> Die Fotos konnten nicht verarbeitet werden. Bitte nochmals versuchen.

**Ursache:** Beim Verkleinern im Browser ist etwas schiefgegangen. Häufig: eine beschädigte Datei, ein exotisches Format, das der Browser nicht dekodiert, oder ein sehr altes Gerät, dem der Arbeitsspeicher ausgeht.

**Behebung:** Betroffenes Bild entfernen und ein neues aufnehmen. Bleibt es dabei, den Fotoschritt überspringen und von Hand beschreiben; die Meldung geht dann ohne Bild. Grundsätzlich gilt: Diese Meldung betrifft **nur** das Gerät der meldenden Person, nicht das System.

### 3.11 Weitere Meldungen im Wortlaut

| Meldung (wortgetreu) | Wo | Ursache | Behebung |
|---|---|---|---|
| «Bitte gib eine gültige E-Mail-Adresse ein.» | Schritt 1, unter dem Feld | Adresse leer oder ohne gültige Form | Adresse korrigieren. Kein Systemfehler. |
| «Bitte mindestens ein Foto aufnehmen – oder den Schritt überspringen.» | Schritt 2 | «Weiter» ohne Foto | Foto wählen oder «Überspringen und manuell beschreiben» benutzen. |
| «Es werden maximal 6 Fotos übernommen.» | Schritt 2 | mehr als sechs Bilder ausgewählt | Kein Fehler. Die ersten sechs werden übernommen. |
| «Bitte ausfüllen: Titel, Beschreibung, Abteilung.» (nur die tatsächlich fehlenden) | Schritt 3, roter Kasten oben | Pflichtfelder leer | Felder ausfüllen. Kein Systemfehler. |
| «Fotos werden vorbereitet…» / «Bilder werden verkleinert» | Überlagerung | Normalzustand während der Verkleinerung | Abwarten, wenige Sekunden. |
| «Foto wird analysiert…» / «Das kann einen Moment dauern» | Überlagerung | Normalzustand während des Aufrufs von Flow A | Abwarten. Nach 30 Sekunden bricht die Seite selbst ab und geht mit leeren Feldern weiter. |
| «Meldung wird gesendet…» / «Einen Moment bitte» | Überlagerung | Normalzustand während des Aufrufs von Flow B | Abwarten. |

---

## 4. Diagnose-Werkzeuge

### 4.1 Die Seite lokal starten

Im Wurzelverzeichnis der Ablage:

```
powershell -ExecutionPolicy Bypass -File code\serve.ps1
```

Danach `http://localhost:8123/` öffnen. Die Seite spricht dabei mit den **echten** Flows; ein Testabsenden erzeugt also eine echte E-Mail an den Servicedesk. Titel deshalb mit «TEST» beginnen lassen.

Einen Mock-Modus wie bei der Menüwahl gibt es nicht. Wer nur die Darstellung prüfen will, kommt mit den Entwicklerwerkzeugen weiter.

### 4.2 Flow-Läufe in Power Automate

1. `https://make.powerautomate.com` öffnen, anmelden mit **powerplatform@campus-sursee.ch**.
2. Umgebung oben rechts auf **CAMPUS SURSEE (default)** stellen, technisch `Default-2553fb74-5dcc-4072-8bb5-399d18f72af9`.
3. **Meine Flows**, dann den gewünschten Flow:
   - **Problem-Melder - Analyse** (Flow A), ID `9d38c54c-f92b-4ac1-8f99-85f8db8b7f10`
   - **Problem-Melder - Absenden** (Flow B), ID `31581404-1a5a-46da-a9ad-a7f47e5209f9`
4. Auf der Detailseite unter **Ausführungsverlauf über 28 Tage** den Lauf zum fraglichen Zeitpunkt anklicken. Rote Aktionen aufklappen; dort stehen Eingaben, Ausgaben und der Fehlertext des Dienstes.

Nützlich: In Flow A zeigt die Aktion «Einen Prompt ausführen» unter **Ausgaben** das Feld **Ergebnis** mit dem rohen JSON des Modells, dazu **Verwendetes Modell**, Prompttoken und Abschlusstoken. Damit lässt sich in Sekunden klären, ob die KI nichts erkannt hat oder ob es ein technischer Fehler war.

> Bei sehr grossen Läufen bietet die Oberfläche Eingaben und Ausgaben nur als Download an («Zum Herunterladen klicken»). Das ist normal und liegt an den Fotos im Base64-Format.

### 4.3 Beide Flows von Hand testen

Ein Aufruf von PowerShell aus, ohne Browser und ohne Seite. Nützlich, um Frontend und Backend sauber zu trennen. Die Aufrufadressen stehen im Quelltext von `frontend\index.html` bei `FLOW_A_URL` und `FLOW_B_URL`.

**Flow A, Analyse:**

```powershell
$url = '<FLOW_A_URL>'
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\Pfad\zum\testfoto.jpg'))
$body = @{ email='test@campus-sursee.ch'; fotos=@(@{ name='foto1.jpg'; contentBase64=$b64 }) } |
        ConvertTo-Json -Depth 5 -Compress
Invoke-WebRequest -Uri $url -Method POST -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
  -ContentType 'application/json;charset=UTF-8' -UseBasicParsing | Select-Object -Expand Content
```

Erwartet wird HTTP 200 mit einem JSON wie:

```json
{ "titel": "Drucker mit Papierstau",
  "beschreibung": "Auf dem Foto ist ein Druckerdisplay zu sehen, das den Fehler 'Paper Jam' anzeigt. …",
  "abteilung": "ICT-Servicedesk" }
```

**Flow B, Absenden** – Achtung, das verschickt eine echte E-Mail:

```powershell
$url = '<FLOW_B_URL>'
$body = @{ email='test@campus-sursee.ch'; titel='TEST Bitte ignorieren';
           beschreibung='Automatischer Test.'; abteilung='ICT-Servicedesk'; fotos=@() } |
        ConvertTo-Json -Depth 5 -Compress
Invoke-WebRequest -Uri $url -Method POST -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
  -ContentType 'application/json;charset=UTF-8' -UseBasicParsing | Select-Object -Expand Content
```

Erwartet wird HTTP 200 mit `{"ok":true}`.

**Deutung der Antworten:**

| Antwort | Bedeutung |
|---|---|
| HTTP 200 mit erwartetem Inhalt | Backend in Ordnung. Liegt der Fehler trotzdem vor, ist es das Frontend oder das Netzwerk der meldenden Person. |
| HTTP 502 `NoResponse` | Der Flow lief an und ist mittendrin gescheitert. Ausführungsverlauf ansehen, siehe 3.4. |
| HTTP 400 `TriggerInputSchemaMismatch` | Der Aufruf passt nicht zum Trigger-Schema. Meist wurde `text/plain` statt `application/json` gesendet. |
| HTTP 202 ohne Inhalt | Der Flow hat keine Antwort-Aktion mehr oder sie steht nicht am Ende. Flow prüfen. |
| gar keine Verbindung | Netzwerk, Proxy oder FortiGate. Andere Adresse zum Vergleich aufrufen. |

### 4.4 CORS prüfen

Die Seite ruft die Flows aus dem Browser heraus auf, also über Domänengrenzen hinweg. Der Preflight lässt sich einzeln prüfen:

```powershell
Invoke-WebRequest -Uri '<FLOW_URL>' -Method OPTIONS -UseBasicParsing -Headers @{
  'Origin'='https://beispiel.ch'; 'Access-Control-Request-Method'='POST'
  'Access-Control-Request-Headers'='content-type' }
```

Erwartet wird HTTP 204 mit `Access-Control-Allow-Origin: *`. Diese Antwort erzeugt die Power-Platform-Gateway selbst; sie muss nicht im Flow gebaut werden. Fehlt sie, blockiert der Browser den Aufruf, und für die meldende Person sieht es aus wie ein Verbindungsfehler.

### 4.5 Entwicklerwerkzeuge im Browser

F12, Reiter **Konsole** und **Netzwerk**, dann die Seite benutzen. Erwartet werden genau zwei fremde Aufrufe: ein POST an den Power-Automate-Host beim «Weiter» nach den Fotos, ein zweiter POST beim «Absenden». Dazu die Schriften von Google Fonts und das Logo von `www.campus-sursee.ch`.

Steht bei einem POST ein Statuscode wie 400, 429 oder 502, gehört er ins Ticket. Fehlt der Aufruf ganz, wurde er blockiert – Werbeblocker, Proxy oder FortiGate prüfen.

---

## 5. Wiederkehrende Aufgaben

### 5.1 Eine Änderung an der Webseite veröffentlichen

Es gibt **keine** automatische Veröffentlichung.

1. Änderung in `frontend\index.html` vornehmen.
2. Lokal prüfen: `code\serve.ps1` starten, `http://localhost:8123/` öffnen, einmal ganz durchklicken. Testmeldungen mit «TEST» im Titel kennzeichnen.
3. Datei am Zielort veröffentlichen. Vorgesehen ist Netlify wie bei der Menüwahl: Site auswählen, Reiter **Deploys**, den Ordner mit der `index.html` in das Feld für Drag & Drop ziehen.
4. Nach dem Veröffentlichen den Browsercache umgehen (Strg und F5) und nochmals durchklicken.

Ein fehlerhafter Stand lässt sich bei Netlify über den Deploy-Verlauf sofort zurücksetzen.

### 5.2 KI-Modell oder Prompt ändern

1. `https://make.powerautomate.com` mit **powerplatform@campus-sursee.ch** öffnen, richtige Umgebung wählen.
2. Links **Eingabeaufforderungen**, in der Liste unten **«Problem-Melder Analyse»** anklicken.
3. Oben rechts beim Feld **Modell** die Auswahl öffnen. Zur Wahl stehen unter anderem GPT-4.1 mini (Basic), GPT-4.1 (Standard), **GPT-5 chat** (Standard, aktuell eingestellt), GPT-5 reasoning (Premium) und Claude Sonnet 4.6 (experimentell, kostenpflichtig).
4. Anweisungstext bei Bedarf anpassen. Die vier Abteilungsnamen müssen **wortgleich** bleiben, sonst passt die Antwort nicht zu den Auswahlfeldern der Seite.
5. **Testen ist Pflicht**, sonst bleibt «Speichern» grau: bei der Eingabe «Foto» ein Beispielbild hochladen, Dialog schliessen, oben auf **«Test»** klicken und das Ergebnis abwarten.
6. **Speichern** und auf das grüne Banner **«Ihr angepasster Prompt wurde gespeichert.»** warten.

> **Wichtig:** Beim Wechsel auf GPT-5 chat ging ein erster Speicherversuch in diesem Projekt **stillschweigend verloren**. Der Dialog schloss sich ohne Fehlermeldung, das Modell stand danach wieder auf dem alten Wert, und der Flow lieferte weiter die alten Ergebnisse. Nach jeder Änderung deshalb den Prompt neu öffnen und das Modell kontrollieren, danach einen echten Flow-Aufruf machen (Abschnitt 4.3).

Am Flow selbst ist **nichts** zu ändern. Er verweist auf den Prompt; die Umstellung wirkt sofort.

### 5.3 Verbrauch an Copilot-Guthaben prüfen

Im Prompt-Editor steht nach jedem Test rechts unten der Verbrauch des Laufs. Für die Umgebung insgesamt: Power Platform Admin Center, **Ressourcen → Kapazität**.

Faustzahl: rund **3 Guthaben pro Analyse** mit GPT-5 chat. Ein Wechsel auf GPT-4.1 mini senkt das auf etwa ein Zehntel, kostet aber spürbar an Qualität der Beschreibung.

### 5.4 Empfängeradresse ändern

1. Flow **«Problem-Melder - Absenden»** im klassischen Designer öffnen (`?v3=false`).
2. Aktion **«E-Mail senden (V2)»** aufklappen, Feld **«An»** anpassen.
3. Speichern und mit einem Testaufruf prüfen (Abschnitt 4.3).

Soll zusätzlich die Abteilung als Empfänger dienen, wäre eine Bedingung oder ein Schalter nötig. Das ist bewusst nicht gebaut, siehe `05_Entscheide_und_Verlauf.md`, Abschnitt 6.

### 5.5 Aufrufadresse eines Flows neu holen

Wird ein Trigger neu erstellt, ändert sich die Aufrufadresse und die Seite muss nachgeführt werden.

1. Flow im klassischen Designer öffnen, Trigger **«Beim Empfang einer HTTP-Anforderung»** aufklappen.
2. Rechts neben **HTTP-POST-URL** auf das Kopiersymbol klicken.
3. Adresse in `frontend\index.html` bei `FLOW_A_URL` beziehungsweise `FLOW_B_URL` eintragen.
4. Seite neu veröffentlichen (Abschnitt 5.1).

Die Adresse enthält eine Signatur (`sig=…`). Sie gehört **nicht** in Tickets, Mails oder Chats.

---

## 6. Grenzen und bekannte Schwächen

Diese Punkte sind bekannt und für einen Proof of Concept bewusst in Kauf genommen. Sie gehören ins Gespräch, bevor jemand sie für einen Fehler hält – und auf den Tisch, bevor das Tool in den Dauerbetrieb geht.

1. **Die Flows sind anonym aufrufbar, die Adressen stehen im Quelltext.** Wer die Seite öffnet und den Quelltext ansieht, hat beide Aufrufadressen. Damit lassen sich beliebig E-Mails an den Servicedesk auslösen und Analysen anstossen, die Copilot-Guthaben verbrauchen. Es gibt kein Rate-Limit, keine Anmeldung und keine Herkunftsprüfung. Für einen internen Versuch vertretbar, für den Dauerbetrieb zu entscheiden. Mögliche Gegenmittel: Seite nur intern erreichbar machen, gemeinsames Geheimnis im Kopf der Anfrage, oder Prüfung der Herkunft im Flow.
2. **Die E-Mail-Adresse wird nicht verifiziert.** Sie ist ein Freitextfeld. Wer sich vertippt, bekommt keine Rückfrage; wer eine fremde Adresse einträgt, meldet in fremdem Namen.
3. **Nur das erste Foto wird analysiert.** Die Vorschläge stammen immer vom ersten Bild, auch wenn sechs angehängt sind. Alle Bilder gehen mit der E-Mail.
4. **Es gibt keine Ablage und keine Ticketnummer.** Die einzige Spur ist die E-Mail; der Flow-Lauf verfällt nach 28 Tagen. Auswertungen, Statistiken oder ein Nachverfolgen des Bearbeitungsstands sind nicht möglich. Für Letzteres wäre eine Anbindung an Freshdesk der nächste Schritt.
5. **Kein Schutz gegen Doppelmeldungen.** Wer nach einer Fehlermeldung nochmals sendet, obwohl die erste doch ankam, erzeugt zwei E-Mails.
6. **Die Analyse kostet Geld.** Jeder Fotoschritt verbraucht Copilot-Guthaben, auch wenn die Meldung danach abgebrochen wird.
7. **Abhängigkeit von zwei fremden Adressen.** Logo und Favicon kommen von `www.campus-sursee.ch`, die Schrift von Google Fonts. Beide Ausfälle sind harmlos: Die Seite bleibt vollständig benutzbar, sie sieht nur anders aus.
8. **Versionsverwaltung erst seit dieser Ablage.** Der Verlauf beginnt mit dieser Git-Ablage; alles davor ist nicht nachvollziehbar. Wer weiterhin im Arbeitsverzeichnis `C:\Claude\problem-melder\` ändert, muss die Datei nach `frontend\` zurückspielen, sonst läuft der veröffentlichte Stand auseinander.
9. **Der Power-Automate-Designer ist unzuverlässig.** Der neue Designer konnte diesen Flow wiederholt nicht speichern, Ausdrucksfehler erscheinen als unsichtbare Browser-Dialoge, die die Seite einfrieren lassen, und ein Speichern kann still verloren gehen. Wer hier arbeitet, muss jede Änderung nachkontrollieren. Details in `03_Technische_Dokumentation.md`, Abschnitt 9.

---

## 7. Eskalation

### 7.1 Wenn nichts hilft

In dieser Reihenfolge vorgehen:

1. **Backend allein prüfen.** Beide Flows von Hand aufrufen, Abschnitt 4.3. Das trennt in einem Schritt Frontend von Backend.
2. **Ausführungsverlauf lesen.** Gibt es zum genannten Zeitpunkt überhaupt einen Lauf? Ist er grün oder rot? Das beantwortet die meisten Fragen.
3. **Zweites Gerät und zweites Netz.** Tritt der Fehler nur bei einer Person auf, liegt es am Gerät oder am Empfang, nicht am System.
4. **Auf den letzten funktionierenden Stand der Seite zurück.** Bei Netlify über den Deploy-Verlauf.
5. **Notbetrieb sicherstellen.** Das Melde-Tool ist eine Bequemlichkeit, kein kritischer Dienst. Fällt es aus, melden die Mitarbeitenden wie bisher per Telefon oder E-Mail an den Servicedesk. Das ist als Rückfallebene ausdrücklich vorgesehen.
6. **Ticket eröffnen** mit den Angaben aus 7.2.

### 7.2 Was ein Ticket enthalten muss

- **Zeitpunkt** mit Datum und Uhrzeit auf die Minute genau, damit sich der Flow-Lauf zuordnen lässt
- **E-Mail-Adresse der meldenden Person**, wie sie in Schritt 1 eingetragen war
- **Fehlermeldung im Wortlaut**, am besten als Bildschirmfoto der ganzen Seite
- **In welchem Schritt** es passiert ist: Kontakt, Fotos, Übersicht oder beim Absenden
- **Anzahl Fotos** und ob der Fotoschritt übersprungen wurde
- **Gerät und Browser**, zum Beispiel «iPhone, Safari» oder «Arbeitsplatz-PC, Edge»
- **Netz**: Campus-WLAN, Mobilfunk oder Gastnetz
- **Reproduzierbarkeit**: einmalig, bei jedem Versuch, nur bei einer Person
- Falls schon geprüft: Ergebnis des Testaufrufs aus Abschnitt 4.3

### 7.3 Wer wofür

| Fall | Nächste Stelle |
|---|---|
| Flows, Verbindungen, KI-Prompt, Guthaben | ICT-Services, Konto `powerplatform@campus-sursee.ch` |
| Outlook-Verbindung, Postfach, Regeln | Servicedesk |
| Webseite, Veröffentlichung, Adresse | ICT-Services |
| Logo oder Favicon fehlt | Betreuung von `www.campus-sursee.ch` |
| Störung bei Microsoft oder Netlify | fremder Dienst, Statusseite des Anbieters prüfen und abwarten |
| Inhaltliche Zuordnung einer Meldung | Servicedesk und die vier Abteilungen |
