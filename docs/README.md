Lua Plugin Dependency list:
---------------------------

Here is a list of Lua Plugin dependencies of the codebase as a starting point to understanding the code a bit better. There may be errors in this list due to the simplistic way it was generated. Refinement can be done if examples of errors are found. 

Contact [OrigamiPaper](https://github.com/OrigamiPaper) if you find any missing dependencies so he can fix the list and the way the are parsed. In general, OrigamiPaper doesn't know too much about ns2 modding or Lua so he might need a little help understanding how everything ties together.

Modules, in the true lua sense, are not used very much. Thus, tools like [depgraph](https://github.com/mpeterv/depgraph) is don't give a good picture of the codebase. That is simply the way either ns2 or shine is designed it seems.

Important note: The plugin name is what [Wyzcrak](https://github.com/lancehilliard) calls the extension/plugin in his code but they do not always correspond to a lua script. This is evident on the graph I hacked together from that is based on the table.

### Where Plugins are used/called:

| Filename                                          | Plugin                  |
|---------------------------------------------------|-------------------------|
| shine/extensions/afkkickhelper.lua                | afkkick                 |
| shine/extensions/afkkickhelper.lua                | arclight                |
| shine/extensions/afkkickhelper.lua                | captains                |
| shine/extensions/afkkickhelper.lua                | scoreboard              |
| shine/extensions/afkkickhelper.lua                | timedstart              |
| shine/extensions/arclight/arclight.lua            | arclight                |
| shine/extensions/arclight/arclight.lua            | bots                    |
| shine/extensions/arclight/arclight.lua            | captains                |
| shine/extensions/arclight/arclight.lua            | communityslots          |
| shine/extensions/arclight/arclight.lua            | mapvote                 |
| shine/extensions/arclight/arclight.lua            | winorlose               |
| shine/extensions/audit.lua                        | captains                |
| shine/extensions/audit.lua                        | communityslots          |
| shine/extensions/audit.lua                        | tf_comeback             |
| shine/extensions/autoexec/client.lua              | autoexec                |
| shine/extensions/autoexec/server.lua              | autoexec                |
| shine/extensions/balance/balance.lua              | arclight                |
| shine/extensions/balance/balance.lua              | balance                 |
| shine/extensions/balance/balance.lua              | captains                |
| shine/extensions/balance/balance.lua              | communityslots          |
| shine/extensions/balance/balance.lua              | mapvote                 |
| shine/extensions/balance/balance.lua              | scoreboard              |
| shine/extensions/balance/balance.lua              | sidebar                 |
| shine/extensions/balance/balance.lua              | updatetoreadyroomhelper |
| shine/extensions/balance/balance.lua              | voterandom              |
| shine/extensions/betterknownas.lua                | betterknownas           |
| shine/extensions/bots.lua                         | bots                    |
| shine/extensions/bots.lua                         | captains                |
| shine/extensions/bots.lua                         | forceroundstart         |
| shine/extensions/bots.lua                         | mapvote                 |
| shine/extensions/bots.lua                         | push                    |
| shine/extensions/bots.lua                         | sidebar                 |
| shine/extensions/bots.lua                         | winorlose               |
| shine/extensions/captains/captains.lua            | afkkick                 |
| shine/extensions/captains/captains.lua            | captains                |
| shine/extensions/captains/captains.lua            | mapvote                 |
| shine/extensions/captains/captains.lua            | push                    |
| shine/extensions/captains/captains.lua            | scoreboard              |
| shine/extensions/captains/captains.lua            | sidebar                 |
| shine/extensions/captains/captains.lua            | spawnselectionoverrides |
| shine/extensions/captains/captains.lua            | timedstart              |
| shine/extensions/captains/captains.lua            | updatetoreadyroomhelper |
| shine/extensions/chatchannels.lua                 | chatchannels            |
| shine/extensions/communityslots.lua               | betterknownas           |
| shine/extensions/communityslots.lua               | bots                    |
| shine/extensions/communityslots.lua               | captains                |
| shine/extensions/communityslots.lua               | chatchannels            |
| shine/extensions/communityslots.lua               | communityslots          |
| shine/extensions/communityslots.lua               | karma                   |
| shine/extensions/communityslots.lua               | newcomms                |
| shine/extensions/communityslots.lua               | scoreboard              |
| shine/extensions/communityslots.lua               | sidebar                 |
| shine/extensions/communityslots.lua               | teamres                 |
| shine/extensions/crashreconnect/client.lua        | serverstart             |
| shine/extensions/damagemodifier.lua               | lapstracker             |
| shine/extensions/damagemodifier.lua               | winorlose               |
| shine/extensions/fullgameplayed.lua               | communityslots          |
| shine/extensions/gorgetunnelhelper/client.lua     | scoreboard              |
| shine/extensions/greetings.lua                    | betterknownas           |
| shine/extensions/groundedrookies.lua              | bots                    |
| shine/extensions/groundedrookies.lua              | communityslots          |
| shine/extensions/groundedrookies.lua              | scoreboard              |
| shine/extensions/hidefullmodlist.lua              | push                    |
| shine/extensions/infestedhelper/server.lua        | mapvote                 |
| shine/extensions/karma.lua                        | bots                    |
| shine/extensions/karma.lua                        | captains                |
| shine/extensions/karma.lua                        | communityslots          |
| shine/extensions/karma.lua                        | karma                   |
| shine/extensions/karma.lua                        | push                    |
| shine/extensions/lapstracker.lua                  | lapstracker             |
| shine/extensions/lapstracker.lua                  | scoreboard              |
| shine/extensions/mapvotehelper.lua                | arclight                |
| shine/extensions/mapvotehelper.lua                | captains                |
| shine/extensions/mapvotehelper.lua                | infestedhelper          |
| shine/extensions/mapvotehelper.lua                | mapvote                 |
| shine/extensions/newcomms/server.lua              | newcomms                |
| shine/extensions/newcomms/server.lua              | scoreboard              |
| shine/extensions/permissions.lua                  | permissions             |
| shine/extensions/pregamescoreboardsort/client.lua | pregamescoreboardsort   |
| shine/extensions/printablenames.lua               | printablenames          |
| shine/extensions/recordinghelper/client.lua       | scoreboard              |
| shine/extensions/recordinghelper/server.lua       | recordinghelper         |
| shine/extensions/restartwhenempty/server.lua      | mapvote                 |
| shine/extensions/scoreboard/client.lua            | scoreboard              |
| shine/extensions/scoreboard/client.lua            | squadnumbers            |
| shine/extensions/scoreboardicons.lua              | scoreboardicons         |
| shine/extensions/scoreboard/server.lua            | afkkick                 |
| shine/extensions/scoreboard/server.lua            | betterknownas           |
| shine/extensions/scoreboard/server.lua            | captains                |
| shine/extensions/scoreboard/server.lua            | newcomms                |
| shine/extensions/scoreboard/server.lua            | scoreboard              |
| shine/extensions/scoreboard/server.lua            | speclisten              |
| shine/extensions/scoreboard/server.lua            | squadnumbers            |
| shine/extensions/scoreboard/server.lua            | targetedcommands        |
| shine/extensions/scoreboard/server.lua            | voicecommreminder       |
| shine/extensions/serverstart/client.lua           | crashreconnect          |
| shine/extensions/serverstart/client.lua           | serverstart             |
| shine/extensions/serverstart/server.lua           | mapvote                 |
| shine/extensions/serverstart/server.lua           | push                    |
| shine/extensions/sidebar.lua                      | basecommands            |
| shine/extensions/siegehelper.lua                  | communityslots          |
| shine/extensions/siegehelper.lua                  | sidebar                 |
| shine/extensions/specbets.lua                     | mapvote                 |
| shine/extensions/speclisten.lua                   | sidebar                 |
| shine/extensions/speclisten.lua                   | speclisten              |
| shine/extensions/sprayhelper/client.lua           | readyroomrave           |
| shine/extensions/sprayhelper/server.lua           | readyroomrave           |
| shine/extensions/squadnumbers/server.lua          | captains                |
| shine/extensions/squadnumbers/server.lua          | scoreboard              |
| shine/extensions/stagedteamjoins.lua              | captains                |
| shine/extensions/stagedteamjoins.lua              | mapvote                 |
| shine/extensions/taglines.lua                     | betterknownas           |
| shine/extensions/targetedcommands.lua             | scoreboard              |
| shine/extensions/targetedcommands.lua             | targetedcommands        |
| shine/extensions/td/td.lua                        | td                      |
| shine/extensions/teamroles.lua                    | betterknownas           |
| shine/extensions/teamroles.lua                    | scoreboard              |
| shine/extensions/teamswitch.lua                   | captains                |
| shine/extensions/teamswitch.lua                   | timedstart              |
| shine/extensions/tgnsbadges/server.lua            | mapvote                 |
| shine/extensions/tgnsbadges/server.lua            | tgnsbadges              |
| shine/extensions/timedstart.lua                   | afkkickhelper           |
| shine/extensions/timedstart.lua                   | arclight                |
| shine/extensions/timedstart.lua                   | bots                    |
| shine/extensions/timedstart.lua                   | captains                |
| shine/extensions/timedstart.lua                   | communityslots          |
| shine/extensions/timedstart.lua                   | mapvote                 |
| shine/extensions/timedstart.lua                   | timedstart              |
| shine/extensions/voicecommreminder.lua            | scoreboard              |
| shine/extensions/winorlose.lua                    | arclight                |
| shine/extensions/winorlose.lua                    | communityslots          |
| shine/extensions/winorlose.lua                    | scoreboard              |
| shine/extensions/winorlose.lua                    | winorlose               |
| shine/extensions/wraplength/client.lua            | wraplength              |
| shine/extensions/wraplength/server.lua            | wraplength              |
| tgns/server/TGNSClientKicker.lua                  | ban                     |
| tgns/server/TGNSCommonServer.lua                  | afkkick                 |
| tgns/server/TGNSCommonServer.lua                  | ban                     |
| tgns/server/TGNSCommonServer.lua                  | improvedafkhandler      |
| tgns/server/TGNSCommonServer.lua                  | karma                   |
| tgns/server/TGNSCommonServer.lua                  | mapvote                 |
| tgns/server/TGNSCommonServer.lua                  | permissions             |
| tgns/server/TGNSCommonServer.lua                  | scoreboard              |
| tgns/server/TGNSCommonServer.lua                  | tempgroups              |
| tgns/server/TGNSConnectedTimesTracker.lua         | bots                    |

### List of filenames where plugin is registered:

| Filename (shine/extensions)      | plugin                  |
|----------------------------------|-------------------------|
| adminmenu/shared.lua             | adminmenu               |
| afkchanged.lua                   | afkchanged              |
| afkkickhelper.lua                | afkkickhelper           |
| arclight/arclight.lua            | arclight                |
| audit.lua                        | audit                   |
| autoexec/shared.lua              | autoexec                |
| autospec/shared.lua              | autospec                |
| balance/balance.lua              | balance                 |
| betterknownas.lua                | betterknownas           |
| bots.lua                         | bots                    |
| broadcast.lua                    | broadcast               |
| captains/captains.lua            | captains                |
| chatchannels.lua                 | chatchannels            |
| communityslots.lua               | communityslots          |
| crashreconnect/shared.lua        | crashreconnect          |
| damagemodifier.lua               | damagemodifier          |
| disablestockmapvote.lua          | disablestockmapvote     |
| emptymapcycler.lua               | emptymapcycler          |
| enforceteamsizes.lua             | enforceteamsizes        |
| everysecond/shared.lua           | everysecond             |
| forceroundstart.lua              | forceroundstart         |
| friendlyfiretweaks.lua           | friendlyfiretweaks      |
| fullgameplayed.lua               | fullgameplayed          |
| gamestartevents.lua              | gamestartevents         |
| gamestracker.lua                 | gamestracker            |
| gorgetunnelhelper/shared.lua     | gorgetunnelhelper       |
| greetings.lua                    | greetings               |
| groundedrookies.lua              | groundedrookies         |
| help.lua                         | help                    |
| hidefullmodlist.lua              | hidefullmodlist         |
| hidespectators.lua               | hidespectators          |
| improvedafkhandler.lua           | improvedafkhandler      |
| infestedhelper/shared.lua        | infestedhelper          |
| karma.lua                        | karma                   |
| lapstracker.lua                  | lapstracker             |
| lookdown.lua                     | lookdown                |
| mapvotehelper.lua                | mapvotehelper           |
| modupdatednotice.lua             | modupdatednotice        |
| movement/movement.lua            | movement                |
| newcomms/shared.lua              | newcomms                |
| noattackpregame.lua              | noattackpregame         |
| notifyadminonmuteplayer.lua      | notifyadminonmuteplayer |
| perficon/shared.lua              | perficon                |
| permissions.lua                  | permissions             |
| playerlocationchanged.lua        | playerlocationchanged   |
| pregamescoreboardsort/shared.lua | pregamescoreboardsort   |
| primeablechat/primeablechat.lua  | primeablechat           |
| printablenames.lua               | printablenames          |
| prohibitednames.lua              | prohibitednames         |
| push.lua                         | push                    |
| recordinghelper/shared.lua       | recordinghelper         |
| reluse.lua                       | reluse                  |
| restartwhenempty/shared.lua      | restartwhenempty        |
| rookiethrottle.lua               | rookiethrottle          |
| rotatingeggspawns/shared.lua     | rotatingeggspawns       |
| scoreboardicons.lua              | scoreboardicons         |
| scoreboard/shared.lua            | scoreboard              |
| serverstart/shared.lua           | serverstart             |
| sidebar.lua                      | sidebar                 |
| siegehelper.lua                  | siegehelper             |
| spawnselectionoverrides.lua      | spawnselectionoverrides |
| specbets.lua                     | specbets                |
| speclimit.lua                    | speclimit               |
| speclisten.lua                   | speclisten              |
| sprayhelper/shared.lua           | sprayhelper             |
| squadnumbers/shared.lua          | squadnumbers            |
| stagedteamjoins.lua              | stagedteamjoins         |
| statusextended.lua               | statusextended          |
| taglines.lua                     | taglines                |
| targetedcommands.lua             | targetedcommands        |
| td/td.lua                        | td                      |
| teamres.lua                      | teamres                 |
| teamroles.lua                    | teamroles               |
| teamswitch.lua                   | teamswitch              |
| teamticker.lua                   | teamticker              |
| tempgroups.lua                   | tempgroups              |
| tgnsbadges/shared.lua            | tgnsbadges              |
| timedstart.lua                   | timedstart              |
| updatetoreadyroomhelper.lua      | updatetoreadyroomhelper |
| uweranking.lua                   | uweranking              |
| voicecommreminder.lua            | voicecommreminder       |
| winorlose.lua                    | winorlose               |
| wraplength/shared.lua            | wraplength              |

Missing plugins from this list are likely built into shine already or in ns2 itself.

### Plugin Dependency Graph:
<img src="./PluginsAssociationProcessedv2.svg">

A plugin dependency graph based on the lua file names and referenced Shine.Plugin objects. The lua file connected is to the place where the plugin is registered (i.e. initally defined). If the plugin has no file where it was registered it will not have a lua file assocated. These cases are probably built in to NS2 or Shine in some way. Plugins that are not referenced anywhere but their own lua file are not included in this graph. This graph does not include lua files that load other lua scripts (see lua/tgns folder for examples).

### How files were generated:
Here are some bash commands I ran to generate the raw files used to generate tables and graphs. It is somewhat incomplete but I hope that it will answer questions to explain what I parsed for in the files.
```{bash}
cd docs
find ../* | grep "\.lua" > all_lua.txt
cat all_lua.txt | xargs grep -oP "Shine.Plugins\.[^\s.:[]+" | sort -u > PluginsAssociationRaw.txt
cat all_lua.txt | xargs grep -oP "Shine.RegisterExtension\([^\n]+\)" | sort -u | sed -rn 's/\.\.\/mods\/tgns\/output\/lua\/shine\/extensions\/([^:]+):Shine:RegisterExtension\(\s*"([^"]+)"\s*,\s*Plugin\s*\)/\1\t\2/p' > ShinePluginRegistration.tsv
grep -v -Ff ShinePluginRegistration.tsv PluginsAssociationProcessed.txt > PluginsAssociationProcessed_noSelfConnect.tsv
awk '{print$1}' ShinePluginRegistration.tsv > ShinePluginRegistration_filenamesOnly.txt
grep -vFf ShinePluginRegistration_filenamesOnly.txt PluginsAssociationProcessed.txt | awk '{print $1}' | sort -u > PluginsAssociationFilesNoRegistration.txt
```

The rest is some ad hoc regex with a text editor, graphviz and gvpr to generate a dot file.
