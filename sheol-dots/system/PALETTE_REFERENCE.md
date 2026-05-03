# SHEOL // TTY Palette Reference

`setvtrgb-palette.txt` is the file fed to `setvtrgb`.
Format requires 16 lines of "R,G,B" decimal values, comma-separated, no comments.

The mapping below is for reference only — DO NOT add this to the palette file.

```
Line  ANSI color       Token       RGB              Hex
----  ---------------  ----------  ---------------  -------
1     black            crypt       12,10,16         #0c0a10
2     red              sanctus     90,26,26         #5a1a1a
3     green            oxide       107,85,48        #6b5530
4     yellow           gilt        160,130,64       #a08240
5     blue             tarnish     74,58,31         #4a3a1f  (warm — NOT actual blue)
6     magenta          viaticum    45,26,58         #2d1a3a
7     cyan             linen       107,100,112      #6b6470  (muted gray — NOT actual cyan)
8     white            bone        184,174,160      #b8aea0
9     bright black     ash         42,37,48         #2a2530
10    bright red       sanctus+    139,42,42        #8b2a2a
11    bright green     gilt        160,130,64       #a08240
12    bright yellow    leaf        201,166,81       #c9a651
13    bright blue      oxide       107,85,48        #6b5530
14    bright magenta   viaticum+   74,42,90         #4a2a5a
15    bright cyan      bone        184,174,160      #b8aea0
16    bright white     pallor      232,223,208      #e8dfd0
```

The radical move: ANSI blue and cyan are remapped to gold and gray. This means
every CLI tool that uses default colors (ls, git, log files, neovim's default
theme) inherits the no-cool-tones rule automatically.

To apply manually:
    setvtrgb /etc/sheol/setvtrgb-palette.txt > /dev/tty1

For all TTYs at once:
    for tty in /dev/tty[1-6]; do setvtrgb /etc/sheol/setvtrgb-palette.txt > $tty; done

The systemd service `sheol-tty-palette.service` does this automatically at boot.
