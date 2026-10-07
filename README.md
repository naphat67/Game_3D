# Backrooms: Level 0

A single-player Backrooms game made with Godot 4.7. This build focuses on Level 0, a Smiler encounter, and collectible light balls.

## Play in a browser

The ready-to-publish web build is in [`docs/`](docs/). To publish it with GitHub Pages, set the repository's Pages source to the `main` branch and `/docs` folder.

To rebuild the web version, open the project in Godot 4.7 and export the `Web` preset. It uses the Compatibility renderer and single-threaded web export.

## Controls

- `W A S D`: Move
- `Mouse`: Look
- `Left click`: Throw a light ball
- `Shift`: Run
- `Space`: Jump
- `E`: Interact
- `P`: Release or capture the mouse
- `Tab`: Open inventory

Collect light balls before throwing them. One pickup appears at a time, up to eleven total. The Smiler takes five hits to defeat; it can catch the player within 20 meters and five touches end the run.
