# Interdimensional Swift
### It's Swift... on the Nintendo 3DS!

Do you want to get started with 3DS homebrew, but find C displeasurable? Have you thought to yourself "Gee, I wish there was a language that was easier to understand!"

...Well then, look no further, because this mad goat has just the setup for you! With the power of [Embedded Swift](https://github.com/swiftlang/swift-evolution/blob/main/visions/embedded-swift.md), you too can code in Swift for your Nintendo 3DS!

&nbsp;

## Getting Started
### 1. Set up your development environment
- This guide assumes you have followed the instructions to set up `devkitPro`, & the 3DS SDK.
  - You can find the instructions to get started with this here: https://devkitpro.org/wiki/Getting_Started
  - Be sure to install all of `3DS-dev` via `dkp-pacman`
  - Make sure `DEVKITARM` & `DEVKITPRO` are exported to your system environment variables, either via the relevant shell `rc` file, or via system settings
- This guide assumes you are using a `makefile` as your build method of choice.
- This guide assumes you have already installed the latest [Swift toolchain for non-Darwin & Embedded development](https://www.swift.org/install) and set it as the default toolchain
- This guide assumes you are using an editor preconfigured to use SourceKit-LSP, the language server for code completion with Swift, such as VSCode with the [Swift extension](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode).
- This guide is based off using the DevkitPro 3DS example "Hello-World" (`examples/3DS/graphics/printing/hello-world`)

&nbsp;

### 2. Set up your project layout as follows...
  - `Project/` ← Root Project Folder
    - `source/` ← Source Folder
      - `game.swift` ← Your main swift file
      - `Bridging-Header.h` ← The header used to import the 3DS SDK into swift
    - `makefile` ← Your Makefile
    - `compile_commands.json` ← The compilation database used to tell the language server to import the header above
> [!NOTE]
> Without `compile_commands.json`, you cannot use Intellisense, or similar code-completion/error-checking/documentation features of your IDE of choice, within your `.swift` code. Since this is not a Swift Package Manager project, this file essentially tells the Swift language server, SourceKit-LSP, how to import the `Bridging-Header` which imports the 3DS SDK.

&nbsp;

### 3. Configure your `Bridging-Header.h` as follows...
```h
#include <stdio.h>
#include <3ds.h>
// Any other C headers you need to import go here
// #include <header.h> = header as part of an imported directory at build time
// #include "path/to/header.h" = static path to header not imported by directory
```

&nbsp;

### 4. Configure your `compile_commands.json` as follows...
```json
[
    {
      "directory": "<ABSOLUTE PATH TO PROJECT ROOT>",
      "command": "swiftc source/game.swift -parse-as-library -enable-experimental-feature Embedded -target armv6-none-none-eabi -no-allocations -import-objc-header source/Bridging-Header.h -I <ABSOLUTE PATH TO DEVKITARM>/include -I <ABSOLUTE PATH TO DEVKITARM>/arm-none-eabi/include -I <ABSOLUTE PATH TO DEVKITPRO>/libctru/include <ANY OTHER INCLUDES AND SWIFT COMPILER FLAGS>",
      "file": "source/game.swift"
    }
]
```
> [!IMPORTANT]
> On POSIX systems (macOS/UNIX, Linux), open the terminal and run `echo $DEVKITPRO` for the absoslute path to the devkitPro directory, and `echo $DEVKITARM` for the path to the devkitARM directory. Replace `<ABSOLUTE PATH TO DEVKITPRO>` and `<ABSOLUTE PATH TO DEVKITARM>` respectively.


> [!NOTE]
> Replace `<ANY OTHER INCLUDES AND SWIFT COMPILER FLAGS>` with any additional flags and include operations. If none are needed, delete this and the preceding space.

&nbsp;

### 5. Alter your `makefile` as follows...
  1. Alter the compiler flags for swift:
  ```diff
- CFLAGS	:=	-g -Wall -O2 -mword-relocations \
+ SWIFTCFLAGS	:=	-g -Wall -O2 \
			-ffunction-sections \
			$(ARCH)

- CFLAGS	+=	$(INCLUDE) -D__3DS__
+ SWIFTCFLAGS	+=	$(INCLUDE) -D__3DS__

+ CFLAGS	:=	$(SWIFTCFLAGS) -mword-relocations
```
> [!WARNING]  
> I am not certain how correct this is. `-mword-relocations` is not a valid flag with the swift compiler, so I am unsure as to how important this may be. For what it is worth, I was able to successfully build and run `hello-world` with `-mword-relocations` simply removed, but to err with caution, I have elected to instruct others to instead alter the compilation flags so that Swift effectively receives a variation of `CFLAGS` with `-mword-relocations` removed.
  2. Add Swift compiler instructions:
```diff
#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(CTRULIB)

+ #---------------------------------------------------------------------------------
+ # Instructions for the Swift compiler
+ #---------------------------------------------------------------------------------
+ SWIFTC := <PATH TO swiftc BINARY>
+ SWIFTFLAGS := -wmo -parse-as-library -enable-experimental-feature Embedded -target armv6-none-none-eabi -no-allocations -import-objc-header ../$(SOURCES)/Bridging-Header.h -I $(DEVKITARM)/include -I $(DEVKITARM)/arm-none-eabi/include -I $(DEVKITPRO)/libctru/include <ANY OTHER INCLUDES OR SWIFT COMPILER FLAGS GO HERE>
+ %.o: %.swift
+ 	@echo $(notdir $<)
+ 	$(ADD_COMPILE_COMMAND) add $(SWIFTC) $(SWIFTFLAGS) "$(addprefix -Xcc , $(C_FLAGS)) -c $< -o $@" $<
+ 	$(SILENTCMD)$(SWIFTC) $(SWIFTFLAGS) $(addprefix -Xcc , $(SWIFTCFLAGS)) -c $< -o $@ $(ERROR_FILTER)
```
> [!IMPORTANT]
> Replace `<PATH TO swiftc BINARY>` with the absolute path to where `swiftc` is located. On macOS, this is likely to be `/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swiftc`, but if you are using a different toolchain other than latest, YMMV.

> [!NOTE]
> Replace `<ANY OTHER INCLUDES OR SWIFT COMPILER FLAGS GO HERE>` with any additional flags and include operations. If none are needed, delete this and the preceding space.
  3. Include `.swift` files as part of compilation:
```diff
export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
+ SWIFTFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.swift)))
```
  4. Alter the `OFILES_SOURCES` to include swift files:
```diff
- export OFILES_SOURCES 	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
+ export OFILES_SOURCES 	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o) $(SWIFTFILES:.swift=.o)
```

&nbsp;

### 6. Write your swift code...
  - Example (`game.wift`):
```Swift
@main
struct Game {
    static func main() {
        gfxInitDefault()
        
        consoleInit(GFX_TOP, nil)

    	print("Hello from Swift!")

	    print("Press B to exit.")

        while(aptMainLoop()) {
            hidScanInput()
            var kDown: UInt32 = hidKeysDown()

            if (kDown == KEY_B) { 
                break // break in order to return to hbmenu
            }

		// Flush and swap framebuffers
		gfxFlushBuffers()
		gfxSwapBuffers()

		//Wait for VBlank
		gspWaitForEvent(GSPGPU_EVENT_VBlank0, true)

        }
        gfxExit()
    }
}
```

&nbsp;

### 7. `make`, and enjoy! :)
