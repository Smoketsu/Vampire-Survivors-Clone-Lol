## SaveBackupData: words and limits of the save codes (SaveBackup) and the Settings
## Save tab (GDD §15.0 "Save backup codes and the GitHub Pages build"). Data only.
class_name SaveBackupData
extends RefCounted

## Every save code starts with this (format version 1: base64 of the gzipped save.cfg).
const CODE_PREFIX: String = "NECRO1:"  # TUNING (not in GDD)
## Largest save file (bytes) a code may unpack to; anything bigger is refused (a real
## save is a few kB).
const MAX_SAVE_BYTES: int = 1048576  # TUNING (not in GDD)
## Seconds (real time) after Backup before the Web build asks whether the clipboard
## took the code (the browser answers asynchronously).
const COPY_CHECK_DELAY: float = 0.6  # TUNING (not in GDD)

# --- Words (Settings -> Save) ----------------------------------------------------------

## Dim line above the buttons (BODY tier).
const INFO: String = "Back up your progress as a code. Paste it to restore it here or on another device."  # TUNING (not in GDD)
## Backup button.
const BACKUP: String = "Backup"  # TUNING (not in GDD)
## Restore button.
const RESTORE: String = "Restore"  # TUNING (not in GDD)
## Status after a code reached the clipboard.
const COPIED: String = "Code copied"  # TUNING (not in GDD)
## Status after the code was shown in the browser's box instead.
const SHOWN: String = "Code shown: copy it from the box"  # TUNING (not in GDD)
## Status when there is no progress yet.
const NOTHING: String = "No progress to back up yet"  # TUNING (not in GDD)
## Status after a successful restore.
const RESTORED: String = "Progress restored"  # TUNING (not in GDD)
## Status for a pasted text that is not a save code.
const INVALID: String = "That is not a Necropathy save code"  # TUNING (not in GDD)
## Status when saving is unavailable or the file could not be written.
const FAILED: String = "Could not restore here"  # TUNING (not in GDD)
## Status in a run: Restore waits for the main menu.
const IN_RUN: String = "Restore from the main menu"  # TUNING (not in GDD)
## Web build: the browser's box that shows the code.
const PROMPT_COPY: String = "Your Necropathy save code. Select it all and copy it:"  # TUNING (not in GDD)
## Web build: the browser's box that asks for a code.
const PROMPT_PASTE: String = "Paste your Necropathy save code:"  # TUNING (not in GDD)
## Confirm dialog before a restore replaces the progress (title, body, confirm button).
const CONFIRM := ["Restore?", "Your current progress is replaced by the backup.", "Restore"]  # TUNING (not in GDD)
