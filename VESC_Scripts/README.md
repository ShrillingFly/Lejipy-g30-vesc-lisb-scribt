# Aktuelle Version: **Alpha 2.0** (stabil)

Die Datei `g30_dashboard_race.lisp` in diesem Ordner ist **immer die neueste
Alpha** – also die Version, die auf echter Hardware getestet ist und gut
läuft. Wenn du hier landest, kannst du die Datei ohne Nachdenken nehmen.

**Direkt holen:** [g30_dashboard_race.lisp](g30_dashboard_race.lisp) öffnen →
oben rechts auf **Raw** → alles kopieren → in VESC Tool unter
**VESC Dev Tools → Lisp** einfügen und hochladen.

## Was drin ist

- Zwei Profile: **Original** (eco/drive/sport) und **Race**, umschaltbar per
  Doppelklick am Power-Button bei gleichzeitig gehaltener Bremse + Gas.
- Alle Tuning-Werte (Speed, Strom, Watt, Field Weakening) stehen als Tabelle
  ganz oben im Script.
- Keine Alarmanlage – Lock ist eine reine Wegfahrsperre.
- Fehlercodes werden als echte Ninebot-G30-Codes angezeigt.

## Andere Versionen

Ältere Alphas/Betas und die aktuelle **Beta 3.0** (neue Features, noch nicht
auf der Straße getestet) liegen auf eigenen Branches – siehe
[CHANGELOG.md](../CHANGELOG.md) im Hauptordner. Dort ist jede Version verlinkt
und beschrieben, was neu ist und was behoben wurde.

Sobald eine Beta auf dem Roller getestet ist und läuft, wird sie zur neuen
Alpha und landet hier in diesem Ordner.
