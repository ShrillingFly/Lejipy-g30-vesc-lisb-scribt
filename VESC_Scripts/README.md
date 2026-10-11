# ⚠ Dieser Branch: **Beta 3.5** – NICHT die Alpha

Die Datei `g30_dashboard_race.lisp` in **diesem Branch** ist die Beta 3.5:
neue Features, **noch nicht auf der Straße getestet**.
(Beta 3.5: Race Drive 60 km/h / 5 kW, Sport 80 km/h / 10 kW, Eco volle Leistung mit 35 A Field Weakening.)

**Du willst die stabile Version?** Dann hier entlang:
[VESC_Scripts auf `main`](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/tree/main/VESC_Scripts)
– dort liegt immer die neueste Alpha.

## Was in Beta 3.5 neu ist

- Die Dashboard-Anzeige ist frei konfigurierbar (oben im Script): getrennt
  einstellbar, was **im Stand** und **während der Fahrt** angezeigt wird,
  jeweils für Normal- und Race-Profil.
- Zusätzlich das Fehlercode-Feld als **rot blinkende** Anzeige nutzbar
  (z.B. Motortemperatur während der Fahrt). Ein echter VESC-Fehler hat dort
  immer Vorrang und kann nie verdeckt werden.
- Normal-Profil neu: Eco 15 km/h / 450 W, Drive 20 km/h / 650 W,
  Sport 22 km/h / 1000 W.
- **Überhitzungsschutz**: ab 110 °C Motortemperatur nur noch Drive, bis er
  unter 100 °C abgekühlt ist.
- **Alarmanlage**: piept und blinkt ~10 s, wenn der ausgeschaltete Roller
  bewegt wird. An/aus über `alarm-enabled` oben im Skript.

Details siehe [CHANGELOG.md](../CHANGELOG.md).

Wenn diese Beta getestet ist und gut läuft, wird sie zur neuen Alpha und
landet auf `main`.
