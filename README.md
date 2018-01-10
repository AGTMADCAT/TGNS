TGNS
====

Welcome to the [TGNS open-source mods repository][repoannouncethread]. TGNS is [TacticalGamer.com][tg]'s well-known Natural Selection community. This repository houses most of the mods they use on their NS2 server, many of which are built atop Person8880's [Shine Admin Mod][shine].

Some of the more unique customizations on [the TGNS game server][tgns] include:

__Captains__: Start a Captains Game, like a pickup game/gather/dodgeball, wherein teams are picked one at a time by appointed team captains

__WinOrLose__: The losing team can put down their weapons to force a must-end-the-game timer on the winning team

__TagLines__: Players can set text announcements when they join the server

__RookieThrottle__: Keeps the number of concurrent rookies low, so regulars can most effectively help them learn the game

Other offerings include: Admin Chat, distributing rookies to both teams during team random operations, admin notifications of player mutes, and more. Tactical Gamer's [Natural Selection - Tactics and Mod Discussions][modforum] forum welcomes "discussion about Natural Selection tactics, maps, and mods," and community members may request server mod changes there.

[Connect to TGNS via Steam][connect] right away to find out what you're missing!

[modforum]: http://www.tacticalgamer.com/natural-selection-tactics-mod-discussions/
[tgns]: http://www.tacticalgamer.com/natural-selection-general-discussion/189377-tacticalgamer-com-natural-selection-2-server-online.html
[connect]: steam://run/4920//connect%2C+tgns.tacticalgamer.com:27015
[tg]: http://tacticalgamer.com
[repoannouncethread]: http://www.tacticalgamer.com/natural-selection-tactics-mod-discussions/190657-tgns-open-source-mods-repository.html
[shine]: https://github.com/Person8880/Shine

# Development Setup
- Clone this repo to your machine
- Create a shortcut to the NS2.exe. it probably lives somewhere similar to this path:
`C:\Program Files (x86)\Steam\steamapps\common\Natural Selection 2\NS2.exe`
- I suggest renaming this shortcut to `dev` or whatever makes sense to you
- Goto the properties for this shortcut, on the `shortcut` tab add the following to
the `target` field: `-game "C:\Users\your_name\development\TGNS\mods\tgns\output" -debug`.
The new path you are adding here is to the `\mods\tgns\output` folder inside the repo.
The target should look something like this when finished:
`"C:\Program Files (x86)\Steam\steamapps\common\Natural Selection 2\NS2.exe" -game "C:\Users\your_name\development\TGNS\mods\tgns\output" -debug`.
- Add config files to: `"C:\Users\your_name\AppData\Roaming\Natural Selection 2"`.
Much of the TGNS mod works in conjunction with the Shine Administration Mod. Configuring the shine mod
will be done in here as well.
Additionally this is where log files get outputted to, I suggest creating a shortcut
to here as well as it can be helpful to edit the config files or view the logs out of the client.

Use this shortcut while developing and then you can still play ns2 by launching through steam.
The `-game` flag tells NS2 to use the files in the mod directory first, it will fall back to
the ns2 root directory if they don't exist. The `-debug` flag adds additional messaging in the
console and is helpful while developing.

Add other mods by using the `mods` menu in the NS2 client. As mentioned before, this mod works
closely with Shine and requires it. Before you start a map locally to test you need to
enable the Shine mod. From the main menu in the NS2 client, click `mods` and enable `Shine Administration`.

## Useful commands
The following commands are helpful while developing

- `map <ns2_mapname>`: Loads to that map
- `j1` or `jointeamone`: joins marines
- `j2` or `jointeamtwo`: joins aliens

The following require cheats to be enabled

- `sv_cheats 1`: Enables cheats
- `pres 100`: Sets personal res to 100
- `tres 100`: Sets team res to 100
- `<lifeform>`: Will immediately change you to that lifeform e.g. `gorge`
- `alltech`: Unlock all tech upgrades
- `autobuild`: Placed structures automatically spawn built

## Useful links
- [NS2 Wiki Modding](https://wiki.unknownworlds.com/ns2/Modding)
- [How to make a mod tutorial](https://forums.unknownworlds.com/discussion/128106/how-to-make-a-mod-for-natural-selection-2)
- [Modding Framework](https://wiki.unknownworlds.com/ns2/Modding_Framework)
- [Steam Community: Modding Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=802509066)
- [Console Commands](https://wiki.unknownworlds.com/ns2/Console_Commands)
- [Dedicated Server Wiki](https://wiki.unknownworlds.com/ns2/Dedicated_Server)
