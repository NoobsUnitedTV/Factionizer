Factionizer - A faction reputation management tool
--------------------------------------------------

History
-------
On August 10 2007 john.ra reported in alt.games.warcraft the URL of
the following reputation calculator.

	http://reputation.mygamesonline.org/

I thought it was awseome. Unfortunately it went offline for quite some time
due to over-traffic and during that time I had the idea that it would be
very neat to have something like this, especially considering that the
information to calculate everything was more or less available from the
WoWWiki faction pages.

Urbin, Dun-Morogh (EU)

Features
--------
This addon displays how many reputation points are missing to the next
reputation level in your reputation window. In addition, it extends the
reputation detail window by showing how many points you need for your
next reputation level and how you can best gain this reputation.

Thanks
------
To Shanti, Luidor/Dougi and Milamber of <Hüter des weißen Feuers>, Syrenia of <Orden des Blutraben> and Tattoo of <Dark Desire> of EU-Dun Morogh for their help on localising the faction names.
Catriona from alt.games.warcraft for helping me test the guild reputation cap feature.

on curse:
Caraxe for finding solution to the lfg/gc problem and german locals
Zakhai for the Brazilian Portuguese locals
Elandril for german locals
Elpiase for starting Italian
Mednik for helping with Russian
Boneseater for starting French

Sources
-------
All information regarding the reputation gained for each faction comes
from http://www.wowjuju.com/. Localisation of quests, mobs
and items come from www.WoWhead.com. Old help http://www.wowwiki.com/Faction.

Slash commands
--------------
/fz help	Show supported slash commands
/fz about	Show version info
/fz status	Show configuration status
/fz enable | disable | toggle <setting>
	<setting>	Enable/Disable/Toggle showing of
			mobs
			items
			quests
			instances | dungeons
				that give reputation gains
	<setting>
	missing	Missing reputation text in reputation frame
	details	Extended reputation detail frame
	chat	Extended reputation gain chat message
	suppress	Suppress original reputation gain chat message
	all	Include all <settings> in enable/disable/toggle
/fz list		Show list of all factions grouped by standing
/fz list <standing>	Show list of all factions with wich you have the given standing

Todo list
---------
- add item tooltips to show what they can be used for [low prio]
- add about, history, todo frames [low prio]
- add limit numbers for timbermaw, aldor, sha'tar rep

Localisations
- added built in localisation 06/01/13
- adding built in localisation 05/06/13

Bugs/Features
- fixing "order by standing*