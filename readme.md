# microui

A port of [microui](https://github.com/rxi/microui) to Nim; a tiny, portable, immediate-mode UI library

## Extras

Some additions have been added to the library (in terms of new UI elements to use), which are contained in the `microui/extras`. They can be imported by doing

```nim
import microui/extras
```

Extra features include:
- `muMenuBar` - A taskbar / toolbar for use in windows and outside
    - `muMenuBarTab` - A tab of the MenuBar, acts similarly to treenodes
- `muSeparator` - A line separator
- `muTextSeparator` - A line separator with text inbetween 
- `muTextLink` - A muText element with a URL link parameter that will attempt to open the link when the text is clicked

Overloads:
- `muText`:
    - An overload with a `color` MUColor parameter for specifying specific text color
- `muWindow`:
    - An overload with a `isOpen` boolean parameter which will determine the state of the window being "open". Can be used to create windows that are toggleable via variable. Slightly more readable than other methods of accomplishing the same.