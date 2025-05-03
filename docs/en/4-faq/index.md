# F.A.Q. and limitations

## What is the correct command to use in Aseprite Command Path

The plugin uses one of the default commands bellow depending on the Operational System:

- Windows: `C:\\Steam\steamapps\common\Aseprite\aseprite.exe`.
- MacOS: `/Applications/Aseprite.app/Contents/MacOS/aseprite`.
- Linux: `aseprite`.

If you are using a different path you can edit it via Editor Settings.

## Linux: Path is correct but Aseprite not found

Some distros install Godot via Flatpak. By default, flatpak apps are sandboxed not having access to the host's file system. This will make Godot show "command not found" even when the right path is set.

At the time I'm writing this, people recommend using a program called Flatseal which is able to give flatpak apps permission to access parts of the file system.

## MacOS: Path is correct but Aseprite not found

If you are copying the path from the Finder, it's very likely you are copying the wrong one. MacOS apps are just special folders ending on `.app`. The real executable is located inside it, in the `Contents/MacOS/` folder.

Check the default command for an example. Usually what you want is for your aseprite path to end on `Aseprite.app/Contents/MacOS/aseprite`.

## Non-looping animations

From Aseprite 1.3 you can control loops by setting the `repeat` property under `Tag properties` in Aseprite. There's no extra steps required in the plugin.

Older versions have no option for loops so this plugin handles that via a configured convention.

By default, all animations are imported with loop = true. Any animation starting with `_` (the exception prefix), will be imported with loop = false.

Both the default configuration and the exception prefix can be changed in the configuration window.

## Import overwrite previous files

This is expected behaviour, import overwrites previously imported files. Any manual modification in the previous resource file will be lost.
