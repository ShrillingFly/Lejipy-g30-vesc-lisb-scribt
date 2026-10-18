# G30 Dashboard Race

Betreibt das originale **Ninebot G30 Display** an einem VESC-Controller –
mit zwei umschaltbaren Profilen **Original** und **Race**. Alle Einstellungen
werden in der **App UI** von VESC Tool geändert, ohne Code anzufassen.

Getestet mit VESC 7.00 auf einem Spintend Ubox Single 85 200 mit 72V-Akku.

## Installation

1. VESC Tool öffnen und mit dem VESC verbinden (USB, Bluetooth oder WLAN).
2. **VESC Packages → Load Custom** → `g30_dashboard_race.vescpkg` auswählen
   → **Install**.
3. **App UI** öffnen, Werte prüfen, **Speichern**.
4. Die ADC-App einrichten (siehe unten).

## ADC Setup

- **App Settings → General**: **APP to Use** auf `ADC`, dann **Write**
- **App Settings → ADC → General**: **Control Type** `Current`,
  **Use Filter** `True`, **Safe Start** `Regular`, **Update Rate** `1000 Hz`
- **App Settings → ADC → Mapping**: **ADC Mapping** öffnen, Gas und Bremse
  einmal komplett durchziehen, dann **Apply and Write**

**Gas/Bremse über Display (Software-ADC)** in der App UI: Gas und Bremse kommen
über UART vom Display. Ausschalten, wenn sie direkt an den ADC-Pins hängen.

## Verkabelung

Rot auf **5V**, Schwarz auf **GND**, Gelb auf **TX (UART-HDX)**,
Grün auf **RX (Button)**, **1 kOhm** von **3.3V** auf **RX (Button)**.

## Bedienung am Display

Alle Knopf-Gesten funktionieren nur im **Stillstand**.

| Geste | Funktion |
|---|---|
| 1x drücken (aus) | Roller einschalten |
| 1x drücken (an) | Licht an/aus |
| 2x drücken | Fahrmodus wechseln: Eco → Drive → Sport |
| 2x drücken + **Bremse** halten | Sperre an/aus |
| 2x drücken + **Bremse und Gas** halten | **Original ↔ Race** |
| Lang drücken | Roller ausschalten |

Nach jedem Neustart ist wieder **Original** aktiv.

## App UI

| Tab | Inhalt |
|---|---|
| Allgemein | Software-ADC, Temperatur-Warnungen, Anfahrgeschwindigkeit, Limit-Übergang, Schwellen für die Gesten |
| Original | Eco/Drive/Sport: km/h, Strom, Watt, Field Weakening; Anzeige und Blinkfeld |
| Race | Race an/aus, Eco/Drive/Sport wie bei Original; Anzeige und Blinkfeld |
| Schutz | Alarmanlage, Überhitzungsschutz |

**Laden** holt die Werte vom VESC, **Speichern** schreibt sie ins EEPROM und
übernimmt sie sofort, **Standard** setzt alle Werte auf die Standardwerte zurück.

Akkuspannung und Abschaltgrenzen stellt das Package **nicht** ein – das
geschieht in der Motor-/Akku-Konfiguration im VESC Tool.

## Credits

Basiert auf [VESC Scooter Support](https://github.com/1zun4/vesc_scooter_support)
von Izuna und AKA13 (GPL-3.0). Blinkfeld-Idee aus
[Sharkboys G30-Script](https://github.com/Sharkboy-j/vesc_g30_dash).

Privates Hobbyprojekt, Benutzung auf eigene Gefahr. Örtliche Gesetze beachten.
