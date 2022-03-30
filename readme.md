# **Continue Plugin for MAME** #

This plugin adds a continue feature to some classic arcade games. 

The continue option will appear before your game is over with a 10 second countdown timer.  Simply push the *P1 Start* button to continue your game and your score will be reset.

A tally of the number of continues made will appear at the top of the screen.


![Continue Plugin Screenshot](https://i.imgur.com/4rnfvYl.png)


The plugin currently supports these games:

- Pac-Man
- Ms. Pac-Man
- Galaga
- Galaxians
- Frogger
- Q*bert
- Donkey Kong
- Donkey Kong Junior
- Robotron
- Sinistar
- Berzerk
- Missile Command
- Centipede
- Battlezone
- Asteroids
- Crazy Climber
- Space Invaders

Other variants of these games are also supported (including):
- Pac-Man Plus
- Ms. Pac-Man Attack
- Pac-Man and Ms. Pac-Man Speed Up Hacks
- Super Missile Attack
- Galaga Fast Shoot Hack
- Super Galaxians
- Moon Alien
- DK II Jumpman Returns 
- DK Remix Editions


Tested with latest MAME version 0.241

Compatible with all MAME versions from 0.196

  
## Installing and running
 
The Plugin is installed by copying the "continue" folder into your MAME plugins folder.

The Plugin is run by adding `-plugin continue` to your MAME arguments e.g.

```mame mspacman -plugin continue```  


## Thanks to

The MAMEdev team 
- https://docs.mamedev.org/

Scott Lawrence (BleuLlama) for Pac-Man/Ms.Pac-Man ROM Disassembly resources at:
- https://github.com/BleuLlama/GameDocs/blob/master/disassemble/mspac.asm

Scott Tunstall Galaxians, Robotron and Berzerk ROM disassembly resources at:
- http://seanriddle.com/willy3.html#soft

Kef Schecter (furrykey) for Donkey Kong ROM disassembly resources at:
- https://github.com/furrykef/dkdasm/blob/master/dkong.asm

Rich McFerron for Space Invaders and Crazy Climber ROM disassembly resources at:
- https://computerarcheology.com/Arcade/

nmikstas for Asteroids ROM disassembly resources at:
- https://github.com/nmikstas/asteroids-disassembly/tree/master/AsteroidsSource

hackbar and neiderm for Galaga ROM disassembly resources at:
- https://github.com/hackbar/galaga

Andy McFadden for Missile Command, Centipede and Battlezone ROM disassembly resources at:
- https://6502disassembly.com/va-missile-command/

Historical Source for Sinistar source code at:
https://github.com/historicalsource/sinistar


## What's next

I would like to add support for other classic games.
Let me know if you have any requests.  It greatly helps when there is a rom disassembly available.


## Feedback

Please send feedback to jon123wilson@hotmail.com

Jon

