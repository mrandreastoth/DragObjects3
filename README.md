# DragObjects3
Written by [Andreas Toth](https://github.com/mrandreastoth) based on [DragObjects2](http://www.blong.com/conferences/borcon2001/draganddrop/4114.htm) for Delphi.

Tested under Delphi 10.4.2.

## About
Delphi has built-in support for drag-and-drop, however, it is flawed as the move threshold from the start position does not work but instantly starts the drag operation. This demo both demonstrates the issue as well as tries to implement a work-around, something that, at this stage, is only partially successful.

## Usage
Compile and run the software then drag-and-drop any of the objects shown above the panel onto the panel itself. To demonstrate Delphi's drag-and-drop issue, use the automatic mode; and, to test the implementation, use the manual mode.

## Known issues
1. The low-level mouse hook procedure does not always initialize (especially if mouse is moving at the time)!
2. The low-level mouse handler always sets AMessage.Result to 0 which causes issues for some messages (size form to see what happens)!

**WARNING**: Breakpointing in the low-level routines can cause Windows to temporarily/permanently disable the low-level hook!