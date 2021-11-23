## HackIt Patcher (and template)

[HackIt Patcher](https://github.com/jbop1626/hackit_patcher/blob/master/hackit_patcher.s) is a small MIPS payload which patches the iQue Player [SKSA](http://www.iquebrew.org/index.php?title=SKSA) to remove certain content checks, and causes SKSA to load [tickets](http://www.iquebrew.org/index.php?title=Ticket) from a file named ```hackit.sys```, rather than the default [```ticket.sys```](http://www.iquebrew.org/index.php?title=Ticket.sys). This allows you to launch homemade applications with customized tickets.  

It supports SKSA versions 1095, 1099, 1101, and 1106 (common SKSA versions which support USB).  

Also included is a [template](https://github.com/jbop1626/hackit_patcher/blob/master/template.s) for writing your own SA patcher, which, like HackIt Patcher, uses skGetId as an entry point and a hollowed-out skVerifyHash as the container for the SA patching code.  

### Usage

1. Assemble with [armips](https://github.com/Kingcom/armips).  
2. Set up a game to run code from its savefile (a guide is in the works).  
3. Overwrite the game's savefile on the console with the file of the assembled patcher.  
4. Run the game.  

The game should boot to a black screen. Don't touch anything for about 5 seconds to be safe, then **soft reset** by tapping the power button. This will return to the menu and trigger the patch.  

The patch will be active until the next time the console is *completely* powered off (i.e. it persists through a soft reset). To take advantage of the patch, however, you will also need to transfer to the console a ```hackit.sys``` file and whatever applications you wish to run.  

### License
HackIt Patcher is licensed under the [MIT License](https://github.com/jbop1626/hackit_patcher/blob/master/LICENSE.md).

### More Information
See the comments in [```hackit_patcher.s```](https://github.com/jbop1626/hackit_patcher/blob/master/hackit_patcher.s) and [```template.s```](https://github.com/jbop1626/hackit_patcher/blob/master/template.s), [```iQueBrew/bbp_pocs```](https://github.com/iQueBrew/bbp_pocs), as well as the [iQueBrew wiki](http://www.iquebrew.org).  

