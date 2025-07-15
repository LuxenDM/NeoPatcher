Welcome to NeoPatcher!

NeoPatcher is a tool that helps you convert ordinary plugins for Vendetta Online into ones compatible with Neoloader. It creates the registration and launcher code necessary for Neoloader to detect and manage your plugin(s), while the plugin itself continues to function just like it did before.

A Windows executable is provided. If you're using a different operating system, see `readme-dev.txt` for source-based usage instructions.

==================================================
Instructions
==================================================

1) Launch NeoPatcher and agree to the MIT license.
2) Choose whether to patch:
     • All of your mods at once, or
     • A specific mod

3a) If patching all mods:  
     • Select the folder that contains your mod folders  
     • Click "Next"

3b) If patching a specific mod:  
     • Select that mod's folder  
     • Click "Next"

4) On the job screen:  
     • Select a mod from the list on the left  
     • Its info will appear on the right  
     • You can edit the plugin's internal name, version, etc.

4a) You can add more individual mods to the list at this time by clicking the "Add another mod" button.

5) When you're ready, click "Begin Patching" to apply the changes. For most mods, this takes less than a second.

6) Done! Your selected mods are now Neoloader-compatible.

If anything goes wrong, a complete backup of the original mod folder is created inside a `backup/` folder where the tool is located.

==================================================
How It Works
==================================================

NeoPatcher modifies your mod’s `main.lua` file using a template. This template adds:

• Inline LME registration metadata (`[modreg]`, etc.)
• Detection and compatibility code for Neoloader
• A fallback so your plugin still loads correctly if Neoloader isn't present

The patched plugin registers itself with Neoloader, and during the game’s normal plugin loading phase, your original plugin logic still runs as expected. The added code is minimal, and ensures compatibility without disrupting the original behavior.

Best of all: if Neoloader isn’t installed, the plugin just runs like normal — no harm, no error, no disruption.
