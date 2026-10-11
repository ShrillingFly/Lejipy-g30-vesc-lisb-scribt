# Aktuelle Version: **Alpha 3.0** (stabil)

Die Datei `g30_dashboard_race.lisp` in diesem Ordner ist **immer die neueste
Alpha** – also die Version, die auf echter Hardware getestet ist und gut
läuft. Wenn du hier landest, kannst du die Datei ohne Nachdenken nehmen.

Alpha 3.0 ist die auf der Straße getestete **Beta 3.1**, Datei unverändert.

**Direkt holen:** [g30_dashboard_race.lisp](g30_dashboard_race.lisp) öffnen →
oben rechts auf **Raw** → alles kopieren → in VESC Tool unter
**VESC Dev Tools → Lisp** einfügen und hochladen.

## Was drin ist

- Zwei Profile: **Original** und **Race**, umschaltbar per Doppelklick am
  Power-Button bei gleichzeitig gehaltener Bremse + Gas.
- Original: Eco 15 km/h / 450 W, Drive 20 km/h / 650 W, Sport 22 km/h / 1000 W.
- **Frei konfigurierbare Anzeige** oben im Script: was im Stand und während der
  Fahrt angezeigt wird, getrennt für beide Profile – inklusive rot blinkender
  Anzeige im Fehlercode-Feld (z.B. Motortemperatur in Race).
- Alle Tuning-Werte als Tabelle oben im Script, Einstellungen nummeriert.
- Lock ist eine reine Wegfahrsperre, keine Alarmanlage.
- Fehlercodes werden als echte Ninebot-G30-Codes angezeigt.

## Andere Versionen

Neuere Features (Alarmanlage, neue Race-Werte, Überhitzungsschutz) stecken in
der aktuellen **Beta 3.5** und sind noch nicht getestet – siehe
[CHANGELOG.md](../CHANGELOG.md). Dort ist jede Version verlinkt und
beschrieben, was neu ist und was behoben wurde.

Sobald eine Beta auf dem Roller getestet ist und läuft, wird sie zur neuen
Alpha und landet hier in diesem Ordner.
