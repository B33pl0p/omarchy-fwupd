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
omarchy plugin add /home/biplop/Projects/omarchy-fwupd --enable
omarchy plugin enable io.github.biplop.fwupd right
```

The plugin requires `fwupd` and `fwupdmgr`. Install them with:

```bash
omarchy pkg add fwupd
```

If the first check does not find newly published firmware, run
`fwupdmgr refresh` once, then open the plugin and refresh again.

## Behavior

- Checks immediately when the bar loads, then every six hours by default.
- Uses `LANG=C` so parsing is stable across desktop locales.
- Shows the bar widget only while checking or when updates are available.
- Never installs firmware automatically.
- Does not run commands through a shell or pass device data through shell
  arguments.

The refresh interval can be changed in the plugin settings when supported by
the installed Omarchy shell version.

## Development

Validate the manifest locally:

```bash
omarchy plugin validate /home/biplop/Projects/omarchy-fwupd
```

Install from a hosted Git repository after publishing:

```bash
omarchy plugin add https://github.com/B33pl0p/omarchy-fwupd.git --enable
```

## License

MIT
