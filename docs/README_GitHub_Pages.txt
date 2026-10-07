WEB BUILD - GODOT 4.7

To publish with GitHub Pages:
1. Upload the contents of this folder (all index.* files and .nojekyll) to the repository root or its docs/ folder.
2. In the repository, open Settings > Pages and select that branch and folder as the deployment source.
3. Open the published Pages URL over HTTPS.

Keep all index.* files together. The game will not run by opening index.html directly from your computer; it needs a web server.

This Web build uses Godot's Compatibility renderer. Godot 4 does not support exporting C# projects to Web, so the C# I4 connection component is omitted from this Web-only build. The desktop project remains separate.
