# 86adventure
![](git-content/intro.gif)

X86adventure is a **tiny 2D game engine** written in assembly for **x86 microprocessor**. x86adventure works in **16bit mod**.

It includes a graphic library (13h vga mode)  allowing you to:

1 : Draw generic shapes ( lines, rectangles, triangles, circles ...)

2 : Draw all bitmap format (32bit, 16bit, 8bit indexed-color, monochrome...)

3 : Print text with custom bitmmap font

4 : Draw sprites from spritesheet

## About the demo 

The demo includes a boot screen, a [sprite editor](#Sprite-Editor), a [map editor](#Level-Editor) and a basic [game engine](#Play) (collision detection, physics... etc.)  

* Use +/- to navigate between sprites.
* Left click to change tile or right click to remove tile.
* Press space to set starting position of character on the map.
* Arrow to move. 
* Z to jump. 
* X to use dash when ready. Up/down arrow to climb plants.
* Escape to quit play mode or sprite editing.

## How to build

You will need **nasm** installed on your computer and a virtual machine that can virtualize a x86 processor (virtual box, Qemu etc...) 

Compile first the bootloader. It will be written in the first sector of the floppy image : 
```
nasm bootloader.asm -f bin -o bootloader.bin
```

Compile the game engine files : 
```
nasm bootscreen.asm -f bin -o bootscreen.bin
```

Concat the two binary files. (Windows users)
```
COPY /B bootloader.bin + bootscreen.bin disk.bin
```

## How to run image file

You can run the disk image on a virtual machine (Qemu example with haxm acceleration)
```
qemu-system-x86_64.exe -fda disk.bin -accel hax
```

You can also boot it directly on your computer using a usb device : move disk.bin to /utils folder and run sectorpadding.exe (or use any software that 
can make disk.bin size a multiple of 512 , then copy the result file to the first sectors of your usb and restart your computer.


### Sprite Editor
![](git-content/spediting.gif)

### Level Editor
![](git-content/mapediting.gif)

### Post-Proccessing
![](git-content/postproc.gif)

### Play 
![](git-content/game.gif)




