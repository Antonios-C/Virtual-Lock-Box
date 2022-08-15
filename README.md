# Virtual Lock Box

This program was written, tested and compiled within a virtual 7 segment display FPGA simulator.

Simulator used : https://github.com/norandomtechie/ece270-simulator

## Image of Simulator
![image](https://user-images.githubusercontent.com/96555013/184593988-d0664d27-d653-4eff-bd5c-0f8d95ee7a97.png)


## General Functions

Within the program you can set a passcode, lock the box and unlock the box with said passcode. At the start of the program you are prompted to set a passcode
and press the "W" button. Pressing the "W" button only in this instance will lock the box. if "W" button is pressed at a different time after the passcode is set it will unlock
box, assuming entered passcode is correct. Once the box is unlocked the user cannot enter the passcode, they need to lock the box again. If the box is locked and an incorrect
passcode is entered an "alarm" will go off. 

### Light Modes:
1) Red : Alarm going off
2) Green : Unlocked box
3) Blue : Locked box 
4) No Light : User needs to set passcode

### Button Purposes: 

1) Buttons 0 - "F" can be pressed to enter/set passcode 
2) Button "X" is backspace button incase you want to delete the last character 
3) Button "W" unlocks the box 
4) Button "Y" locks the box

## Demo 

https://user-images.githubusercontent.com/96555013/184594631-0d182367-5652-49a3-8472-344922906825.mp4

