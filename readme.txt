Welcome to NeoPatcher! The goal of NeoPatcher is to provide an easy way to translate ordinary plugins for Vendetta Online into ones compatible with Neoloader. NeoPatcher creates the registration and launcher files necessary for making Neoloader detect your plugin(s), while the plugin's code itself is handled by the game just like normal.

An executable is provided for Windows users. If you are on another PC system, please refer to readme-dev.txt.

==================================================
Instructions on use:
==================================================

1) Launch NeoPatcher and agree to the MIT license. 
2) Select to patch all mods, or patch a specific mod
3a) If you want to patch ALL of your mods, select the folder containing all of your mods, then click next
3b) If you want to patch a specific mod, select the folder containing that individual mod, then click next
4) Select a mod you want to edit details on. The mods to be patched will be listed on the left; when one is selected, the contents on the right will fill in. Items will save edits you make when you select another mod or begin the process.
4a) If you want to add more individual mods to patch, you can do so with the button on the bottom left at this time.
5) Select to begin the patching process. If you have only one or a few mods to patch, this process will likely happen instantaniously.
6) Congratulations, you're done, and your mods have been patched!

If there are any issues with your patched mod, you can find the original mod's files located in the "backup" folder created where the tool is located. 

==================================================
How it works
==================================================

How does NeoPatcher create its patches? Its actually really simple. It takes the original main.lua file and renames it to "core_patched.lua", then creates new main.lua file based on a template. It then creates a Neoloader declaration INI based on the provided information, and then its done! 

The end result is a plugin that registers itself to Neoloader. When the Neoloader init process occurs, it detects your newly patched code as a compatibility plugin, and then patched_core.lua will run during the default plugin loader like normal as long as the plugin is set to load. As a bonus, if Neoloader is not enabled, the plugin will skip all the neoloader stuff and just launch like normal anyways. 
