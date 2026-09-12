# Omarchy Firmware Updates

An Omarchy shell extension that checks `fwupdmgr get-updates` periodically,
shows a firmware indicator in the bar, and provides a small update dashboard.
Installation is always explicit: clicking **Install updates** opens
`fwupdmgr update` in Omarchy's floating terminal so authentication, device
safety checks, and reboot prompts remain visible.

The dashboard identifies the laptop by its DMI vendor and product name, shows
the current BIOS version, reports the last check time, and lets you refresh
the LVFS query manually.

## Install

```bash
omarchy plugin add https://github.com/B33pl0p/omarchy-fwupd.git --enable
omarchy plugin enable io.github.biplop.fwupd right
```

The plugin requires `fwupd` and `fwupdmgr`. Install them with:

```bash
omarchy pkg add fwupd
```

If the first check does not find newly published firmware, run
`fwupdmgr refresh` once, then open the plugin and refresh again.

## Remove

```bash
omarchy plugin remove io.github.biplop.fwupd --yes
```

Removing the plugin deletes its bar widget from Omarchy's plugin installation.
If you added a custom `{ "id": "io.github.biplop.fwupd" }` entry to
`~/.config/omarchy/shell.json`, remove that entry separately.

## Dependencies and permissions

The plugin requires:

- Omarchy shell with third-party bar-widget support
- `fwupd` / `fwupdmgr`
- A working Omarchy polkit agent for authenticated firmware installation

The plugin reads DMI metadata from `/sys/class/dmi/id/` and invokes
`fwupdmgr get-updates` for checks. It never installs firmware automatically.
The **Install updates** action explicitly launches `fwupdmgr update`, which
may require authentication and a reboot.

## Behavior

- Checks immediately when the bar loads, then weekly by default.
- Uses `LANG=C` so parsing is stable across desktop locales.
- Keeps the bar widget visible so the firmware dashboard is always accessible.
- Sends one desktop notification when a check newly discovers firmware updates;
  it does not repeat the notification while the same updates remain available.
- Never installs firmware automatically.
- Does not run commands through a shell or pass device data through shell
  arguments.

The dashboard lets you choose hourly, daily, weekly, or monthly automatic
checks with compact themed buttons. Manual refresh is always available.

The plugin does not overwrite user configuration during installation or
removal. The frequency selector writes only the selected widget entry after
the user changes it in the dashboard.

## Development

Validate the manifest locally:

```bash
omarchy plugin validate ./omarchy-fwupd
```

Install or update from the hosted Git repository:

```bash
omarchy plugin add https://github.com/B33pl0p/omarchy-fwupd.git --enable
omarchy plugin update io.github.biplop.fwupd --yes
```

## License

MIT

## Marketplace notes

This repository is public and includes installation and removal instructions.
Before submission, confirm that you own or have permission to submit the
plugin and any associated assets. This plugin currently ships no preview image
or other third-party asset.

Marketplace approval means listing approval only; it is not a security review.
