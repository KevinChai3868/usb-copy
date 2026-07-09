---
name: copy-lobster-usb
description: Copy the local Lobster AI USB folder to all currently inserted removable USB drives and assign license keys from a key.txt file. Use when the user asks to prepare, duplicate, provision, or write "龍蝦AI隨身碟" / Lobster AI USB drives, especially when each drive needs lobster.key updated with the next LXAI license code and the number of USB drives should be detected from the current machine.
---

# Copy Lobster USB

## Workflow

Use `scripts/copy-lobster-usb.ps1` for this task instead of hand-writing ad hoc copy commands. It handles removable-drive detection, key-count checks, robust copying, and updating `lobster.key`.

Default paths:

- Source folder: `C:\傳輸\龍蝦AI隨身碟`
- Key file: `C:\傳輸\key.txt`
- Target folder on each USB: `<Drive>:\龍蝦AI隨身碟`

Run a dry run first:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\copy-lobster-usb\scripts\copy-lobster-usb.ps1"
```

If the detected drives and serial assignment look right, run with `-Proceed`:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\copy-lobster-usb\scripts\copy-lobster-usb.ps1" -Proceed
```

## Behavior

- Detect removable drives with `Win32_LogicalDisk DriveType = 2`.
- Sort drives by drive letter, then assign keys in order from `key.txt`.
- Treat blank lines in `key.txt` as unused.
- Require at least one key per detected USB drive.
- Copy with `robocopy /E /MT:8 /R:0 /W:0 /FFT /XJ`.
- Write each target `lobster.key` last line as `LXAI-<serial>`.
- Leave the source folder and source `lobster.key` unchanged.
- Write robocopy logs to `C:\傳輸\robocopy-<drive>.log` by default.

## Common Options

Use `-DriveLetters D,E` to target specific drives instead of all removable drives:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\copy-lobster-usb\scripts\copy-lobster-usb.ps1" -DriveLetters D,E -Proceed
```

Use `-DestinationFolderName` if the folder name changes:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\copy-lobster-usb\scripts\copy-lobster-usb.ps1" -DestinationFolderName "龍蝦AI隨身碟" -Proceed
```

## Verification

After running, report:

- Each target drive and folder.
- The assigned serial.
- The final line of each target `lobster.key`.
- Each robocopy exit code and whether any log reports `FAILED > 0`.

Robocopy exit codes below 8 are generally non-fatal. Code `1` usually means files were copied successfully.
