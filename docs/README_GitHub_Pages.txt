GODOT 4.7 WEB BUILD

This folder contains the published game files. Keep all index.* files and .nojekyll together.

GitHub Pages setup:
1. Push this project to the repository.
2. In Settings > Pages, select the main branch and /docs folder as the deployment source.
3. Open the HTTPS Pages URL after the deployment completes.

To rebuild, open the Godot project and export the Web preset. The preset uses the Compatibility renderer and single-threaded web export. Serve these files from a web server; opening index.html directly from disk will not run the game.
