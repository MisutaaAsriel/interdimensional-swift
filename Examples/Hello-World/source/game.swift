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