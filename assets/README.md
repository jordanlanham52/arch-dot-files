DROP YOUR ASSETS HERE
=====================

This directory expects two files, neither of which is included in the repo:

1. `wallpaper.png`
   The full-resolution Tarnished Reliquary wallpaper you generated.
   Used as desktop wallpaper and as the (blurred) hyprlock background.

2. `spade.png`  (optional)
   An isolated spade pip on transparent background, ~512×512.
   Extract it from the wallpaper using GIMP, Photopea, or rembg.
   Used as the hyprlock centerpiece.

The install script copies these to ~/.config/hypr/ on `bash install.sh`.
You can also do it manually:

    cp wallpaper.png ~/.config/hypr/wallpaper.png
    cp spade.png     ~/.config/hypr/spade.png

If `spade.png` is missing, hyprlock will run fine — it just won't have
the centered pip image (the rest of the composition still works).
