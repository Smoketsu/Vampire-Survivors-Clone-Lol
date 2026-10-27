## UnlockData — level-up items that must be UNLOCKED before a run offers them
## (GDD §15.0 "Act II: the Ancient Eye", owner-approved "Unlockable spells and
## passives"): Act II's three abyssal spells (each unlocked by slaying one of
## the act's bosses), its two counter-passives (each earned by an Act II
## achievement) and the two new summon classes. An id absent here is always
## open, so every Act I item, and a fresh save's card pool, is exactly as
## before. Unlocks are kept in the Meta [unlocks] save section
## (MetaProgress.unlocked_items), read through the ONE helper Unlocks.is_open(),
## and announced by an end-screen unlock plate; the Codex shows a locked item
## as a silhouette naming its unlock (`text`).
## Keys of a row:
##   type        — "spell" (AbilityData), "passive" (PassiveData) or "class"
##                 (UnitData): which card table the id belongs to; or an
##                 achievement reward type (REWARD_TYPES, content wave 2):
##                 "ultimate", "title" (TitleData) or "skin" (SkinData).
##   name        — UI name of an "ultimate" row (the others name themselves
##                 through their own table; Unlocks.item_name()).
##   boss        — boss script id (StageRegistry.BOSS_ARRIVALS): slaying it in
##                 any run unlocks the item; or
##   achievement — MetaData.ACHIEVEMENTS id: earning it unlocks the item.
##   text        — the unlock condition, for the Codex and the plate.
## Act-only items (offered only on one act's stages) are marked by their own
## card row's "act" key (PassiveData / AbilityData / UnitData), not here.
## Rows are added by each Act II stage as its items are built.
class_name UnlockData
extends RefCounted

## Item id -> unlock row (keys above).
const UNLOCKS := {
	# --- Act II: Fallen Seraph ---
	# Grand Inquisitor Seraphine's gift (GDD §15.0 "Fallen Seraph"): her fall
	# raises a corrupted angel for the necromancer, with its paired passive.
	# Offered on every stage (no card-row "act" key). A save that slew her
	# before these rows existed has them open at once (MetaProgress
	# _load_unlocks(): her stage record shows the kill).
	"fallen_seraph": {"type": "class", "boss": "seraphine", "text": "Slay Grand Inquisitor Seraphine."},  # TUNING (not in GDD)
	"fallen_grace": {"type": "passive", "boss": "seraphine", "text": "Slay Grand Inquisitor Seraphine."},  # TUNING (not in GDD)
	# --- Act II: Gullhaven Harbour ---
	"undertow": {"type": "spell", "boss": "merrow", "text": "Slay Abbot Silas Merrow in Gullhaven Harbour to unlock."},  # owner-approved
	"salt_of_the_deep": {"type": "passive", "boss": "merrow", "text": "Slay Abbot Silas Merrow in Gullhaven Harbour to unlock."},  # Undertow's paired passive, unlocked with it
	"brinewalker": {"type": "passive", "achievement": "low_tide", "text": "Earn Low Tide: clear Gullhaven Harbour."},  # owner-approved
	# --- Act II: the Hollow Archive ---
	"forbidden_verse": {"type": "spell", "boss": "archivist", "text": "Slay the Archivist in the Hollow Archive to unlock."},  # Owner-approved proposal
	"marginalia": {"type": "passive", "boss": "archivist", "text": "Slay the Archivist in the Hollow Archive to unlock."},  # Forbidden Verse's paired passive, unlocked with it
	"iron_mind": {"type": "passive", "achievement": "nothing_unwritten", "text": "Earn Nothing Unwritten: burn every forbidden tome in one Hollow Archive run."},  # Owner-approved proposal
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"call_of_the_drowned": {"type": "spell", "boss": "vhalneth", "text": "Slay Vhal'Neth, the Dreaming Mother, on Ul-Thalos."},  # Proposal: unlocked by defeating Vhal'Neth
	"abyssal_pact": {"type": "passive", "boss": "vhalneth", "text": "Slay Vhal'Neth, the Dreaming Mother, on Ul-Thalos."},  # TUNING (not in GDD) with its spell
	"spawn_of_the_deep": {"type": "class", "boss": "vhalneth", "text": "Slay Vhal'Neth, the Dreaming Mother, on Ul-Thalos."},  # Proposal decision 5: the finale's reward
	"crushing_depths": {"type": "passive", "boss": "vhalneth", "text": "Slay Vhal'Neth, the Dreaming Mother, on Ul-Thalos."},  # TUNING (not in GDD) with its class
	# --- Content wave 2: B. Achievement rewards ---
	# Achievement rewards (owner-approved Proposal 2, GDD §15.0 "Achievement
	# rewards (content wave 2)"): options and cosmetics only, never raw power.
	# Three more types (REWARD_TYPES): "ultimate" (UltimateData id; the pre-run
	# ultimate picker asks Unlocks.is_open(); `name` is its UI name), "title"
	# (TitleData id; its name comes from TitleData) and "skin" (a SkinData
	# UNIVERSAL_SKINS family id: that look for every character). A save that
	# earned the achievement before a row existed has the reward at once
	# (MetaProgress._load_unlocks()).
	"sovereigns_decree": {"type": "ultimate", "achievement": "dread_sovereign", "name": "Sovereign's Decree",
		"text": "Earn Dread Sovereign: slay a stage boss while commanding Warriors, Archers, Mages and a priest order."},  # owner-approved Proposal 2
	"eclipse": {"type": "ultimate", "achievement": "dawn_extinguished", "name": "Eclipse",
		"text": "Earn Dawn Extinguished: defeat Grand Inquisitor Seraphine."},  # owner-approved Proposal 2
	"grave_tide": {"type": "ultimate", "achievement": "mass_grave", "name": "Grave Tide",
		"text": "Earn Mass Grave: raise 500 temporary undead in one run."},  # owner-approved Proposal 2
	"heretics_bane": {"type": "title", "achievement": "heretics_bane",
		"text": "Earn Heretic's Bane: defeat 500 Covenant Chaplains."},  # owner-approved Proposal 2
	"master_of_the_drowned": {"type": "title", "achievement": "the_dead_god_serves",
		"text": "Earn The Dead God Serves: slay Vhal'Neth on Ul-Thalos."},  # owner-approved Proposal 2
	"archnecromancer": {"type": "title", "achievement": "full_ossuary",
		"text": "Earn Full Ossuary: hold 4 evolutions at once in one run."},  # owner-approved Proposal 2
	"executioner": {"type": "title", "achievement": "swift_judgment",
		"text": "Earn Swift Judgment: slay a stage boss within 45 s of its arrival."},  # owner-approved Proposal 2
	"untouchable": {"type": "skin", "achievement": "untouchable",
		"text": "Earn Untouchable: reach 0:00 without dropping below half health."},  # owner-approved Proposal 2
	"deathlord": {"type": "skin", "achievement": "deathlords_due",
		"text": "Earn Deathlord's Due: clear any stage on Deathlord difficulty."},  # owner-approved Proposal 2
	# --- Content wave 2: Bone Golem ---
	# The Bone Legion achievement's reward (owner decision, GDD §15.0 "Content
	# wave 2"): the Bone Golem and its paired passive, offered on every stage.
	"bone_golem": {"type": "class", "achievement": "bone_legion", "text": "Earn Bone Legion: Skeleton Warriors slay 1,000 foes."},  # Owner-approved proposal 5
	"grave_masonry": {"type": "passive", "achievement": "bone_legion", "text": "Earn Bone Legion: Skeleton Warriors slay 1,000 foes."},  # Its paired passive, unlocked with it
	# --- Act III: the Assembly Halls ---
	# The Motherboard's gifts (owner-approved Act III proposal "Rewards"): the
	# spell Hollow Puppet and the summon class Grave Drone, each with its
	# paired passive; Cold Assembly's counter-passive Signal Ghost ("act": 3 on
	# its card row: offered only on Act III stages).
	"hollow_puppet": {"type": "spell", "boss": "motherboard", "text": "Shut down the Motherboard in the Assembly Halls to unlock."},  # Owner-approved proposal
	"strings_of_the_dead": {"type": "passive", "boss": "motherboard", "text": "Shut down the Motherboard in the Assembly Halls to unlock."},  # Hollow Puppet's paired passive, unlocked with it
	"grave_drone": {"type": "class", "boss": "motherboard", "text": "Shut down the Motherboard in the Assembly Halls to unlock."},  # Owner-approved proposal
	"overclock": {"type": "passive", "boss": "motherboard", "text": "Shut down the Motherboard in the Assembly Halls to unlock."},  # The Grave Drone's paired passive, unlocked with it
	"signal_ghost": {"type": "passive", "achievement": "cold_assembly", "text": "Earn Cold Assembly: destroy every fabricator in one Assembly Halls run."},  # Owner-approved proposal
	# --- Act III: the Scrap Wastes ---
	# Kestrel's gift (owner-approved Act III proposal "Rewards": Death Ray is
	# unlocked by Kestrel, the Dead Pixel) with its paired passive, offered on
	# every stage; the stage's achievement earns Act III's first
	# counter-passive (offered only in Act III through its card row's "act").
	"death_ray": {"type": "spell", "boss": "kestrel", "text": "Slay Kestrel, the Dead Pixel, in the Scrap Wastes to unlock."},  # Owner-approved Act III proposal
	"conductive_marrow": {"type": "passive", "boss": "kestrel", "text": "Slay Kestrel, the Dead Pixel, in the Scrap Wastes to unlock."},  # Death Ray's paired passive, unlocked with it
	"lead_lined_bones": {"type": "passive", "achievement": "static_in_the_wastes", "text": "Earn Static in the Wastes: clear the Scrap Wastes."},  # Owner-approved Act III proposal
	# --- Act III: the Iron Citadel ---
	# Deus Ex Machina's fall (owner-approved Act III proposal): the spell Scrap
	# Swarm with its paired passive, and the finale's summon class with its
	# paired passive, offered on every stage (no card-row "act" key). The title
	# Breaker of Engines is the Nothing Is Deathless achievement's reward.
	"scrap_swarm": {"type": "spell", "boss": "deus_ex_machina", "text": "Defeat Deus Ex Machina in the Iron Citadel to unlock."},  # Owner-approved proposal
	"machine_soul": {"type": "passive", "boss": "deus_ex_machina", "text": "Defeat Deus Ex Machina in the Iron Citadel to unlock."},  # Scrap Swarm's paired passive, unlocked with it
	"iron_revenant": {"type": "class", "boss": "deus_ex_machina", "text": "Defeat Deus Ex Machina in the Iron Citadel to unlock."},  # Owner-approved proposal: the finale's reward
	"recoil_frame": {"type": "passive", "boss": "deus_ex_machina", "text": "Defeat Deus Ex Machina in the Iron Citadel to unlock."},  # Its paired passive, unlocked with it
	"breaker_of_engines": {"type": "title", "achievement": "nothing_is_deathless",
		"text": "Earn Nothing Is Deathless: defeat Deus Ex Machina in the Iron Citadel."},  # Owner-approved proposal
	# --- Act IV: the Shores of Ilion ---
	# Achilles' fall (owner-approved Act IV proposal "Rewards": Paris's Arrow is
	# unlocked by Achilles) with its paired passive, offered on every stage; the
	# stage's achievement Heel Found earns the counter-passive Bronze Breaker
	# (offered only in Act IV through its card row's "act").
	"paris_arrow": {"type": "spell", "boss": "achilles", "text": "Slay Achilles on the Shores of Ilion to unlock."},  # Owner-approved Act IV proposal
	"mortal_heel": {"type": "passive", "boss": "achilles", "text": "Slay Achilles on the Shores of Ilion to unlock."},  # Paris's Arrow's paired passive, unlocked with it
	"bronze_breaker": {"type": "passive", "achievement": "heel_found", "text": "Earn Heel Found: slay Achilles with a blow to his back or heel."},  # Owner-approved Act IV proposal
	# --- Act IV: Mount Olympus ---
	# Zeus's fall (owner-approved Act IV proposal "Rewards": Stolen Thunder is
	# unlocked by Zeus) with its paired passive, offered on every stage; the
	# stage's achievement Twilight of the Gods earns Act IV's counter-passive
	# Grounded Bones (offered only in Act IV through its card row's "act").
	"stolen_thunder": {"type": "spell", "boss": "zeus", "text": "Slay Zeus on Mount Olympus to unlock."},  # Owner-approved Act IV proposal
	"titans_blood": {"type": "passive", "boss": "zeus", "text": "Slay Zeus on Mount Olympus to unlock."},  # Stolen Thunder's paired passive, unlocked with it
	"grounded_bones": {"type": "passive", "achievement": "twilight_of_the_gods", "text": "Earn Twilight of the Gods: clear the Pantheon Trial on Mount Olympus."},  # Owner-approved Act IV proposal
	# --- Act IV: the Asphodel Underworld ---
	# Hades' fall (owner-approved Act IV proposal "Rewards": River Styx is
	# unlocked by Hades; the finale grants the Myrmidon Shades): the spell with its
	# paired passive, and the summon class with its paired passive, offered on
	# every stage (no card-row "act" key). The Empty Throne achievement opens the
	# Act IV epilogue part (EpilogueData.ACT4_PART), not an unlock row.
	"river_styx": {"type": "spell", "boss": "hades", "text": "Make Hades kneel in the Asphodel Underworld to unlock."},  # Owner-approved proposal
	"ferrymans_toll": {"type": "passive", "boss": "hades", "text": "Make Hades kneel in the Asphodel Underworld to unlock."},  # River Styx's paired passive, unlocked with it
	"myrmidon_shade": {"type": "class", "boss": "hades", "text": "Make Hades kneel in the Asphodel Underworld to unlock."},  # Owner-approved proposal: the finale's reward
	"myrmidon_oath": {"type": "passive", "boss": "hades", "text": "Make Hades kneel in the Asphodel Underworld to unlock."},  # Its paired passive (own decision), unlocked with it
	# --- Act V: the Burning Province ---
	# Kage's fall (owner-approved Act V proposal "Rewards": Hundred Shadows is
	# unlocked by Kage) with its paired passive, offered on every stage; the
	# stage's achievement No Shadow Unlit earns Act V's counter-passive Paper
	# Lanterns (offered only in Act V through its card row's "act").
	"hundred_shadows": {"type": "spell", "boss": "kage", "text": "Slay Kage in the Burning Province to unlock."},  # Owner-approved Act V proposal
	"hidden_hand": {"type": "passive", "boss": "kage", "text": "Slay Kage in the Burning Province to unlock."},  # Hundred Shadows' paired passive, unlocked with it
	"paper_lanterns": {"type": "passive", "achievement": "no_shadow_unlit", "text": "Earn No Shadow Unlit: light 20 stone lanterns in one Burning Province run and slay Kage."},  # Owner-approved Act V proposal
	# --- Act V: the Road to the Sun ---
	# Amaterasu's fall (owner-approved Act V proposal "Rewards": Black Sun is
	# unlocked by Amaterasu; the finale grants the Oni): the spell with its paired
	# passive, and the summon class with its paired passive, offered on every
	# stage (no card-row "act" key). The Sun Goes Out achievement opens the Act V
	# epilogue part (EpilogueData.ACT5_PART), not an unlock row.
	"black_sun": {"type": "spell", "boss": "amaterasu", "text": "Put out the sun: defeat Amaterasu on the Road to the Sun to unlock."},  # Owner-approved proposal
	"stolen_dawn": {"type": "passive", "boss": "amaterasu", "text": "Put out the sun: defeat Amaterasu on the Road to the Sun to unlock."},  # Black Sun's paired passive, unlocked with it
	"bound_oni": {"type": "class", "boss": "amaterasu", "text": "Put out the sun: defeat Amaterasu on the Road to the Sun to unlock."},  # Owner-approved proposal: the finale's reward
	"onis_resolve": {"type": "passive", "boss": "amaterasu", "text": "Put out the sun: defeat Amaterasu on the Road to the Sun to unlock."},  # Its paired passive (own decision), unlocked with it
	# --- Act V: Castle Kurogane ---
	# Shogun Kurogane's fall (owner-approved Act V proposal "Rewards": Banner of
	# the Dead is unlocked by the Shogun) with its paired passive, offered on
	# every stage; the stage's achievement Regiments Broken earns Act V's
	# counter-passive Unbending (offered only in Act V through its card row's "act").
	"banner_of_the_dead": {"type": "spell", "boss": "shogun", "text": "Slay Shogun Kurogane in Castle Kurogane to unlock."},  # Owner-approved Act V proposal
	"warlords_seal": {"type": "passive", "boss": "shogun", "text": "Slay Shogun Kurogane in Castle Kurogane to unlock."},  # Banner of the Dead's paired passive, unlocked with it
	"unbending": {"type": "passive", "achievement": "regiments_broken", "text": "Earn Regiments Broken: slay the Shogun after breaking all six of his banners."},  # Owner-approved Act V proposal
}

## End-screen plate heading of a newly unlocked item, by type.
const PLATE_HEADINGS := {
	"spell": "Spell unlocked",  # TUNING (not in GDD)
	"passive": "Passive unlocked",  # TUNING (not in GDD)
	"class": "Summon unlocked",  # TUNING (not in GDD)
	# --- Content wave 2: B. Achievement rewards ---
	"ultimate": "Ultimate unlocked",  # TUNING (not in GDD)
	"title": "Title earned",  # TUNING (not in GDD)
	"skin": "Skin unlocked",  # TUNING (not in GDD)
}

# --- Content wave 2: B. Achievement rewards ---
## Row types that are achievement rewards, not level-up cards: never in a
## card pool, and not opened by the autotest's --unlocks=all (which is about
## the card pool; Unlocks.is_open()).
const REWARD_TYPES := ["ultimate", "title", "skin"]  # TUNING (not in GDD)
