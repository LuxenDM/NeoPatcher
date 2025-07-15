These are the source files for NeoPatcher — a utility for converting Vendetta Online plugins into Neoloader-compatible plugins. All core logic is written in `main.lua`. The C++ portion simply embeds and executes the Lua environment with the required libraries.

==================================================
Running the Lua version directly:
==================================================

1) Install a Lua 5.1 interpreter for your system
   • You can get Lua from https://www.lua.org/
   • LuaRocks (https://luarocks.org/) is recommended for installing dependencies

2) Install the following Lua libraries:
   • IUP and IUPLua 3.30
   • LuaFileSystem 1.8.0

3) Open `main.lua` and uncomment line 2:
   ```lua
   --local lfs = require('lfs')  →  local lfs = require('lfs')

4) Run `main.lua` using your preferred method
   ```sh
   lua main.lua

==================================================
Compiling the binary:
==================================================

1) Run `generate_array.py`.
   This converts `main.lua` into a C++ header file (`lua_index.h`) containing a raw byte array.

2) Ensure your compiler links against the following libraries:
   • Lua 5.1.x
   • IUP and IUPLua 3.30
   • LuaFileSystem 1.8.0

   On Windows, IUP also depends on
   • `ole32.lib`
   • `comctl32.lib`

3) Compile `luatest.cpp` using your preferred toolchain
   This has been tested with Visual Studio 2022.
   If you're using MSVC:
   • Add `lua_index.h` to your project
   • ENsure all IUP/Lua DLLs are in the runtime path, or link statically

==================================================
Notes from the author:
==================================================

NeoPatcher was created by Luxen De'Mark, who is not a C++ expert and makes no claims of production-grade compiler knowledge.

You're encouraged to improve the C++ wrapper if you'd like to contribute — suggestions are HIGHLY welcome!