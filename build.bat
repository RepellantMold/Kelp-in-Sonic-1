@echo off
asm68k /p /k /c sound/z80/z80.asm, snd.unc, ,snd.lst
FW_KENSC\koscmp snd.unc snd.kos
asm68k /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- sonic1.asm, s1built.bin , ,.lst >errors.log
fixheadr.exe s1built.bin 
pause