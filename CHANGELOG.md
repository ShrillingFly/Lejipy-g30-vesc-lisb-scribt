# Changelog

Jede Version liegt als eigener Branch im Repo, mit dem exakten Skript-Stand von
damals. **Auf `main` liegt immer die neueste Alpha** – also die getestete,
empfohlene Version.

| Version | Status | Kurz |
|---|---|---|
| [**Beta 3.1**](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/beta-3.1/VESC_Scripts/g30_dashboard_race.lisp) | zum Testen | wie 3.0, nur aufgeräumt: Skript 155 Zeilen kürzer |
| [Beta 3.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/beta-3.0/VESC_Scripts/g30_dashboard_race.lisp) | ersetzt durch 3.1 | frei konfigurierbare Anzeige, neue Normal-Werte |
| [**Alpha 2.0**](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/alpha-2.0/VESC_Scripts/g30_dashboard_race.lisp) | **stabil, auf `main`** | bewährter Stand, läuft auf echter Hardware |
| [Release 1.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/release-1.0/VESC_Scripts/g30_dashboard_race.lisp) | Vorgänger | Tuning-Werte als Tabelle oben im Skript |
| [Beta 2.1](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-2.1/VESC_Scripts/g30_dashboard_race.lisp) | alt | Geräusch-Fix am Speed-Limit |
| [Beta 2.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-2.0/VESC_Scripts/g30_dashboard_race.lisp) | alt | 20A Field Weakening in Race-Eco |
| [Beta 1.4](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.4/VESC_Scripts/g30_dashboard_race.lisp) | alt | robustes Button-Debounce |
| [Beta 1.3](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.3/VESC_Scripts/g30_dashboard_race.lisp) | alt | Motortemp-Anzeige, Button-Fix |
| [Beta 1.2](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.2/VESC_Scripts/g30_dashboard_race.lisp) | alt | Alarmanlage entfernt |
| [Beta 1.1](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.1/VESC_Scripts/g30_dashboard_race.lisp) | alt | Race geöffnet, Ninebot-Fehlercodes |
| [Beta 1.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.0/VESC_Scripts/g30_dashboard_race.lisp) | alt | erste Hardware-Fixes |
| [Alpha 1.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/alpha-1.0/VESC_Scripts/g30_dashboard_race.lisp) | alt | erste Version |

## So holst du dir eine bestimmte Version

Jeder Versionsname – in der Tabelle oben wie in den Abschnitten unten – ist
ein Link, der direkt die passende `g30_dashboard_race.lisp` öffnet. Von dort:

1. Auf den Versionsnamen klicken - die Skript-Datei geht auf.
2. Oben rechts über dem Code auf **Raw** (bzw. das Download-Symbol) klicken.
   Dann steht der reine Text da, ohne GitHub-Drumherum.
3. Alles markieren und kopieren (Strg+A, Strg+C), oder die Seite als Datei
   speichern.
4. In VESC Tool: Tab **VESC Dev Tools → Lisp** öffnen, den alten Inhalt
   löschen, den neuen Code einfügen und auf **Upload** klicken.

Alternativ das ganze Repo auf einmal holen:

```
git clone https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt
```

Danach mit `git checkout beta-3.1` bzw. `git checkout history/beta-1.2`
zwischen den Versionen wechseln (`git branch -a` zeigt alle).

## [Beta 3.1](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/beta-3.1/VESC_Scripts/g30_dashboard_race.lisp) - aufgeräumt (ungetestet)

Gleiche Funktionen wie Beta 3.0, nur übersichtlicher gemacht. **Am Verhalten
ändert sich nichts** – geprüft: der Code ist Zeile für Zeile identisch mit
Beta 3.0, geändert wurden ausschließlich Kommentare.

**Aufgeräumt:**
- Der lange Versions-Changelog steht nicht mehr im Skript selbst (er steht ja
  hier) – das Skript ist dadurch **741 → 586 Zeilen** kurz.
- Die Erklärung zur Anzeige-Konfiguration von 20 auf 11 Zeilen eingedampft.
- Die Einstellungs-Abschnitte sind jetzt nummeriert: **1) Fahrmodi**,
  **2) Anzeige**, **3) Hardware/Tuning**. Alle Einstellungen passen damit auf
  etwa eine Bildschirmseite.

## [Beta 3.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/beta-3.0/VESC_Scripts/g30_dashboard_race.lisp) - frei konfigurierbare Anzeige (ungetestet)

**Neu:**
- Das Dashboard lässt sich jetzt komplett oben im Script konfigurieren. Zwei
  Felder können unabhängig belegt werden:
  - **MAIN** - die große Zahl in der Mitte (normalerweise die Geschwindigkeit).
  - **BLINK** - das Fehlercode-Feld. Alles ungleich 0 erscheint dort als **rot
    blinkende Zahl**. Der Trick stammt aus Sharkboys G30-Script, das darüber
    die Controller-Temperatur während der Fahrt anzeigt.
- Pro Feld gibt es vier Slots: **im Stand** und **während der Fahrt**, jeweils
  getrennt für Normal- und Race-Profil. Jeder Slot nimmt einen Code:
  `0` km/h, `1` Akku %, `2` Motortemperatur, `3` Controller-/FET-Temperatur,
  `4` Tageskilometer, `5` Zellspannung (x10), `6` aus.
- **Standardbelegung:** Normal zeigt immer km/h, nichts blinkt. Race zeigt im
  Stand den Akku, während der Fahrt km/h, und blinkt dabei die Motortemperatur
  rot (`blink-race-ride` auf `6` setzen, um das abzuschalten).
- Ersetzt den festen `show-mot-temp-in-idle`-Schalter aus Beta 1.3.

**Geändert:**
- Normal-Profil neu abgestimmt: Eco 15 km/h / 450 W, Drive 20 km/h / 650 W,
  Sport 22 km/h / 1000 W. Race-Profil unverändert.

**Sicherheit:**
- Ein echter VESC-Fehler hat im Blink-Feld immer Vorrang und wird weiterhin als
  Ninebot-G30-Fehlercode angezeigt - eine konfigurierte Anzeige kann also nie
  einen echten Fehler verdecken.
- Angezeigte Werte werden auf 0-255 begrenzt, bevor sie ins Frame geschrieben
  werden (ein Feld ist nur ein Byte; Minusgrade oder über 255 km würden sonst
  überlaufen).

## [Alpha 2.0 (Stabil)](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/alpha-2.0/VESC_Scripts/g30_dashboard_race.lisp) - bewährter Stand

Inhaltlich identisch mit `Release 1.0` - als bewusster Rückfall-Punkt markiert,
weil diese Version auf echter Hardware gut funktioniert. Das ist der Stand, der
auf `main` liegt.

## [Release 1.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/release-1.0/VESC_Scripts/g30_dashboard_race.lisp)

**Neu:**
- Alle Tuning-Werte (Original- und Race-Profil: Speed/Strom/Watt/Field Weakening)
  als übersichtliche Tabelle ganz oben im Script - eine Zeile pro Modus statt
  vieler Einzelzeilen.
- Ausführlicher Versions-Changelog ans Dateiende verschoben, damit die
  Einstellwerte direkt nach dem Kopf sichtbar sind.

Keine Verhaltensänderung - reine Struktur/Lesbarkeit.

## [Beta 2.1](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-2.1/VESC_Scripts/g30_dashboard_race.lisp) - Geräusch-Fix am Speed-Limit

**Behoben:**
- Komische/singende Geräusche beim Erreichen des Speed-Limits, sowohl im
  Original- als auch im Race-Drive/Sport-Modus. VESCs Geschwindigkeits-Governor
  fängt erst spät an, den Strom zu reduzieren (Standard: `l-erpm-start` = 0.8,
  also erst bei 80% vom Limit) - das führt bei wenig Drehzahlreserve (kein
  Field Weakening) zu einem abrupten, hörbaren Eingriff. Auf 0.5 gesenkt für
  einen früheren, sanfteren Übergang.

## [Beta 2.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-2.0/VESC_Scripts/g30_dashboard_race.lisp) - Field Weakening in Race-Eco

**Neu:**
- 20A Field Weakening in Race-Eco aktiviert (lässt den Motor über seine normale
  Back-EMF-Grenze hinaus drehen, um das weit offene Speed-Limit überhaupt
  erreichen zu können).
- Race-Drive und Race-Sport bleiben bewusst ohne Field Weakening.

## [Beta 1.4](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.4/VESC_Scripts/g30_dashboard_race.lisp) - Robustes Button-Debounce

**Behoben:**
- Button-Pin wird jetzt per 3-fach-Mehrheitsentscheid über 60ms gelesen (statt
  einmal lesen + einmal 30ms später bestätigen). Verhindert Phantom-Presses
  (z.B. ging das Licht beim harten Bremsen von selbst an), verursacht durch
  Störungen auf der Button-Leitung, die sich physisch die Leitung mit der
  UART-Kommunikation teilt - besonders bei hohem Bremsstrom ohne Field
  Weakening. Entspricht dem Fix, den das Upstream-Projekt
  (m365fw/vesc_m365_dash) für genau dasselbe Problem übernommen hat.

## [Beta 1.3](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.3/VESC_Scripts/g30_dashboard_race.lisp) - Motortemp-Anzeige + Button-Fix

**Neu:**
- Anzeige im Stillstand (nur Race-Modus) zeigt jetzt Motortemperatur statt
  Batterie-Prozent. Der zuvor gemeldete "b3"-Fehler war höchstwahrscheinlich
  einfach die Batterie-% (z.B. "63%"), auf dem Display-Font als "b3" gelesen.

**Behoben:**
- Button-Presses werden nur noch gezählt, während das Board wirklich steht.
  Vorher konnte ein Signal während des Auslaufens/Bremsens einen ungewollten
  Mode- oder Lock-Wechsel auslösen, sobald das Rad zum Stillstand kam.

## [Beta 1.2](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.2/VESC_Scripts/g30_dashboard_race.lisp) - Alarmanlage entfernt

**Entfernt:**
- Komplette Alarm-/Diebstahlschutz-Logik: Gyro-Bewegungserkennung, Sirenen-Töne,
  erzwungene Vollbremsung beim Sperren.
- Lock ist jetzt nur noch eine reine Wegfahrsperre (Gas wird gekappt), ohne
  Sound oder Bewegungsmelder.

## [Beta 1.1](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.1/VESC_Scripts/g30_dashboard_race.lisp) - Race geöffnet + Ninebot-Fehlercodes

**Neu:**
- Race-Watt-Deckel wieder auf 100.000 W geöffnet (echte Leistung kommt vom
  Gashebel, nicht vom Watt-Limit - das war unnötig konservativ).
- Fehlercode-Anzeige am Dashboard von rohen VESC-internen Codes auf eine
  Best-Effort-Zuordnung zu echten Ninebot-G30-Fehlercodes umgestellt, damit am
  Display etwas Nachschlagbares steht statt eines kryptischen VESC-Codes.

## [Beta 1.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/beta-1.0/VESC_Scripts/g30_dashboard_race.lisp) - Erste Hardware-Fixes

**Behoben:**
- ADC-Schwellen für Bremse/Gas-Erkennung von 0.1V auf 0.3V angehoben. Bei 0.1V
  reichte minimales ADC-Rauschen, damit die Button-Logik dachte, die Bremse
  sei ständig gehalten - dadurch landete jeder Doppelklick im Lock/Race-Toggle
  statt jemals durch Eco/Drive/Sport zu schalten.
- Unrealistische Race-Werte (1.500.000 W, 999 km/h) auf 20.000 W / 80 km/h
  reduziert. Ein physikalisch unerreichbares Ziel ließ den Regelkreis auf
  Dauer-Vollgas hängen, vermutliche Ursache für den "b3"-Fault (DRV) am
  Display.

**Neu:**
- Fault-Code-Ausgabe im VESC-Tool-Terminal zum Debuggen.

## [Alpha 1.0](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/history/alpha-1.0/VESC_Scripts/g30_dashboard_race.lisp) - Erste Version

**Neu:**
- Custom G30-Dashboard-Script mit zwei Profilen: Original (Stock
  eco/drive/sport, unverändert) und Race (eigene Werte für eco/drive/sport).
- Umschalten zwischen den Profilen per Doppelklick am Power-Button, während
  Bremse UND Gashebel gleichzeitig gehalten werden.

Status: ungetestet auf echter Hardware.
