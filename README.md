# Copy Lobster USB Skill

Batch-copy a prepared folder to every currently inserted USB drive, then write a per-drive license or serial value into the copied `lobster.key` file.

Although this skill was first built for a Lobster AI USB workflow, the pattern is useful for any repeated USB provisioning job where:

- the same folder must be copied to multiple USB drives;
- each USB drive needs a different serial, license code, or identifier;
- the number of USB drives should be detected from the devices currently plugged in.

## What It Does

- Detects removable USB drives on Windows.
- Sorts drives by drive letter.
- Reads serials from a text file, one serial per line.
- Copies the source folder to each USB drive with `robocopy`.
- Updates the final line of each copied `lobster.key` to `LXAI-<serial>`.
- Leaves the original source folder untouched.
- Prints a final summary showing each drive, assigned serial, target key line, and robocopy exit code.

## Default Paths

The bundled script defaults to the original local workflow:

- Source folder: `C:\傳輸\龍蝦AI隨身碟`
- Key file: `C:\傳輸\key.txt`
- Target folder: `<USB drive>:\龍蝦AI隨身碟`
- Robocopy logs: `C:\傳輸\robocopy-<drive>.log`

You can override these paths with script parameters.

## Install As A Codex Skill

Copy this repository folder into your Codex skills directory:

```powershell
Copy-Item -Recurse -Force . "$env:USERPROFILE\.codex\skills\copy-lobster-usb"
```

After that, you can ask Codex to use `$copy-lobster-usb` for USB batch-copy work.

## Dry Run

Run without `-Proceed` first. This only shows the detected USB drives and planned serial assignment.

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\copy-lobster-usb.ps1"
```

## Execute

When the plan looks correct, run with `-Proceed`:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\copy-lobster-usb.ps1" -Proceed
```

## Target Specific Drives

Use `-DriveLetters` to process only selected USB drives:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\copy-lobster-usb.ps1" -DriveLetters D,E -Proceed
```

## Use Different Source Or Key Files

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\copy-lobster-usb.ps1" `
  -SourceFolder "C:\Path\To\USB-Package" `
  -KeyFile "C:\Path\To\keys.txt" `
  -DestinationFolderName "USB-Package" `
  -LogDirectory "C:\Path\To\logs" `
  -Proceed
```

## Key File Format

Use one serial per line. Blank lines are ignored.

```text
AAAA-0001
BBBB-0002
CCCC-0003
```

For each USB drive, the script writes:

```text
LXAI-AAAA-0001
```

to the last line of the copied `lobster.key`.

## Safety Notes

- The script does not modify the source folder.
- The script stops if there are fewer serials than detected USB drives.
- `robocopy` exit codes below `8` are treated as non-fatal.
- Always run the dry run first when multiple removable drives are connected.
