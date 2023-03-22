set /p ver="Enter a new version number: "

del distrib\scratchpad_v%ver%.zip

rem 7z a -tzip distrib\scratchpad_v%ver%.zip README.md
rem 7z a -tzip distrib\scratchpad_v%ver%.zip CHANGELOG.md
rem 7z a -tzip distrib\scratchpad_v%ver%.zip LICENSE
rem 7z a -tzip distrib\scratchpad_v%ver%.zip ./src/Scratchpad.exe
rem 7z a -tzip distrib\scratchpad_v%ver%.zip ./src/template.txt
rem 7z a -tzip distrib\scratchpad_v%ver%.zip src/Scratchpad.ahk
rem 7z a -tzip distrib\scratchpad_v%ver%.zip "src/pencil with border.ico"

7z a -tzip distrib\scratchpad_v%ver%.zip README.md CHANGELOG.md LICENSE ./src/Scratchpad.exe ./src/template.txt
7z rn distrib\scratchpad_v%ver%.zip README.md docs/README.md CHANGELOG.md docs/CHANGELOG.md LICENSE docs/LICENSE

PAUSE
