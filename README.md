# hdr-power

**Auto HDR with the charger, on KDE Plasma (Wayland)** — the Linux port of Windows'
*"turn HDR on when plugged in"* laptop feature.

When you plug in the charger, HDR is enabled on your laptop panel; when you unplug,
it is disabled again — saving OLED battery without you touching System Settings.

It's a single watcher script plus a systemd **user** service, toggling HDR through
Plasma's own `kscreen-doctor`. No dependencies beyond Plasma itself, no root.

> KDE still has no built-in equivalent — the upstream feature request
> ([bug 509230](https://bugs.kde.org/show_bug.cgi?id=509230)) was closed *works-for-me*
> rather than implemented, so this little daemon fills the gap.

## What it does

- Polls the mains adapter state (`/sys/class/power_supply/<AC>/online`) once per second.
- On charger **connected** → `kscreen-doctor output.<panel>.hdr.enable`
  On charger **unplugged** → `...hdr.disable`
- Acts only when the charger state actually *changed* — no pointless display flashes,
  and HDR state is verified before touching it.
- Waits for the Plasma session at login (starts early at boot without racing KWin).
- A **manual** HDR toggle in System Settings is respected: it sticks until the next
  plug/unplug event, exactly like Windows' behavior.
- Logs every action to the systemd journal — `journalctl --user -u hdr-power`.

## Requirements

- KDE Plasma 6 (recent; `kscreen-doctor` gained HDR control in the 6.x era) on **Wayland**
- HDR itself working for your panel (Plasma → Display & Monitor)
- A mains power supply entry with an `online` attribute under `/sys/class/power_supply/`
  (nearly all laptops; some USB-C ultrabooks don't — see Troubleshooting)

*Tested on: Plasma 6.8.2, KDE/Plasma Wayland session, AMD Radeon 860M (RDNA 3.5),
2.8K 120 Hz OLED panel.*

## Install

```sh
git clone https://github.com/CodeMody/hdr-power.git
cd hdr-power
./install.sh
```

`install.sh` copies the files, auto-detects your power-supply name (e.g. `ACAD`, `AC`)
and panel output name (e.g. `eDP-1`), writes a per-machine systemd override, and
enables + starts the service.

<details>
<summary>Manual install (what the script does, step by step)</summary>

```sh
install -Dm755   bin/hdr-power              ~/.local/bin/hdr-power
install -Dm644   systemd/hdr-power.service  ~/.config/systemd/user/hdr-power.service
systemctl --user daemon-reload
systemctl --user enable --now hdr-power
```
</details>

## Verify it works

```sh
journalctl --user -u hdr-power -n      # should say "Started: HDR on eDP-1 follows charger ACAD"
kscreen-doctor -o | grep -m1 HDR:      # current HDR state
```

Then simply unplug and re-plug the charger — HDR should toggle within a second or two
(you'll see a brief display flash; that's Plasma switching color mode).

## Configuration

Everything is a plain default in the script; override without touching code:

| Variable | Default | Meaning |
|---|---|---|
| `HDR_POWER_OUTPUT` | `eDP-1` | Which display HDR is toggled on (e.g. an external monitor: `DP-1`) |
| `HDR_POWER_PSU` | `ACAD` | Mains adapter name under `/sys/class/power_supply/` |
| `HDR_POWER_POLL` | `1` | Poll interval in seconds |

Two places to set them, lowest to highest precedence:

1. systemd override (written by `install.sh`): `~/.config/systemd/user/hdr-power.service.d/override.conf`
   — edit, then `systemctl --user daemon-reload && systemctl --user restart hdr-power`
2. personal config file: `~/.config/hdr-power/environment` (sourced by the script itself)

```sh
# ~/.config/hdr-power/environment
HDR_POWER_OUTPUT=DP-3
```

Run `~/.local/bin/hdr-power once` to apply the current state manually, once, without the daemon.

## Rollback / uninstall

```sh
./uninstall.sh
```

or by hand:

```sh
systemctl --user disable --now hdr-power
rm -f  ~/.config/systemd/user/hdr-power.service
rm -rf ~/.config/systemd/user/hdr-power.service.d
rm -f  ~/.local/bin/hdr-power
systemctl --user daemon-reload
```

HDR itself is left exactly in whatever state it was — nothing else in your Plasma
display config is touched.

## Troubleshooting

- **Service exits with "no mains adapter found"** — your laptop doesn't expose
  `AC*/online`. Check `grep -r . /sys/class/power_supply/*/type 2>/dev/null`; if no
  entry has type `Mains` with an `online` file, this machine needs a variant that
  watches `BAT0/status` (Charging/Discharging) instead.
- **HDR never turns on** — check `journalctl --user -u hdr-power` first, then
  `kscreen-doctor -o | grep HDR:`; if the panel reports `HDR: unsupported`, fix HDR
  on the desktop itself before automation (see Plasma's Display & Monitor settings).
- **Panel name differs** — find it with `kscreen-doctor -o` (look for the `eDP` entry)
  and set `HDR_POWER_OUTPUT` accordingly.

## License

MIT — do whatever, keep the credit line if you can.
