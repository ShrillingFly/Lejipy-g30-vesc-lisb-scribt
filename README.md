# G30 VESC Dashboard – Original + Race Profile

VESC lisp dashboard script for a Ninebot G30, based on the original
["G30 dashboard support lisp script" by Izuna and AKA13](https://github.com/m365fw/vesc_m365_dash),
extended with a second, switchable **Race profile** on top of the
stock **Original profile**.

Tested with VESC 7.00 on a Spintend Ubox Single 85 200, 72V pack.

## What it does

- **Original profile**: stock eco/drive/sport limits, unchanged from upstream.
- **Race profile**: separate eco/drive/sport limits, tuned independently
  (see the table at the top of the script). Switch between the two by
  double-pressing the dashboard button while holding brake **and**
  throttle at the same time (board must be stationary). Same gesture
  switches back.
- Dashboard error codes are mapped from VESC's internal fault codes to
  the closest matching real Ninebot G30 error code, so what shows up on
  the display is something you can actually look up.
- No alarm/anti-theft subsystem - locking just cuts throttle (immobilizer
  only), no siren, no gyro movement detection, no forced auto-brake.
- Debounced button reading (3-sample majority vote) to filter out noise
  on the shared button/UART wire, e.g. from hard braking.

Full details are documented in comments inside
[`VESC_Scripts/g30_dashboard_race.lisp`](VESC_Scripts/g30_dashboard_race.lisp).
See [`CHANGELOG.md`](CHANGELOG.md) for the full Alpha → Beta → Release
version history, with the exact script snapshot for each version kept on
its own branch.

## Which version to use

- **`main` (Alpha 2.0)** - the stable, proven version. This is what runs
  well on real hardware. Use this one.
- **[`beta-3.0`](https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/tree/beta-3.0)** -
  new, not yet road-tested: the dashboard display becomes freely
  configurable (what's shown standing still vs riding, per profile,
  including a red blinking readout in the error-code field), plus a
  retuned Original profile. Try it if you want those features.

## Installation

UART wiring: red = 5V, black = GND, yellow = COM-TX (UART-HDX),
green = COM-RX (button) + 3.3V through a 1kΩ resistor.

German wiring guide: https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/

Load the script into VESC Tool's Lisp tab and upload it to your VESC.

## Tuning

All the values you'd realistically want to change day-to-day - speed
caps, current scale, watt ceilings, field weakening, ADC thresholds,
temperature warnings - are grouped in one block near the top of the
script, under `QUICK-EDIT PARAMETERS`. Everything below
`Code starts here` is implementation and shouldn't need touching for
normal tuning.

**NOTE:** battery voltage/cutoffs are not set by this script - configure
those separately in your VESC motor/battery config in VESC Tool.

## Disclaimer

This is a hobbyist mod for a personal electric scooter. Test any speed/
power/current changes carefully and within your local laws before riding.
No warranty, use at your own risk.
