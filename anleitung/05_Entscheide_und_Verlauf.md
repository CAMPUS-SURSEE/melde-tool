# Entscheide und Verlauf

**Stand:** 28.08.2026

Warum das Melde-Tool so gebaut ist, wie es gebaut ist. Dieses Dokument beantwortet die Fragen, die sich sonst in einem Jahr niemand mehr beantworten kann.

---

## 1. Warum überhaupt

Wer am Campus einen Mangel entdeckt – eine defekte Lampe, einen Drucker mit Fehlermeldung, einen kaputten Stuhl im Seminarraum – meldet ihn heute per Telefon oder E-Mail an den Servicedesk. Das hat zwei Nachteile: Es dauert, und die Meldung ist oft unvollständig. Was genau ist kaputt, wo steht es, wer ist zuständig?

Das Melde-Tool dreht den Ablauf um. Statt zu beschreiben, fotografiert man. Die KI erledigt den beschreibenden Teil und schlägt gleich die zuständige Abteilung vor. Die meldende Person kontrolliert nur noch und tippt auf «Absenden».

Der Anspruch war ausdrücklich: **so simpel und selbsterklärend wie möglich**. Keine Anleitung nötig, keine Schulung, keine App.

---

## 2. Warum keine Anmeldung

Die Anwendung soll von jedem Mitarbeitenden im Vorbeigehen benutzbar sein, mit dem Handy in der Hand, ohne vorher etwas einzurichten. Eine Anmeldung wäre genau die Hürde, die den Zweck zunichtemacht: Wer sich erst einloggen muss, ruft doch wieder an.

Stattdessen genügt die E-Mail-Adresse, und die muss man nur einmal eingeben. Sie liegt danach im `localStorage` des Browsers, und die Seite startet beim nächsten Mal direkt beim Fotoschritt.

**Was das bedeutet:** Es gibt keinen Nachweis, wer wirklich gemeldet hat, und die Adresse wird nicht geprüft. Für Mängelmeldungen ist das vertretbar. Für den Preis hat man einen Meldeweg, der zehn Sekunden dauert.

**Was es auch bedeutet:** Die Flows müssen anonym aufrufbar sein. Das ist der Ursprung der Schwäche in Abschnitt 8, Punkt 1.

---

## 3. Warum die KI und nicht ein Formular

Ein reines Formular hätte auch funktioniert. Die KI ist der eigentliche Gewinn, aus drei Gründen:

1. **Die Beschreibung entsteht von selbst.** Wer knapp fotografiert und auf «Weiter» tippt, hat schon Titel und Beschreibung. Das ist der Unterschied zwischen «mach ich später» und «ist erledigt».
2. **Die Zuordnung zur Abteilung ist die eigentliche Arbeit.** Bisher hat der Servicedesk jede Meldung gelesen und weitergeleitet. Der Vorschlag nimmt diesen Schritt vorweg.
3. **Es ist ein KI-Projekt.** Die Ablage heisst «KI-Projekte». Der Nutzen sollte hier sichtbar sein, nicht bloss behauptet.

**Die KI entscheidet aber nichts.** Sie füllt nur Felder vor. Die meldende Person sieht jeden Vorschlag und kann ihn ändern; die Abteilung ist ein Auswahlfeld, kein Automatismus. Wenn die Analyse nichts liefert, funktioniert die ganze Anwendung unverändert weiter, nur eben von Hand. Das war eine Bedingung an den Aufbau: **Die KI darf ein Zusatz sein, nie eine Voraussetzung.**

---

## 4. Warum keine Datenbank und keine Ablage

Naheliegend wäre eine SharePoint-Liste gewesen, wie bei der Menüwahl. Bewusst nicht gebaut:

- **Die E-Mail ist die Meldung.** Der Servicedesk arbeitet ohnehin im Postfach. Eine zweite Ablage, in die niemand schaut, hilft niemandem.
- **Weniger Teile, weniger Störungen.** Ohne Liste gibt es keine Berechtigungen, keine Feldnamen, keine Aufräum-Flows und keinen Zeitzonenärger mit Datumsspalten – lauter Dinge, die bei der Menüwahl Zeit gekostet haben.
- **Für einen Proof of Concept genügt es.** Braucht es später Auswertungen oder eine Nachverfolgung, ist der richtige Ort nicht SharePoint, sondern Freshdesk. Siehe Abschnitt 8.

**Der Preis:** Es gibt keine Statistik, keinen Bearbeitungsstand und keine Ticketnummer. Der Flow-Lauf verfällt nach 28 Tagen, danach ist die E-Mail die einzige Spur.

---

## 5. Warum die Meldungen vom Servicedesk an den Servicedesk gehen

Ursprünglich sollte der Versand über das Betriebskonto `powerplatform@campus-sursee.ch` laufen, dasselbe Konto, das schon die Menüwahl-Flows betreibt.

Das ging nicht. Dieses Konto hat kein nutzbares Exchange-Postfach. Alle damit erstellten Outlook-Verbindungen wurden im Power-Automate-Designer dauerhaft als «Ungültige Verbindung» geführt, und der Flow liess sich schlicht nicht speichern. Erst die vorhandene Verbindung des Kontos **`servicedesk@campus-sursee.ch`** funktionierte – erkennbar daran, dass das Feld «An» plötzlich Adressen zu Kontakten auflöste.

**Folge:** Die Meldungen kommen vom Servicedesk-Postfach an sich selbst. Die meldende Person steht nicht im Absenderfeld, sondern im Text unter «Gemeldet von». Wer antworten will, muss diese Adresse verwenden statt «Antworten» zu drücken. Inhaltlich passt es, weil die Meldungen ohnehin dort landen sollen; es ist trotzdem eine Eigenheit, die man kennen muss.

---

## 6. Warum eine feste Empfängeradresse statt vier

Die Abteilung steht im Betreff, es wäre also naheliegend, gleich an die zuständige Stelle zu schicken. Bewusst nicht gebaut:

- Die Zuordnung ist ein KI-Vorschlag. Direkt zustellen hiesse, einer Maschine die Verteilung zu überlassen, ohne dass jemand gegenliest.
- Der Servicedesk ist die etablierte Anlaufstelle und behält so den Überblick.
- Der Betreff enthält die Abteilung im Klartext. Wer automatisch sortieren will, macht das mit einer Outlook-Regel und kann sie jederzeit ändern – ohne den Flow anzufassen.

---

## 7. Weitere Entscheide, kurz begründet

**Radio-Felder statt Auswahlliste für die Abteilung.** Auf Wunsch geändert. Vier Optionen sind auf dem Handy als antippbare Karten schneller und zeigen zugleich die Zuständigkeit im Klartext.

**E-Mail in Schritt 3 nur als Text mit «Ändern»-Link.** Ein zweites Eingabefeld für dieselbe Adresse verwirrt und macht zwei Quellen daraus. Jetzt gibt es genau ein Feld, in Schritt 1.

**Bilder im Browser verkleinern.** Ein Handyfoto hat schnell fünf Megabyte. Sechs davon über Mobilfunk wären der sichere Weg in die Zeitüberschreitung. 1600 Pixel längste Kante bei JPEG-Qualität 0.8 reichen sowohl für die KI als auch für den Servicedesk.

**Nur das erste Foto analysieren.** Jede Analyse kostet Guthaben und Zeit. Der Zusatznutzen eines zweiten Bildes ist klein, die Kosten verdoppeln sich. Alle Bilder gehen trotzdem mit der Meldung.

**Höchstens sechs Fotos.** Willkürlich, aber praktisch: genug für jeden realen Fall, wenig genug, dass die Übertragung im Mobilfunk gelingt.

**30 Sekunden Zeitlimit für beide Aufrufe.** Lange genug für die Analyse (normal rund 4 Sekunden), kurz genug, dass niemand ratlos auf einen hängenden Bildschirm starrt.

**`application/json` statt `text/plain`.** Ursprünglich war `text/plain` geplant, um den CORS-Preflight zu vermeiden. Beim Testen stellte sich zweierlei heraus: Der Trigger nimmt gar keinen reinen Text an, und das Power-Platform-Gateway beantwortet den Preflight ohnehin selbst mit `Access-Control-Allow-Origin: *`. Der Umweg war also unnötig und hätte gar nicht funktioniert.

**Rein weiss, keine Schatten, kein Kopf- und Fussbereich.** Auf Wunsch. Die Anwendung soll wie ein Ablauf wirken und nicht wie eine Webseite: eine mittig stehende Karte, viel Weissraum, ruhige Übergänge.

**Logo und Favicon direkt von `campus-sursee.ch`.** Ausdrücklich so gewünscht: keine kopierte Datei, die irgendwann veraltet. Der Preis ist die Abhängigkeit von dieser Adresse; fällt sie aus, fehlt nur das Bild.

**«Proof of Concept» als schlichter roter Text.** Zuerst als Pille mit Rahmen und pulsierendem Punkt gebaut, auf Rückmeldung hin zu reinem Text vereinfacht. Der Hinweis soll da sein, aber nicht wichtiger wirken als der Inhalt.

---

## 8. Bekannte Schwächen

Diese Punkte sind bekannt und für einen Proof of Concept bewusst in Kauf genommen. Sie gehören auf den Tisch, bevor das Tool offiziell wird.

| Schwäche | Auswirkung | Möglicher Ausbau |
|---|---|---|
| Flows anonym aufrufbar, Adressen im Quelltext | Wer sie ausliest, kann E-Mails an den Servicedesk auslösen und Guthaben verbrauchen | Seite intern halten, gemeinsames Geheimnis prüfen, oder Anmeldung wie bei der Menüwahl |
| Kein Rate-Limit | Ein Skript könnte das Postfach fluten | Zähler im Flow, oder Prüfung der Herkunft |
| E-Mail-Adresse wird nicht verifiziert | Meldung in fremdem Namen möglich, Tippfehler bleiben unbemerkt | Anmeldung, oder Abgleich gegen das Verzeichnis |
| Keine Ablage, keine Ticketnummer | Keine Auswertung, kein Bearbeitungsstand, nach 28 Tagen nur noch die E-Mail | Anbindung an Freshdesk |
| Nur das erste Foto wird analysiert | Vorschläge können am eigentlichen Problem vorbeigehen | Mehrere Bilder analysieren, kostet entsprechend mehr |
| Keine Rückmeldung an die meldende Person | Sie erfährt nicht, ob und wann etwas passiert | Bestätigungsmail, oder Ticketsystem |
| Kein Schutz gegen Doppelmeldungen | Zwei E-Mails nach einem Fehlversuch, der doch durchkam | Kennung je Meldung mitschicken und im Flow prüfen |
| Analyse kostet Guthaben | Auch abgebrochene Meldungen kosten | Günstigeres Modell, oder Analyse erst beim Absenden |
| Keine Versionsverwaltung | Kein Rückschritt ausser über den Deploy-Verlauf | Git-Anbindung |

---

## 9. Verlauf

| Datum | Was |
|---|---|
| 27.08.2026, Vormittag | Auftrag und Plan: eine HTML-Seite, zwei Power-Automate-Flows. Flow A angelegt, zunächst mit Platzhalter-Antwort. Erster Versuch mit der AI-Builder-Bildanalyse scheitert an der fehlenden Dataverse-Verbindung |
| 27.08.2026, Mittag | Sitzungsabbruch. Flow B ging ungespeichert verloren |
| 28.08.2026, Vormittag | Wiederaufnahme. Frontend gebaut, Flow B neu aufgebaut und nach mehreren Anläufen im klassischen Designer gespeichert. Erster erfolgreicher End-to-End-Test des Versands |
| 28.08.2026, Mittag | Redesign auf Wunsch: rein weiss, minimalistisch, vertikal zentriert, Radio-Felder statt Auswahlliste, E-Mail im `localStorage`, Campus-Logo direkt von der Hauptseite |
| 28.08.2026, Nachmittag | KI-Analyse fertiggestellt: Prompt im KI-Hub angelegt, Bildübergabe-Problem gelöst, Flow A vollständig. Erster erfolgreicher Analyselauf |
| 28.08.2026, später Nachmittag | Modellwechsel von GPT-4.1 mini auf GPT-5 chat. Feinschliff am Design: Schatten entfernt, Proof-of-Concept-Hinweis vereinfacht, Fusszeile entfernt |
| 28.08.2026, Abend | Diese Dokumentation |

**Beim Bau gefundene und gelöste Probleme**, festgehalten, weil sie sich wiederholen könnten:

- **Bildübergabe an den AI Builder.** Weder nacktes Base64 noch eine `data:`-URI werden angenommen. Nötig ist ein Dateiobjekt in der Form `{"$content-type":…,"$content":…}`. Der Fehlertext «Image url cannot be accessed» führt in die Irre. Zwei Fehlversuche.
- **Trigger nimmt kein `text/plain`.** Antwort: `TriggerInputSchemaMismatch … Expected Object but got String`.
- **Der neue Power-Automate-Designer speicherte nicht.** Er meldete hartnäckig eine unterbrochene Verbindung, während die Verbindungsübersicht alles als verbunden auswies. Der klassische Designer (`?v3=false`) speicherte anstandslos.
- **Outlook-Verbindung mit dem powerplatform-Konto unbrauchbar**, weil dieses Konto kein Postfach hat. Siehe Abschnitt 5.
- **Unsichtbare Browser-Dialoge.** «Dieser Ausdruck ist ungültig» erscheint als nativer Dialog, den eine Automation nicht sieht. Die Seite wirkt eingefroren, ohne dass ein Grund erkennbar wäre.
- **Ein Speichern ging still verloren.** Beim Modellwechsel auf GPT-5 chat schloss sich der Dialog ohne Fehlermeldung, das Modell stand danach wieder auf dem alten Wert, und der Flow lieferte weiterhin die alte Antwort – Wort für Wort dieselbe, was den Verdacht überhaupt erst weckte. Erst der zweite Anlauf griff.
- **OAuth-Fenster öffnen nur im Vordergrund.** Aus einem Hintergrund-Tab heraus hängt die Anzeige endlos bei «Anmeldung wird ausgeführt…».
- **«Flow wiederherstellen» rettet ungespeicherte Stände.** Nach einem Neuladen bietet der Designer den Zwischenstand aus dem Browser an. Das hat mehrfach die Arbeit gerettet – und war die Lehre aus dem verlorenen ersten Flow B.

---

## 10. Was geprüft wurde und was nicht

**Geprüft:**

- **Flow B end-to-end**, mehrfach: HTTP 200 mit `{"ok":true}`, E-Mail im Postfach des Servicedesk mit korrektem Betreff, Text und Foto im Anhang.
- **Flow A end-to-end** mit einem eigens erzeugten Testbild (Drucker mit der Fehlermeldung «ERROR: PAPER JAM», Raumangabe «Buero B2.14»). Ergebnis mit GPT-5 chat: Titel «Drucker mit Papierstau», passende Beschreibung, Abteilung «ICT-Servicedesk». Laufzeit rund 4 Sekunden.
- **Verhalten ohne erkennbares Problem**: Ein Landschaftsbild ergibt leere Felder; die Seite geht mit dem Hinweis «Automatische Analyse nicht verfügbar» weiter. Genau so gewollt.
- **CORS-Preflight** mit einer `OPTIONS`-Anfrage: HTTP 204 mit `Access-Control-Allow-Origin: *`.
- **Fehlerfall `text/plain`**: HTTP 400 mit `TriggerInputSchemaMismatch`, wie erwartet.
- **Die Oberfläche im Browser**, vollständig durchgeklickt: alle drei Schritte, Radio-Auswahl, «Ändern»-Link bei der E-Mail, Absenden bis zur Bestätigung, Neustart der Seite mit gemerkter Adresse direkt auf Schritt 2.
- **Der Modellwechsel** über einen echten Flow-Aufruf gegengeprüft, nicht nur über die Anzeige im Editor.

**Nicht geprüft, offen:**

- **Die Seite auf einem echten Handy.** Kamerazugriff, Ausrichtung der Fotos und Verhalten der HEIC-Umwandlung auf dem iPhone sind ungetestet. Das geht erst nach dem Aufschalten über `https://`, weil Browser den Kamerazugriff sonst sperren.
- **Der Betrieb unter Last.** Wie sich viele gleichzeitige Meldungen auf Laufzeit und Guthaben auswirken, ist unbekannt.
- **Echte Fotos vom Campus.** Getestet wurde mit einem gezeichneten Bild und einem Standardhintergrund. Wie gut die Zuordnung bei realen Mängeln trifft, zeigt erst der Betrieb.
- **Das Verhalten bei sehr grossen Meldungen**, also sechs Fotos über Mobilfunk. Das Zeitlimit von 30 Sekunden könnte dort knapp werden.

> Ein Hinweis zur Redlichkeit: Ein Testlauf hat zunächst ein scheinbar korrektes Ergebnis geliefert, obwohl der Modellwechsel gar nicht gespeichert worden war. Aufgefallen ist es nur, weil die Antwort **wortgleich** mit der vorherigen war. Wer künftig am Prompt etwas ändert, prüft das Ergebnis nicht am Text allein, sondern kontrolliert im Prompt-Editor auch das eingestellte Modell.
