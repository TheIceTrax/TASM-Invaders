# TASM-SpaceInvaders
A simple Space Invaders like game made in 16BIT Assembly.

You are a spaceship and you need to shoot aliens. If the aliens reaches you you die.
![Main Menu](https://github.com/TheIceTrax/TASM-SpaceInvaders/blob/guide/Gameplay.png?raw=true)
# How to install
## Windows
Download the package in Releases, unzip and run "dosbox.exe".
## Manual
If you are not on windows, or prefer manually install.
- You need to have [dosbox](https://www.dosbox.com/download.php?main=1 "dosbox") installed.
- The game is intended to be played in 5000 cycles. Please change the cycles on dosbox options from AUTO/other value to be 5000 (under cpu options).

------------

After you have dosbox setup, download [TASM](http://data.cyber.org.il/assembly/TASM.rar "TASM") into a directory and place the source files in the same directory.
In order to compile the game execute these commands:
```bash
tasm /zi GAME.asm
tlink /v GAME.obj
```
To start the game simply run `GAME`.

# Customizing the game
The file "VARS.dat" (Located at game) contains variables that you may change in order to change your expirience.
![Modifiable variables](https://github.com/TheIceTrax/TASM-SpaceInvaders/blob/guide/vars.png?raw=true "Modifiable variables")
