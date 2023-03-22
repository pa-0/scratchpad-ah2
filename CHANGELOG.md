# CHANGELOG

## v9 (2023-03-22)

- CHANGED
	- Changed list item shortcuts so that they're `Alt`-based and not `Ctrl`-based. This change was made so that when you create a list item, you can immediately move it around with the arrow keys because you're already holding down `Alt`.
		- Insert list items shortcut changed to `Alt + Enter`.
		- Insert to-do list items shortcut changed to `Alt + Shift + Enter`.
		- Toggle to-do/done states shortcut changed to `Ctrl + Enter`.
- FIXED
	- On exit, Scratchpad no longer asks you if you want to save a file that is unmodified and doesn't need saving.
	- To-do roll-over wasn't working because the file wasn't being split into lines properly (always looking for `CRLF`, so failed if a file only had one of `CR` or `LF`).


## v8 (2023-02-05)

- Full rewrite of Scratchpad after 10 years of service! It's now in Autohotkey v2. This rewrite is a long time coming, and adds new features and fixes old deficiencies.
- ADDED
	- Support for lists
		- Insert list items (`Ctrl + Enter`)
		- Insert to-do list items (`Ctrl + Shift + Enter`)
		- Toggle to-do/done states (`Alt + Enter`)
		- Roll-over open to-do items into a new file (`Ctrl + Shift + N`)
		- User option: Can define bullets for lists, to-do items, and done items. It defaults to Github-Flavoured Markdown bullets.
	- Better line movement
		- Indent/outdent shortcuts (`Alt + Right/Left`)
			- User option: Custom indent size (as number of spaces).
		- Move line up/down shortcuts (`Alt + Up/Down`)
	- More proactive file saving
		- Autosave on hide and on focus loss. Scratchpad v7 only saved when it was exited, which sometimes led to data loss if the computer crashed or was abruptly restarted.
		- User option: Can enable/disable autosaving on hide and focus loss separately. 
	- Scratchpad window is finally resizeable
		- Crucially, window size is based on the current font size so that programmers using Scratchpad can ask for an editor 90 characters wide and get exactly that.
		- User option: Window size is recorded in `ScratchpadSettings.ini`, and are editable.
	- Scratchpad finally supports custom fonts
		- User option: Support for custom font and font size.
- CHANGED
	- The GUI is entirely just the text editor now, and all previous buttons, checkboxes, etc. have been removed.
	- GUI has pleasing light yellow post-it type colour now.
- REMOVED
	- Scratchpad no longer creates backup files when auto-saving.

## v7 (2013-06-29)

- Scratchpad now refreshes your active file upon unhiding, if it detects that the version on-disk is newer than the version you currently have open.
- Added a confirmation box if you are trying to save an older Scratchpad version of the active file on top of a newer on-disk version.

## v6

- Added a Start minimised checkbox to the GUI.
- Ctrl+S now attempts to silently save your active file, instead of popping a Save dialog every time.
- You can now Save As by pressing Shift + Ctrl + S.
- Window titlebar now indicates whether your file is unsaved since your last edit.

## v5

- Option to autosave the current file when Scratchpad closes (also makes a backup).
- Scratchpad also attempts to load the last-used file when it starts up.
- You can define a custom show/hide hotkey, as some users reported Win+S conflicts with other software they were using.
- Scratchpad remembers its screen position from your last session.
- Ctrl+N makes a new file from the template. There’s also a **New** button on the GUI.
- There’s a Help button **(?)** in the bottom-right that tells you shortcuts and version.
- Cancelling a file-open command no longer blanks the edit box.

## v4

- Added UTF-8 support.
- Added /min command-line flag to start Scratchpad minimised in the system tray.

## v3

- Scratchpad is no longer on top of its own Save/Load dialogs.

## v2

- Scratchpad is always on top of other windows.

## v1

- Initial version.
