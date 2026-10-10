## PowerupData — designer-tunable data for the POWER-UP DROPS (user request;
## the GDD has no floor pickups besides XP crystals, so every number here is
## TUNING (not in GDD)). PowerupManager reads it.
##
## Six power-ups:
##   magnet  Soul Magnet  every XP crystal on the stage flies to the player.
##   feast   Grave Feast  restores a fraction of max HP (food).
##   hyper   Hyper        timed: spells deal x damage_mult and cool down
##                        x cooldown_mult (attack twice as fast).
##   stasis  Stasis       timed: every enemy is frozen in place (no movement,
##                        attacks, heals or projectile spawns). Sir Alaric is
##                        frozen for boss_fraction of the duration; Reckoning
##                        enemies are immune. A frozen attacker's telegraphs
##                        (and Sir Alaric's marks and arming zones) pause
##                        with it, and a frozen Desecration Chaplain does not
##                        channel.
##   frenzy  Dark Frenzy  timed: summons get +damage_bonus damage and
##                        +attack_speed_bonus attack speed (own stacking
##                        category in HordeDirector.compute_stats).
##   nova    Soul Nova    screen clear (the rarest drop): every regular enemy
##                        on screen dies, elites lose elite_hp_fraction of
##                        their CURRENT HP, Sir Alaric takes boss_max_hp_fraction
##                        of his max HP; Reckoning enemies are immune. All
##                        through CombatResolver.damage_enemy, so kills drop
##                        XP and count for stats, Soul Ash and achievements.
## Re-collecting an active timed buff REFRESHES its duration to the full
## value; it never stacks in strength or adds time on top.
##
## Drop rules (PowerupManager.on_enemy_killed):
##   * a regular enemy drops with CHANCE_NORMAL, an elite with CHANCE_ELITE,
##     Sir Alaric always drops BOSS_DROPS power-ups; the chances are scaled by
##     the Profane Pact / Oath drop_chance reward (the boss drop is not),
##   * pity timer: when PITY_TIME s pass without any drop, the next eligible
##     kill drops one for sure,
##   * the type is a weighted draw over `weight`,
##   * at most MAX_LIVE drops lie on the ground (a roll at the cap is lost;
##     the guaranteed boss drop replaces the oldest one instead),
##   * a drop despawns after LIFETIME s and blinks for the last BLINK_TIME s,
##   * Reckoning enemies never drop, and nothing drops once the countdown
##     reached 0:00,
##   * drops are collected by walking over them: within PICKUP_RADIUS px of
##     the necromancer's body edge. A small fixed radius (not the XP pickup
##     radius) on purpose: it is a routing decision, and the Soul Magnet meta
##     upgrade does not vacuum power-ups.
class_name PowerupData
extends RefCounted

## Display / summary order of the power-up ids.
const ORDER := ["magnet", "feast", "hyper", "stasis", "frenzy", "nova"]
## Power-ups with a duration (shown on the HUD with their remaining time).
const TIMED := ["hyper", "stasis", "frenzy"]

## Drop chance of a regular (non-elite) enemy kill.
const CHANCE_NORMAL: float = 0.002  # TUNING (not in GDD) was 0.003 (~23 drops per run made naive builds too safe)
## Drop chance of an elite kill.
const CHANCE_ELITE: float = 0.20  # TUNING (not in GDD)
## Power-ups Sir Alaric drops when slain (guaranteed).
const BOSS_DROPS: int = 1  # TUNING (not in GDD)
## Seconds without any drop after which the next eligible kill drops one.
const PITY_TIME: float = 120.0  # TUNING (not in GDD) was 90 (8 of ~23 drops were pity drops)
## Most power-ups lying on the ground at once.
const MAX_LIVE: int = 3  # TUNING (not in GDD)
## Seconds a drop stays on the ground before it despawns.
const LIFETIME: float = 30.0  # TUNING (not in GDD)
## Final seconds of LIFETIME during which the drop blinks.
const BLINK_TIME: float = 7.0  # TUNING (not in GDD)
## Collection distance (px) from the necromancer's body edge.
const PICKUP_RADIUS: float = 12.0  # TUNING (not in GDD)
## Radius (px) of a drop's world token.
const TOKEN_RADIUS: float = 10.0  # TUNING (not in GDD)

## Power-up definitions.
##   display_name — HUD / banner name.
##   icon         — PowerupGlyphs kind (world token and UI icon).
##   sound        — SoundData id played on pickup.
##   color        — accent colour (palette language: necromancy colours,
##                  cold blue for Stasis).
##   weight       — relative weight of the type draw.
##   duration     — seconds (timed power-ups only).
##   description  — banner line.
const POWERUPS := {
	"magnet": {"display_name": "Soul Magnet", "icon": "powerup_magnet", "sound": "pu_magnet", "color": Palette.XP,
		"weight": 3.0,  # TUNING (not in GDD)
		"description": "Every soul crystal on the field answers your call."},
	"feast": {"display_name": "Grave Feast", "icon": "powerup_feast", "sound": "pu_feast", "color": Palette.HP_FRIENDLY,
		"weight": 3.0,  # TUNING (not in GDD)
		"heal_fraction": 0.30,  # TUNING (not in GDD) of max HP
		"description": "A grim meal mends your body."},
	"hyper": {"display_name": "Hyper", "icon": "powerup_hyper", "sound": "pu_hyper", "color": Palette.VIOLET,
		"weight": 2.0,  # TUNING (not in GDD)
		"duration": 10.0,  # TUNING (not in GDD)
		"damage_mult": 2.0,  # TUNING (not in GDD) spell damage x2
		"cooldown_mult": 0.5,  # TUNING (not in GDD) spell cooldowns halved
		"description": "Your spells strike twice as hard and twice as fast."},
	"stasis": {"display_name": "Stasis", "icon": "powerup_stasis", "sound": "pu_stasis", "color": Palette.COLD_BLUE,
		"weight": 1.5,  # TUNING (not in GDD)
		"duration": 5.0,  # TUNING (not in GDD)
		"boss_fraction": 0.5,  # TUNING (not in GDD) Sir Alaric is frozen for half the duration
		"description": "Time itself halts for the Covenant."},
	"frenzy": {"display_name": "Dark Frenzy", "icon": "powerup_frenzy", "sound": "pu_frenzy", "color": Palette.NECRO_GREEN,
		"weight": 2.0,  # TUNING (not in GDD)
		"duration": 12.0,  # TUNING (not in GDD)
		"damage_bonus": 0.5,  # TUNING (not in GDD) summons x1.5 damage
		"attack_speed_bonus": 0.5,  # TUNING (not in GDD) summons x1.5 attack speed
		"description": "Your undead fight in a blood-mad frenzy."},
	"nova": {"display_name": "Soul Nova", "icon": "powerup_nova", "sound": "pu_nova", "color": Color(0.92, 0.85, 1.0),
		"weight": 0.5,  # TUNING (not in GDD) the rarest drop
		"elite_hp_fraction": 0.5,  # TUNING (not in GDD) of an elite's current HP
		"boss_max_hp_fraction": 0.05,  # TUNING (not in GDD) of Sir Alaric's max HP
		"screen_margin": 40.0,  # TUNING (not in GDD) px beyond the visible area still hit
		"description": "A nova of stolen souls scours the field."},
}
