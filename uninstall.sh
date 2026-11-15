#!/usr/bin/env bash
# Remove hdr-power: stop + disable the service and delete everything install.sh put in place.
set -eu

systemctl --user disable --now hdr-power.service 2>/dev/null || true

rm -f  "$HOME/.config/systemd/user/hdr-power.service"
rm -rf "$HOME/.config/systemd/user/hdr-power.service.d"
rm -f  "$HOME/.local/bin/hdr-power"

systemctl --user daemon-reload || true

echo "hdr-power uninstalled."
echo "HDR state was left as-is (last toggled value). Your optional ~/.config/hdr-power/ config dir was kept."
