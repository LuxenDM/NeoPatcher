These are the source files of NeoPatcher, a utility for patching Vendetta Online plugins to be Neoloader-compatible. All the actual functionality is provided by "main.lua"; the C++ merely initializes a lua interpreter on the user's computer with the necessary libraries.

To run the lua code as-is:
1) Download and install the lua interpreter for your system
2) Download and install the IUPLua and LuaFileSystem libraries (available as luarocks, if that is available to you)
3) Make sure to un-comment line 2 in main.lua and save
4) Run main.lua

To compile the binary using C++:
1) run generate_array.py. this will translate main.lua into bytecode in an index_lua.h file, which is referenced by your compiler.

2) Add the following libraries to your compiler of choice.
Lua 5.1.x
IUP and IUPLua 3.30
LuaFileSystem 1.8.0

This code was originally compiled using Visual Studio 2022

3) Use your compiler of choice to compile luatest.cpp. 
Remember that IUP has dependencies of its own. For Windows, this will be ole32 and comctl32. Refer to the IUP documentation.




The author Luxen De'Mark is NOT knowledgeable about C++ or compilers or all the fancy shmancy utilities surrounding C++, so he won't provide support for this process. He will GLADLY take your suggestions, though! ;)