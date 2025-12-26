# Google Sheets Updater Skill

## Description
Navigate to specific cells in Google Sheets and enter data.

## Navigate to Specific Cell

### Click Name Box and Type Cell Reference
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var nameBox = document.querySelector('#t-name-box');
            if (nameBox) { nameBox.click(); nameBox.focus(); }
        "
    end tell
end tell
delay 0.3

tell application "System Events"
    keystroke "B273"
    key code 36 -- Enter
    delay 0.5
end tell
```

## Enter Data and Move Between Cells

```applescript
-- Paste content
set the clipboard to "Your content"
tell application "System Events"
    keystroke "v" using command down
    delay 0.2
    key code 48 -- Tab to next column
    delay 0.2
end tell
```

## Column Mapping for "My Selected Sources" Sheet
| Column | Header |
|--------|--------|
| A | Date (YYYY-MM-DD) |
| B | SOTA |
| C | Agentic AI |
| D | Cybersecurity |
| E | Open Source AI Projects |
| F | Open Source LLMs |
