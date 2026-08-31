# Melde-Tool: Problem melden

Mitarbeitende am Campus Sursee melden Mängel und Schäden über eine Webseite. Sie fotografieren das Problem mit dem Handy, eine KI schlägt Titel, Beschreibung und zuständige Abteilung vor, und nach einer kurzen Kontrolle geht die Meldung als E-Mail an den Servicedesk.

**Stand dieser Ablage:** 28.08.2026
**Reifegrad:** Proof of Concept. Die Technik ist gebaut und durchgetestet, die Seite ist aber noch nicht veröffentlicht und noch nicht im Betrieb.

---

## Wo fange ich an

| Ich bin | Ich lese |
|---|---|
| Mitarbeiterin oder Mitarbeiter und will ein Problem melden | `anleitung/01_Anleitung_Melden.md` |
| beim Servicedesk und bekomme diese Meldungen | `anleitung/01_Anleitung_Melden.md`, Abschnitt 5 |
| bei den ICT-Services und habe eine Störung | `anleitung/02_Betriebshandbuch_Support.md` |
| bei den ICT-Services und will verstehen, wie es gebaut ist | `anleitung/03_Technische_Dokumentation.md` |
| dabei, es aufzuschalten oder etwas zu ändern | `anleitung/04_Einrichtung_und_Deployment.md` |
| neu im Projekt und frage mich, warum es so ist | `anleitung/05_Entscheide_und_Verlauf.md` |

---

## Was hier liegt

```
Melde-Tool\
├── README.md                             dieses Dokument
├── netlify.toml                          Veröffentlichung: liefert "frontend" aus
├── frontend\
│   └── index.html                        die ganze Webseite, eine einzige Datei
├── code\
│   └── serve.ps1                         kleiner Server zum lokalen Testen
└── anleitung\
    ├── 01_Anleitung_Melden.md            Bedienung, für Meldende und Servicedesk
    ├── 02_Betriebshandbuch_Support.md    Störungsbehebung, für die ICT
    ├── 03_Technische_Dokumentation.md    Architektur, Flows, KI-Prompt, Schnittstellen
    ├── 04_Einrichtung_und_Deployment.md  aufschalten, ändern, von Null aufbauen
    ├── 05_Entscheide_und_Verlauf.md      warum es so gebaut ist, was offen ist
    └── 06_Quellcode_Hinweise.md          Hinweise für alle, die den Code ändern
```

---

## In drei Sätzen, wie es funktioniert

Die Webseite ist eine einzige HTML-Datei ohne Server und ohne Datenbank; sie soll bei Netlify liegen wie schon die Menüwahl, ausgeliefert wird der Ordner `frontend\` gemäss `netlify.toml`. Die Fotos gehen an einen Power-Automate-Flow, der sie von der KI im Power-Platform-KI-Hub (Modell GPT-5 chat) beschreiben und einer Abteilung zuordnen lässt; das Ergebnis füllt das Formular vor. Beim Absenden schickt ein zweiter Flow alles als E-Mail mit den Fotos im Anhang an `servicedesk@campus-sursee.ch`.

---

## Die vier Abteilungen

Jede Meldung wird genau einer dieser vier Stellen zugeordnet. Die KI schlägt vor, die meldende Person kann korrigieren.

| Abteilung | Wofür |
|---|---|
| Umgebungsdienst | Aussenanlagen, Grün, Reinigung |
| Technischer Dienst | Gebäude, Haustechnik, Reparaturen |
| ICT-Servicedesk | Computer, Netzwerk, Software |
| Seminarsupport | Räume, Medientechnik, Anlässe |

---

## Zuständigkeiten

| Bereich | Konto |
|---|---|
| Power Automate Flows | powerplatform@campus-sursee.ch |
| KI-Prompt im KI-Hub, Copilot-Guthaben | powerplatform@campus-sursee.ch |
| Outlook-Verbindung, Versand der Meldungen | servicedesk@campus-sursee.ch |
| Webseite und Veröffentlichung | ICT-Services |
| Bearbeitung der eingehenden Meldungen | die vier Abteilungen, Eingang beim Servicedesk |

Zugangsdaten und die Aufrufadressen der Flows samt Signatur stehen bewusst **nicht** in diesen Dokumenten. Sie stehen im Quelltext der Seite (`frontend\index.html`, ganz oben im `<script>`) und in Power Automate.

---

## Was vor dem Betrieb noch zu klären ist

Der Reihe nach in `anleitung/04_Einrichtung_und_Deployment.md`, Abschnitt 5. In Kürze:

1. **Adresse festlegen und aufschalten.** Die Seite liegt noch nirgends. Ohne Adresse gibt es nichts zu verteilen.
2. **Missbrauch bedenken.** Die beiden Flows sind anonym aufrufbar, die Adressen stehen im Quelltext jeder ausgelieferten Seite. Wer sie ausliest, kann E-Mails an den Servicedesk auslösen. Für einen Proof of Concept vertretbar, vor dem Dauerbetrieb zu entscheiden. Siehe `anleitung/05_Entscheide_und_Verlauf.md`, Abschnitt 8.
3. **Kosten im Auge behalten.** Jede Fotoanalyse verbraucht rund 3 Copilot-Guthaben.
