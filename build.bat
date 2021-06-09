@echo off
rem Build the Z80 portion of the sound driver
asm68k /p /k /c sound/z80/z80.asm, snd.unc, ,snd.lst
rem Compress the Z80 driver
FW_KENSC\koscmp snd.unc snd.kos
rem Build the game...
asm68k /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- sonic1.asm, "Kelp in Sonic 1.gen" , ,.lst >errors.log
rem Fix the header/pad the ROM
romfix -z "Kelp in Sonic 1.gen" 
pause