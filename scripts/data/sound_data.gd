## SoundData — DESIGNER-TUNABLE recipes for every procedurally synthesized
## sound effect, plus the per-sound voice limits (GDD §12 Audio: "necromancy
## sounds low and unsettling", "holy sounds bright and metallic", "aggressive
## audio voice limits ... cap audio voices"). The GDD gives no voice counts
## (GDD §15.7 q48), so every number here is `# TUNING (not in GDD)`.
## No audio files exist: Synth renders these recipes to AudioStreamWAV at
## startup and Sfx plays them through a capped voice pool.
##
## Recipe keys (one entry of SOUNDS):
##   dur           total length in seconds (layers are clipped to it).
##   layers        Array of layer Dictionaries mixed together (see below).
##   volume_db     playback volume on the SFX bus.
##   max_voices    max simultaneous voices of THIS sound (oldest is stolen).
##   min_interval  ms; a new play of the same sound inside it is dropped.
##   pitch_var     random +/- pitch_scale variation per play (0 = none).
##   priority      higher wins when the global voice pool is full.
## Layer keys:
##   wave          "sine" | "tri" | "saw" | "square" | "noise".
##   f0, f1        start / end frequency in Hz (exponential sweep).
##   start, dur    layer start time and length in seconds.
##   amp           peak amplitude before the sound is normalised.
##   attack        linear fade-in in seconds.
##   decay         exponential decay time constant in s (0 = sustain).
##   lp0, lp1      one-pole low-pass cutoff sweep in Hz (0 = off).
##   vib_hz, vib_depth   vibrato rate (Hz) and depth (fraction of pitch).
class_name SoundData
extends RefCounted

## Every sound effect id -> recipe (keys documented in the header).
const SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# --- Player necromancy: low and unsettling (GDD §12) --------------------
	"bolt_cast": {"dur": 0.22, "volume_db": -15.0, "max_voices": 3, "min_interval": 60, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "saw", "f0": 220.0, "f1": 110.0, "dur": 0.2, "amp": 0.35, "attack": 0.01, "decay": 0.08, "lp0": 1800.0, "lp1": 400.0},
			{"wave": "noise", "dur": 0.18, "amp": 0.25, "attack": 0.02, "decay": 0.06, "lp0": 3000.0, "lp1": 500.0},
			{"wave": "sine", "f0": 110.0, "f1": 73.0, "dur": 0.22, "amp": 0.3, "decay": 0.1}]},
	"bolt_hit": {"dur": 0.15, "volume_db": -16.0, "max_voices": 4, "min_interval": 35, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 160.0, "f1": 55.0, "dur": 0.15, "amp": 0.6, "decay": 0.05},
			{"wave": "noise", "dur": 0.08, "amp": 0.4, "decay": 0.02, "lp0": 2500.0, "lp1": 800.0}]},
	"orb_hit": {"dur": 0.16, "volume_db": -17.0, "max_voices": 3, "min_interval": 50, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "tri", "f0": 392.0, "f1": 370.0, "dur": 0.16, "amp": 0.45, "decay": 0.05},
			{"wave": "sine", "f0": 587.0, "dur": 0.12, "amp": 0.2, "decay": 0.04},
			{"wave": "noise", "dur": 0.03, "amp": 0.2, "decay": 0.01, "lp0": 4000.0}]},
	"orb_block": {"dur": 0.22, "volume_db": -12.0, "max_voices": 2, "min_interval": 70, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 784.0, "f1": 523.0, "dur": 0.22, "amp": 0.4, "decay": 0.07, "vib_hz": 30.0, "vib_depth": 0.02},
			{"wave": "tri", "f0": 1046.0, "dur": 0.1, "amp": 0.15, "decay": 0.03},
			{"wave": "noise", "dur": 0.05, "amp": 0.3, "decay": 0.015, "lp0": 6000.0, "lp1": 2000.0}]},
	"shadow_blast": {"dur": 0.7, "volume_db": -10.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 95.0, "f1": 32.0, "dur": 0.7, "amp": 0.7, "decay": 0.25},
			{"wave": "noise", "dur": 0.6, "amp": 0.5, "attack": 0.01, "decay": 0.18, "lp0": 1800.0, "lp1": 150.0},
			{"wave": "saw", "f0": 55.0, "f1": 40.0, "dur": 0.5, "amp": 0.2, "decay": 0.2, "lp0": 300.0}]},
	"mage_burst": {"dur": 0.3, "volume_db": -18.0, "max_voices": 3, "min_interval": 70, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 140.0, "f1": 60.0, "dur": 0.3, "amp": 0.5, "decay": 0.09},
			{"wave": "noise", "dur": 0.25, "amp": 0.35, "decay": 0.07, "lp0": 2200.0, "lp1": 400.0},
			{"wave": "tri", "f0": 330.0, "f1": 165.0, "dur": 0.2, "amp": 0.2, "decay": 0.06}]},
	# --- Newer necromancer spells (scripts/abilities/spells/) ----------------
	# Bone Spear throw: a dry bony whoosh.
	"spear_cast": {"dur": 0.2, "volume_db": -16.0, "max_voices": 2, "min_interval": 90, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.18, "amp": 0.4, "attack": 0.03, "decay": 0.06, "lp0": 1200.0, "lp1": 4500.0},
			{"wave": "tri", "f0": 260.0, "f1": 180.0, "dur": 0.12, "amp": 0.25, "decay": 0.04}]},
	# Ossuary Lance throw: heavier, with a low hollow boom.
	"lance_cast": {"dur": 0.35, "volume_db": -13.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.3, "amp": 0.45, "attack": 0.03, "decay": 0.1, "lp0": 900.0, "lp1": 3500.0},
			{"wave": "sine", "f0": 120.0, "f1": 60.0, "dur": 0.35, "amp": 0.5, "decay": 0.12},
			{"wave": "square", "f0": 200.0, "f1": 140.0, "dur": 0.15, "amp": 0.12, "decay": 0.05, "lp0": 1200.0}]},
	# Spear / lance impact: a bone crack.
	"spear_hit": {"dur": 0.1, "volume_db": -18.0, "max_voices": 3, "min_interval": 45, "pitch_var": 0.15, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.5, "decay": 0.012, "lp0": 6000.0, "lp1": 2500.0},
			{"wave": "square", "f0": 520.0, "f1": 300.0, "dur": 0.08, "amp": 0.18, "decay": 0.025, "lp0": 2500.0}]},
	# Soul Siphon / Soul Rapture drain: a low wobbling suck.
	"siphon_hit": {"dur": 0.3, "volume_db": -19.0, "max_voices": 2, "min_interval": 140, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 90.0, "f1": 140.0, "dur": 0.3, "amp": 0.45, "attack": 0.05, "decay": 0.12, "vib_hz": 11.0, "vib_depth": 0.05},
			{"wave": "noise", "dur": 0.25, "amp": 0.12, "attack": 0.08, "decay": 0.08, "lp0": 600.0, "lp1": 1400.0}]},
	# Soul Rapture death burst: a rising spectral wail.
	"rapture_burst": {"dur": 0.45, "volume_db": -14.0, "max_voices": 2, "min_interval": 110, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 330.0, "f1": 880.0, "dur": 0.4, "amp": 0.3, "attack": 0.02, "decay": 0.15, "vib_hz": 7.0, "vib_depth": 0.02},
			{"wave": "noise", "dur": 0.3, "amp": 0.25, "decay": 0.08, "lp0": 3000.0, "lp1": 800.0},
			{"wave": "sine", "f0": 80.0, "f1": 50.0, "dur": 0.3, "amp": 0.35, "decay": 0.1}]},
	# Corpse Explosion burst: a wet crunch of bones.
	"corpse_burst": {"dur": 0.3, "volume_db": -14.0, "max_voices": 3, "min_interval": 80, "pitch_var": 0.1, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.25, "amp": 0.55, "decay": 0.06, "lp0": 2500.0, "lp1": 300.0},
			{"wave": "sine", "f0": 110.0, "f1": 45.0, "dur": 0.3, "amp": 0.45, "decay": 0.1},
			{"wave": "noise", "start": 0.05, "dur": 0.04, "amp": 0.3, "decay": 0.01, "lp0": 5000.0}]},
	# Grave Eruption: a deep ground rupture with rattling spikes.
	"eruption": {"dur": 0.55, "volume_db": -12.0, "max_voices": 2, "min_interval": 110, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 70.0, "f1": 32.0, "dur": 0.55, "amp": 0.6, "decay": 0.2},
			{"wave": "noise", "dur": 0.45, "amp": 0.45, "decay": 0.14, "lp0": 1500.0, "lp1": 200.0},
			{"wave": "noise", "start": 0.08, "dur": 0.05, "amp": 0.3, "decay": 0.012, "lp0": 6000.0},
			{"wave": "noise", "start": 0.16, "dur": 0.05, "amp": 0.25, "decay": 0.012, "lp0": 6000.0}]},
	# Plague Cloud placed: a long sickly hiss.
	"plague_cast": {"dur": 0.6, "volume_db": -17.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.05, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.6, "amp": 0.4, "attack": 0.12, "decay": 0.22, "lp0": 2500.0, "lp1": 900.0},
			{"wave": "saw", "f0": 98.0, "f1": 92.0, "dur": 0.5, "amp": 0.15, "attack": 0.1, "decay": 0.2, "lp0": 500.0, "vib_hz": 5.0, "vib_depth": 0.03}]},
	# Plague tick on an enemy: a soft wet bubble.
	"plague_tick": {"dur": 0.08, "volume_db": -25.0, "max_voices": 2, "min_interval": 90, "pitch_var": 0.2, "priority": 0,
		"layers": [
			{"wave": "sine", "f0": 300.0, "f1": 520.0, "dur": 0.08, "amp": 0.4, "decay": 0.025},
			{"wave": "noise", "dur": 0.05, "amp": 0.15, "decay": 0.015, "lp0": 1800.0}]},
	# Pestilence Death Nova: a dark choral thump.
	"death_nova": {"dur": 0.8, "volume_db": -11.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 82.0, "f1": 36.0, "dur": 0.8, "amp": 0.6, "decay": 0.3},
			{"wave": "saw", "f0": 146.83, "f1": 110.0, "dur": 0.6, "amp": 0.2, "attack": 0.02, "decay": 0.25, "lp0": 900.0, "lp1": 250.0},
			{"wave": "noise", "dur": 0.6, "amp": 0.35, "decay": 0.18, "lp0": 2000.0, "lp1": 150.0}]},
	# --- Undead army ----------------------------------------------------------
	"summon_rise": {"dur": 0.55, "volume_db": -19.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.05, "priority": 1,
		"layers": [
			{"wave": "saw", "f0": 98.0, "f1": 196.0, "dur": 0.55, "amp": 0.3, "attack": 0.25, "lp0": 400.0, "lp1": 1400.0, "vib_hz": 6.0, "vib_depth": 0.03},
			{"wave": "noise", "dur": 0.5, "amp": 0.15, "attack": 0.3, "lp0": 800.0, "lp1": 2500.0},
			{"wave": "sine", "f0": 49.0, "f1": 98.0, "dur": 0.55, "amp": 0.3, "attack": 0.2}]},
	"summon_death": {"dur": 0.26, "volume_db": -17.0, "max_voices": 3, "min_interval": 80, "pitch_var": 0.12, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.4, "decay": 0.012, "lp0": 5000.0},
			{"wave": "noise", "start": 0.06, "dur": 0.04, "amp": 0.3, "decay": 0.01, "lp0": 4000.0},
			{"wave": "noise", "start": 0.13, "dur": 0.04, "amp": 0.25, "decay": 0.01, "lp0": 3500.0},
			{"wave": "square", "f0": 300.0, "f1": 90.0, "dur": 0.25, "amp": 0.2, "decay": 0.08, "lp0": 1200.0}]},
	"warrior_bash": {"dur": 0.15, "volume_db": -18.0, "max_voices": 3, "min_interval": 70, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.1, "amp": 0.5, "decay": 0.03, "lp0": 3000.0, "lp1": 900.0},
			{"wave": "square", "f0": 130.0, "f1": 80.0, "dur": 0.14, "amp": 0.35, "decay": 0.05, "lp0": 900.0},
			{"wave": "tri", "f0": 620.0, "f1": 600.0, "dur": 0.12, "amp": 0.12, "decay": 0.04}]},
	"priest_ward": {"dur": 0.5, "volume_db": -17.0, "max_voices": 1, "min_interval": 150, "pitch_var": 0.0, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 523.0, "f1": 540.0, "dur": 0.5, "amp": 0.3, "attack": 0.08, "decay": 0.2, "vib_hz": 9.0, "vib_depth": 0.01},
			{"wave": "sine", "f0": 784.0, "dur": 0.45, "amp": 0.2, "attack": 0.1, "decay": 0.18},
			{"wave": "noise", "dur": 0.3, "amp": 0.05, "attack": 0.1, "lp0": 6000.0}]},
	# --- Later summon classes (SummonBehavior specials) -----------------------
	# Corpse Abomination stomp: a deep body thud with a gravelly rumble.
	"abom_stomp": {"dur": 0.55, "volume_db": -12.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 80.0, "f1": 30.0, "dur": 0.55, "amp": 0.8, "decay": 0.18},
			{"wave": "noise", "dur": 0.4, "amp": 0.5, "attack": 0.005, "decay": 0.12, "lp0": 1500.0, "lp1": 120.0},
			{"wave": "square", "f0": 60.0, "f1": 40.0, "dur": 0.3, "amp": 0.2, "decay": 0.1, "lp0": 400.0}]},
	# Grave Rogue dash: a quick airy swish.
	"rogue_dash": {"dur": 0.22, "volume_db": -16.0, "max_voices": 2, "min_interval": 80, "pitch_var": 0.12, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.22, "amp": 0.5, "attack": 0.04, "decay": 0.07, "lp0": 1200.0, "lp1": 6000.0},
			{"wave": "tri", "f0": 300.0, "f1": 900.0, "dur": 0.15, "amp": 0.12, "decay": 0.05}]},
	# Crypt Gargoyle takeoff: a heavy wing beat.
	"gargoyle_takeoff": {"dur": 0.3, "volume_db": -17.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.12, "amp": 0.5, "attack": 0.02, "decay": 0.04, "lp0": 900.0, "lp1": 300.0},
			{"wave": "noise", "start": 0.14, "dur": 0.12, "amp": 0.4, "attack": 0.02, "decay": 0.04, "lp0": 900.0, "lp1": 300.0},
			{"wave": "sine", "f0": 110.0, "f1": 70.0, "dur": 0.25, "amp": 0.25, "decay": 0.08}]},
	# Crypt Gargoyle dive impact: stone crunch.
	"gargoyle_dive": {"dur": 0.35, "volume_db": -13.0, "max_voices": 2, "min_interval": 100, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.3, "amp": 0.55, "decay": 0.08, "lp0": 3000.0, "lp1": 400.0},
			{"wave": "sine", "f0": 120.0, "f1": 45.0, "dur": 0.35, "amp": 0.5, "decay": 0.12},
			{"wave": "square", "f0": 220.0, "f1": 90.0, "dur": 0.15, "amp": 0.15, "decay": 0.05, "lp0": 1500.0}]},
	# Frost Wraith bolt: a thin glassy chime.
	"frost_bolt": {"dur": 0.18, "volume_db": -19.0, "max_voices": 2, "min_interval": 60, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 1760.0, "f1": 1320.0, "dur": 0.18, "amp": 0.3, "decay": 0.06},
			{"wave": "tri", "f0": 2640.0, "dur": 0.1, "amp": 0.12, "decay": 0.03},
			{"wave": "noise", "dur": 0.08, "amp": 0.1, "decay": 0.02, "lp0": 9000.0, "lp1": 4000.0}]},
	# Frost Wraith Deep Freeze: a crackling glassy sweep down.
	"deep_freeze": {"dur": 0.75, "volume_db": -12.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 2093.0, "f1": 523.0, "dur": 0.7, "amp": 0.3, "decay": 0.25},
			{"wave": "noise", "dur": 0.75, "amp": 0.3, "attack": 0.01, "decay": 0.3, "lp0": 9000.0, "lp1": 1800.0},
			{"wave": "tri", "f0": 3136.0, "dur": 0.35, "amp": 0.08, "decay": 0.12, "vib_hz": 25.0, "vib_depth": 0.01}]},
	# Banshee Dirge wail: a rising then falling ghostly moan with vibrato.
	"banshee_wail": {"dur": 0.7, "volume_db": -15.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 660.0, "f1": 440.0, "dur": 0.7, "amp": 0.35, "attack": 0.12, "decay": 0.3, "vib_hz": 6.0, "vib_depth": 0.04},
			{"wave": "tri", "f0": 990.0, "f1": 620.0, "dur": 0.6, "amp": 0.12, "attack": 0.1, "decay": 0.25, "vib_hz": 7.0, "vib_depth": 0.03},
			{"wave": "noise", "dur": 0.5, "amp": 0.12, "attack": 0.08, "decay": 0.2, "lp0": 2400.0, "lp1": 900.0}]},
	# Corpse Catapult launch: a creaking wooden thunk.
	"catapult_launch": {"dur": 0.3, "volume_db": -16.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "square", "f0": 140.0, "f1": 70.0, "dur": 0.2, "amp": 0.3, "decay": 0.07, "lp0": 900.0},
			{"wave": "noise", "dur": 0.25, "amp": 0.35, "attack": 0.01, "decay": 0.08, "lp0": 1400.0, "lp1": 300.0}]},
	# Corpse Catapult boulder impact: a heavy bony crunch.
	"catapult_impact": {"dur": 0.45, "volume_db": -13.0, "max_voices": 3, "min_interval": 90, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 95.0, "f1": 38.0, "dur": 0.45, "amp": 0.7, "decay": 0.15},
			{"wave": "noise", "dur": 0.35, "amp": 0.5, "attack": 0.005, "decay": 0.1, "lp0": 2600.0, "lp1": 250.0}]},
	# --- Covenant (holy: bright and metallic) --------------------------------
	"enemy_hit": {"dur": 0.07, "volume_db": -23.0, "max_voices": 4, "min_interval": 30, "pitch_var": 0.18, "priority": 0,
		"layers": [
			{"wave": "noise", "dur": 0.06, "amp": 0.45, "decay": 0.015, "lp0": 5000.0, "lp1": 2000.0},
			{"wave": "sine", "f0": 420.0, "f1": 260.0, "dur": 0.07, "amp": 0.35, "decay": 0.025}]},
	"enemy_death": {"dur": 0.2, "volume_db": -20.0, "max_voices": 4, "min_interval": 40, "pitch_var": 0.15, "priority": 0,
		"layers": [
			{"wave": "noise", "dur": 0.18, "amp": 0.45, "decay": 0.05, "lp0": 3500.0, "lp1": 600.0},
			{"wave": "square", "f0": 240.0, "f1": 70.0, "dur": 0.2, "amp": 0.25, "decay": 0.06, "lp0": 1500.0},
			{"wave": "sine", "f0": 880.0, "f1": 600.0, "dur": 0.1, "amp": 0.1, "decay": 0.03}]},
	"boss_arrive": {"dur": 1.6, "volume_db": -9.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.0, "priority": 4,
		"layers": [
			{"wave": "sine", "f0": 220.0, "dur": 1.6, "amp": 0.4, "decay": 0.6},
			{"wave": "sine", "f0": 607.0, "dur": 1.2, "amp": 0.2, "decay": 0.4},
			{"wave": "sine", "f0": 1188.0, "dur": 0.8, "amp": 0.1, "decay": 0.25},
			{"wave": "sine", "f0": 110.0, "dur": 1.6, "amp": 0.3, "attack": 0.05, "decay": 0.7}]},
	"boss_telegraph": {"dur": 0.7, "volume_db": -13.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 880.0, "dur": 0.7, "amp": 0.3, "attack": 0.25, "decay": 0.3, "vib_hz": 11.0, "vib_depth": 0.004},
			{"wave": "sine", "f0": 2429.0, "dur": 0.6, "amp": 0.12, "attack": 0.2, "decay": 0.2},
			{"wave": "sine", "f0": 4752.0, "dur": 0.4, "amp": 0.05, "attack": 0.15, "decay": 0.12}]},
	"boss_impact": {"dur": 1.0, "volume_db": -6.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.04, "priority": 4,
		"layers": [
			{"wave": "sine", "f0": 70.0, "f1": 28.0, "dur": 1.0, "amp": 0.8, "decay": 0.35},
			{"wave": "noise", "dur": 0.8, "amp": 0.6, "decay": 0.2, "lp0": 2500.0, "lp1": 120.0},
			{"wave": "sine", "f0": 523.0, "dur": 0.9, "amp": 0.2, "decay": 0.3},
			{"wave": "sine", "f0": 1443.0, "dur": 0.6, "amp": 0.1, "decay": 0.2}]},
	"reckoning": {"dur": 1.9, "volume_db": -7.0, "max_voices": 1, "min_interval": 2000, "pitch_var": 0.0, "priority": 5,
		"layers": [
			{"wave": "sine", "f0": 146.83, "dur": 1.9, "amp": 0.35, "decay": 0.8},
			{"wave": "sine", "f0": 405.0, "dur": 1.6, "amp": 0.15, "decay": 0.5},
			{"wave": "saw", "f0": 73.42, "dur": 1.9, "amp": 0.2, "attack": 0.4, "lp0": 500.0, "vib_hz": 5.0, "vib_depth": 0.01},
			{"wave": "saw", "f0": 87.31, "dur": 1.9, "amp": 0.15, "attack": 0.5, "lp0": 500.0, "vib_hz": 4.6, "vib_depth": 0.01},
			{"wave": "saw", "f0": 110.0, "dur": 1.9, "amp": 0.15, "attack": 0.6, "lp0": 500.0, "vib_hz": 5.3, "vib_depth": 0.01},
			{"wave": "noise", "dur": 1.4, "amp": 0.1, "attack": 0.5, "lp0": 600.0}]},
	# --- Player / progression ---------------------------------------------------
	"player_hurt": {"dur": 0.25, "volume_db": -10.0, "max_voices": 1, "min_interval": 120, "pitch_var": 0.06, "priority": 4,
		"layers": [
			{"wave": "square", "f0": 170.0, "f1": 85.0, "dur": 0.25, "amp": 0.3, "decay": 0.08, "lp0": 1400.0},
			{"wave": "noise", "dur": 0.15, "amp": 0.45, "decay": 0.04, "lp0": 2500.0, "lp1": 500.0},
			{"wave": "sine", "f0": 90.0, "f1": 50.0, "dur": 0.25, "amp": 0.5, "decay": 0.09}]},
	"player_death": {"dur": 1.4, "volume_db": -7.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.0, "priority": 5,
		"layers": [
			{"wave": "sine", "f0": 110.0, "f1": 40.0, "dur": 1.4, "amp": 0.6, "decay": 0.5},
			{"wave": "saw", "f0": 55.0, "f1": 36.0, "dur": 1.4, "amp": 0.3, "attack": 0.02, "decay": 0.5, "lp0": 600.0, "lp1": 150.0},
			{"wave": "noise", "dur": 1.0, "amp": 0.3, "decay": 0.3, "lp0": 1200.0, "lp1": 100.0}]},
	"xp_pickup": {"dur": 0.09, "volume_db": -21.0, "max_voices": 3, "min_interval": 35, "pitch_var": 0.0, "priority": 0,
		"layers": [
			{"wave": "sine", "f0": 1318.5, "dur": 0.09, "amp": 0.4, "attack": 0.002, "decay": 0.03},
			{"wave": "sine", "f0": 1975.5, "dur": 0.07, "amp": 0.15, "decay": 0.02}]},
	"level_up": {"dur": 0.95, "volume_db": -11.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "tri", "f0": 440.0, "dur": 0.45, "amp": 0.3, "decay": 0.2},
			{"wave": "tri", "f0": 523.25, "start": 0.09, "dur": 0.45, "amp": 0.3, "decay": 0.2},
			{"wave": "tri", "f0": 659.25, "start": 0.18, "dur": 0.45, "amp": 0.3, "decay": 0.2},
			{"wave": "tri", "f0": 880.0, "start": 0.27, "dur": 0.65, "amp": 0.3, "decay": 0.25},
			{"wave": "sine", "f0": 220.0, "dur": 0.95, "amp": 0.25, "attack": 0.05, "decay": 0.4}]},
	# --- UI -------------------------------------------------------------------------
	"card_select": {"dur": 0.34, "volume_db": -12.0, "max_voices": 1, "min_interval": 100, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 293.66, "dur": 0.3, "amp": 0.35, "decay": 0.12},
			{"wave": "tri", "f0": 440.0, "start": 0.04, "dur": 0.3, "amp": 0.25, "decay": 0.12},
			{"wave": "noise", "dur": 0.04, "amp": 0.15, "decay": 0.01, "lp0": 5000.0}]},
	"ui_hover": {"dur": 0.035, "volume_db": -26.0, "max_voices": 2, "min_interval": 40, "pitch_var": 0.0, "priority": 2,
		"layers": [
			{"wave": "tri", "f0": 1200.0, "f1": 1100.0, "dur": 0.035, "amp": 0.3, "decay": 0.01}]},
	"ui_confirm": {"dur": 0.15, "volume_db": -17.0, "max_voices": 2, "min_interval": 60, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "tri", "f0": 660.0, "dur": 0.08, "amp": 0.3, "decay": 0.03},
			{"wave": "tri", "f0": 880.0, "start": 0.05, "dur": 0.1, "amp": 0.3, "decay": 0.04}]},
	# Back / cancel (Back buttons, Esc / pad B in a screen): ui_confirm's two notes
	# mirrored downward (D5 -> A4), a little softer.
	"ui_back": {"dur": 0.15, "volume_db": -18.0, "max_voices": 2, "min_interval": 60, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "tri", "f0": 587.33, "dur": 0.08, "amp": 0.3, "decay": 0.03},
			{"wave": "tri", "f0": 440.0, "start": 0.05, "dur": 0.1, "amp": 0.3, "decay": 0.04}]},
	# Panel open (UiMotion.open): a soft, short airy whoosh rising into place.
	"panel_open": {"dur": 0.2, "volume_db": -23.0, "max_voices": 1, "min_interval": 80, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.2, "amp": 0.5, "attack": 0.07, "decay": 0.06, "lp0": 500.0, "lp1": 2600.0},
			{"wave": "sine", "f0": 196.0, "f1": 294.0, "dur": 0.18, "amp": 0.18, "attack": 0.05, "decay": 0.07}]},
	# Panel close (UiMotion.close / hide): the open whoosh falling away, shorter and softer.
	"panel_close": {"dur": 0.15, "volume_db": -25.0, "max_voices": 1, "min_interval": 80, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.15, "amp": 0.5, "attack": 0.02, "decay": 0.05, "lp0": 2400.0, "lp1": 450.0},
			{"wave": "sine", "f0": 294.0, "f1": 180.0, "dur": 0.12, "amp": 0.15, "decay": 0.04}]},
	# Purchase (Ossuary buy): a bright bone-chime, a dry knock then a rising C-G-C sparkle.
	"purchase": {"dur": 0.65, "volume_db": -13.0, "max_voices": 1, "min_interval": 90, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.03, "amp": 0.3, "decay": 0.008, "lp0": 5000.0},
			{"wave": "square", "f0": 700.0, "f1": 520.0, "dur": 0.05, "amp": 0.12, "decay": 0.015, "lp0": 3000.0},
			{"wave": "tri", "f0": 1046.5, "start": 0.02, "dur": 0.4, "amp": 0.3, "decay": 0.13},
			{"wave": "sine", "f0": 1567.98, "start": 0.07, "dur": 0.4, "amp": 0.24, "decay": 0.14},
			{"wave": "sine", "f0": 2093.0, "start": 0.12, "dur": 0.5, "amp": 0.18, "decay": 0.18, "vib_hz": 9.0, "vib_depth": 0.006}]},
	# Denied (can't afford / locked): a dull, low thud with no ring.
	"denied": {"dur": 0.18, "volume_db": -15.0, "max_voices": 1, "min_interval": 90, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 120.0, "f1": 70.0, "dur": 0.18, "amp": 0.55, "decay": 0.05},
			{"wave": "square", "f0": 92.0, "f1": 80.0, "dur": 0.12, "amp": 0.18, "decay": 0.04, "lp0": 380.0},
			{"wave": "noise", "dur": 0.05, "amp": 0.25, "decay": 0.015, "lp0": 700.0}]},
	# Count-up tick (UiMotion.count_up, pitch rises with the count): a tiny bone tick.
	"ui_tick": {"dur": 0.03, "volume_db": -25.0, "max_voices": 2, "min_interval": 45, "pitch_var": 0.02, "priority": 1,
		"layers": [
			{"wave": "tri", "f0": 1480.0, "dur": 0.03, "amp": 0.3, "decay": 0.008},
			{"wave": "noise", "dur": 0.01, "amp": 0.12, "decay": 0.003, "lp0": 6000.0}]},
	# --- Army stance command (ArmyStance change): a low horn over a drum thump --
	"stance_command": {"dur": 0.45, "volume_db": -13.0, "max_voices": 1, "min_interval": 150, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.1, "amp": 0.45, "decay": 0.03, "lp0": 900.0, "lp1": 200.0},
			{"wave": "sine", "f0": 90.0, "f1": 55.0, "dur": 0.2, "amp": 0.5, "decay": 0.07},
			{"wave": "saw", "f0": 98.0, "f1": 110.0, "start": 0.06, "dur": 0.38, "amp": 0.3, "attack": 0.04, "decay": 0.18, "lp0": 500.0, "lp1": 1300.0},
			{"wave": "saw", "f0": 146.83, "f1": 164.81, "start": 0.06, "dur": 0.38, "amp": 0.18, "attack": 0.04, "decay": 0.18, "lp0": 600.0, "lp1": 1500.0}]},
	# --- Power-up pickups (PowerupData, played by Juice.powerup_collected) ------
	"pu_magnet": {"dur": 0.6, "volume_db": -11.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 330.0, "f1": 1320.0, "dur": 0.55, "amp": 0.35, "attack": 0.02, "decay": 0.3, "vib_hz": 14.0, "vib_depth": 0.02},
			{"wave": "tri", "f0": 660.0, "f1": 1760.0, "start": 0.08, "dur": 0.5, "amp": 0.2, "decay": 0.25},
			{"wave": "noise", "dur": 0.5, "amp": 0.08, "attack": 0.2, "lp0": 1500.0, "lp1": 6000.0}]},
	"pu_feast": {"dur": 0.45, "volume_db": -12.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.08, "amp": 0.35, "decay": 0.02, "lp0": 2500.0, "lp1": 700.0},
			{"wave": "noise", "start": 0.12, "dur": 0.08, "amp": 0.3, "decay": 0.02, "lp0": 2200.0, "lp1": 600.0},
			{"wave": "sine", "f0": 392.0, "f1": 523.0, "start": 0.15, "dur": 0.3, "amp": 0.3, "attack": 0.02, "decay": 0.12},
			{"wave": "sine", "f0": 784.0, "start": 0.22, "dur": 0.22, "amp": 0.15, "decay": 0.08}]},
	"pu_hyper": {"dur": 0.6, "volume_db": -10.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 110.0, "f1": 880.0, "dur": 0.4, "amp": 0.3, "attack": 0.01, "decay": 0.2, "lp0": 800.0, "lp1": 5000.0},
			{"wave": "square", "f0": 440.0, "start": 0.3, "dur": 0.3, "amp": 0.15, "decay": 0.1, "lp0": 3000.0},
			{"wave": "noise", "dur": 0.15, "amp": 0.3, "decay": 0.04, "lp0": 6000.0, "lp1": 2000.0}]},
	"pu_stasis": {"dur": 0.9, "volume_db": -10.0, "max_voices": 1, "min_interval": 300, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 1568.0, "f1": 392.0, "dur": 0.8, "amp": 0.3, "decay": 0.35},
			{"wave": "tri", "f0": 2093.0, "dur": 0.5, "amp": 0.12, "decay": 0.2, "vib_hz": 22.0, "vib_depth": 0.01},
			{"wave": "noise", "dur": 0.9, "amp": 0.15, "attack": 0.05, "decay": 0.4, "lp0": 8000.0, "lp1": 1500.0}]},
	"pu_frenzy": {"dur": 0.7, "volume_db": -10.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 73.42, "f1": 146.83, "dur": 0.6, "amp": 0.35, "attack": 0.05, "decay": 0.3, "lp0": 500.0, "lp1": 1600.0, "vib_hz": 7.0, "vib_depth": 0.04},
			{"wave": "square", "f0": 110.0, "dur": 0.5, "amp": 0.15, "attack": 0.1, "decay": 0.2, "lp0": 900.0},
			{"wave": "noise", "dur": 0.4, "amp": 0.25, "decay": 0.12, "lp0": 2500.0, "lp1": 400.0}]},
	"pu_nova": {"dur": 1.3, "volume_db": -6.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.0, "priority": 5,
		"layers": [
			{"wave": "sine", "f0": 60.0, "f1": 30.0, "dur": 1.2, "amp": 0.7, "decay": 0.45},
			{"wave": "noise", "dur": 1.0, "amp": 0.55, "attack": 0.01, "decay": 0.3, "lp0": 7000.0, "lp1": 200.0},
			{"wave": "saw", "f0": 146.83, "f1": 587.33, "dur": 0.5, "amp": 0.2, "attack": 0.02, "decay": 0.2, "lp0": 1200.0, "lp1": 5000.0},
			{"wave": "sine", "f0": 1174.66, "start": 0.1, "dur": 1.0, "amp": 0.15, "decay": 0.4, "vib_hz": 6.0, "vib_depth": 0.01}]},
	# --- Treasure chest (ChestPanel reveal) -------------------------------------
	"chest_open": {"dur": 1.0, "volume_db": -9.0, "max_voices": 1, "min_interval": 300, "pitch_var": 0.0, "priority": 4,
		"layers": [
			{"wave": "noise", "dur": 0.12, "amp": 0.4, "decay": 0.04, "lp0": 2000.0, "lp1": 500.0},
			{"wave": "tri", "f0": 523.25, "start": 0.15, "dur": 0.4, "amp": 0.25, "decay": 0.15},
			{"wave": "tri", "f0": 659.25, "start": 0.25, "dur": 0.4, "amp": 0.25, "decay": 0.15},
			{"wave": "tri", "f0": 783.99, "start": 0.35, "dur": 0.4, "amp": 0.25, "decay": 0.15},
			{"wave": "sine", "f0": 1046.5, "start": 0.45, "dur": 0.55, "amp": 0.25, "decay": 0.25, "vib_hz": 8.0, "vib_depth": 0.01}]},
	# --- Content wave 2: Ultimates --- (UltimateSystem.cast(), UltimateData "sound")
	# Sovereign's Decree: a low bell struck under a dark brass fifth.
	"ult_decree": {"dur": 1.0, "volume_db": -9.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.0, "priority": 4,
		"layers": [
			{"wave": "sine", "f0": 146.83, "dur": 1.0, "amp": 0.5, "decay": 0.45, "vib_hz": 5.0, "vib_depth": 0.004},
			{"wave": "tri", "f0": 220.0, "dur": 0.9, "amp": 0.3, "attack": 0.01, "decay": 0.35},
			{"wave": "saw", "f0": 73.42, "dur": 0.7, "amp": 0.22, "attack": 0.03, "decay": 0.3, "lp0": 700.0, "lp1": 250.0},
			{"wave": "noise", "dur": 0.08, "amp": 0.3, "decay": 0.02, "lp0": 5000.0, "lp1": 1500.0}]},
	# Eclipse: the light sucked away, a falling hollow drone.
	"ult_eclipse": {"dur": 1.2, "volume_db": -9.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.0, "priority": 4,
		"layers": [
			{"wave": "sine", "f0": 880.0, "f1": 110.0, "dur": 0.9, "amp": 0.3, "decay": 0.5},
			{"wave": "sine", "f0": 55.0, "f1": 41.2, "dur": 1.2, "amp": 0.55, "attack": 0.05, "decay": 0.6},
			{"wave": "noise", "dur": 1.1, "amp": 0.35, "attack": 0.02, "decay": 0.45, "lp0": 6000.0, "lp1": 120.0}]},
	# Grave Tide: a rising wave of earth and souls.
	"ult_tide": {"dur": 1.0, "volume_db": -9.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.0, "priority": 4,
		"layers": [
			{"wave": "noise", "dur": 0.9, "amp": 0.45, "attack": 0.25, "decay": 0.3, "lp0": 300.0, "lp1": 2500.0},
			{"wave": "saw", "f0": 73.42, "f1": 146.83, "dur": 0.8, "amp": 0.25, "attack": 0.2, "decay": 0.3, "lp0": 400.0, "lp1": 1400.0},
			{"wave": "sine", "f0": 220.0, "f1": 330.0, "start": 0.3, "dur": 0.6, "amp": 0.2, "decay": 0.25, "vib_hz": 7.0, "vib_depth": 0.02}]},
}

## Music drone loop length in seconds (all oscillators are snapped to a whole
## number of cycles per loop so it repeats seamlessly).
const MUSIC_LOOP_SECONDS: float = 12.0  # TUNING (not in GDD)
## Root drone frequency (D2) of the minor-key ambient bed.
const MUSIC_ROOT_HZ: float = 73.42  # TUNING (not in GDD)
## Pad chords (Hz per voice), one per equal segment of the loop:
## Dm -> Bb -> Gm -> A (D harmonic minor; dark, unresolved turnaround).
const MUSIC_CHORDS: Array = [  # TUNING (not in GDD)
	[146.83, 174.61, 220.0],
	[116.54, 146.83, 174.61],
	[98.0, 116.54, 146.83],
	[110.0, 138.59, 164.81],
]
## Seconds between low "heartbeat" percussion hits.
const MUSIC_BEAT_SECONDS: float = 2.0  # TUNING (not in GDD)

## "Below the Tide", the Act II run loop (GDD §15.0 "Act II: the Ancient Eye":
## "low drones, slow glides, a tolling bell"): the RunLoopSynth score of every
## stage whose STAGE has "music": "tide" (keys in RunLoopSynth's header).
## Rendered lazily (Sfx), never under the autotest.
const TIDE_SCORE := {
	"loop_seconds": 16.0,  # TUNING (not in GDD) a slower swell than Act I's 12 s
	"root_hz": 55.0,  # TUNING (not in GDD) A1: a fifth below the Act I drone
	# Am -> F -> Dm -> E (A minor with a raised, uneasy dominant), voiced low.
	"chords": [
		[110.0, 130.81, 164.81],
		[87.31, 110.0, 130.81],
		[73.42, 87.31, 110.0],
		[82.41, 103.83, 123.47],
	],  # TUNING (not in GDD)
	"drone_lp_hz": 45.0,  # TUNING (not in GDD) darker than Act I's 60
	"wind_lp_hz": 90.0,  # TUNING (not in GDD) a low surf instead of wind
	"wind_swells": 4.0,  # TUNING (not in GDD) four wave surges per loop
	"vibrato_hz": 0.25,  # TUNING (not in GDD) the slow glides
	"vibrato_depth": 0.015,  # TUNING (not in GDD)
	# A drowned bell: struck every 8 s, inharmonic partials (ratios of a bell),
	# a long slow decay; G3 against the A drone, slightly wrong on purpose.
	"toll": {"every": 8.0, "root_hz": 196.0, "dur": 7.5, "decay": 2.2,
		"partials": [[1.0, 0.30], [2.76, 0.16], [5.4, 0.08], [0.5, 0.18]]},  # TUNING (not in GDD)
}

## "Iron Requiem", the Act III run loop (GDD §15.0 "Act III foundation (phase
## 1)", owner-approved proposal: "a pulsing low synth, metallic hits and a cold
## arpeggio"): the RunLoopSynth score of every stage whose STAGE has "music":
## "iron" (keys in RunLoopSynth's header). A buzzy E drone under a cold minor
## pad, an eighth-note bass pulse instead of the heartbeat, a struck-metal
## clang on the off-beats and a square-wave arpeggio over each chord. Rendered
## lazily (Sfx), never under the autotest. 120 bpm: 24 beats per 12 s loop.
const IRON_SCORE := {
	"loop_seconds": 12.0,  # TUNING (not in GDD) 24 beats at 120 bpm
	"root_hz": 41.2,  # TUNING (not in GDD) E1: lower and colder than Act I's D2
	# Em -> C -> Am -> B (E minor with the hard major dominant), voiced low.
	"chords": [
		[164.81, 196.0, 246.94],
		[130.81, 164.81, 196.0],
		[110.0, 130.81, 164.81],
		[123.47, 155.56, 185.0],
	],  # TUNING (not in GDD)
	"drone_lp_hz": 90.0,  # TUNING (not in GDD) buzzier than Act I's 60 (machines hum)
	"wind_lp_hz": 70.0,  # TUNING (not in GDD) a low factory rumble instead of wind
	"wind_swells": 6.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.5,  # TUNING (not in GDD)
	"vibrato_depth": 0.0015,  # TUNING (not in GDD) nearly none: machines do not waver
	# The pulsing low synth: a filtered saw on every eighth (replaces the heartbeat).
	"pulse": {"step": 0.25, "hz": 82.41, "dur": 0.2, "amp": 0.2, "decay": 0.07, "lp0": 700.0, "lp1": 160.0,
		"accent_every": 4, "accent_amp": 0.32},  # TUNING (not in GDD) E2, the beat accented
	# Metallic hits: an inharmonic clang (struck steel) on the off-beats, every 1 s.
	"hits": {"every": 1.0, "offset": 0.5, "root_hz": 610.0, "dur": 0.42, "decay": 0.09,
		"partials": [[1.0, 0.16], [2.31, 0.1], [3.87, 0.07], [5.43, 0.05]], "click": 0.12},  # TUNING (not in GDD)
	# The cold arpeggio: square-wave notes up each chord's tones, one per eighth.
	"arp": {"step": 0.25, "dur": 0.18, "amp": 0.06, "decay": 0.06, "lp0": 2600.0, "wave": "square",
		"chords": [
			[329.63, 392.0, 493.88, 659.26],
			[261.63, 329.63, 392.0, 523.25],
			[220.0, 261.63, 329.63, 440.0],
			[246.94, 311.13, 369.99, 493.88],
		]},  # TUNING (not in GDD) two octaves over the pad
}

## "Hymn of Bronze", the Act IV run loop (GDD §15.0 "Hymn of Bronze and the
## Pantheon sounds", owner-approved proposal: "a martial, ancient feel"): the
## RunLoopSynth score of every stage whose STAGE has "music": "bronze" (keys in
## RunLoopSynth's header). A low D drone and sea-wind bed under a Dorian choir
## pad (Dm - C - G - Dm), a war drum on every beat with a ghost note after the
## off-beats, a plucked lyre arpeggio and a brassy horn swell twice a loop.
## Rendered lazily (Sfx), never under the autotest. 90 bpm: 24 beats per 16 s.
const BRONZE_SCORE := {
	"loop_seconds": 16.0,  # TUNING (not in GDD) 24 beats at 90 bpm
	"root_hz": 36.71,  # TUNING (not in GDD) D1, the drone under a Dorian D
	# Dm -> C -> G -> Dm/A (D Dorian: the raised sixth shows in the lyre), voiced low.
	"chords": [
		[146.83, 174.61, 220.0],
		[130.81, 164.81, 196.0],
		[98.0, 123.47, 146.83],
		[110.0, 146.83, 174.61],
	],  # TUNING (not in GDD)
	"drone_lp_hz": 70.0,  # TUNING (not in GDD) a little brighter than Act I's 60: a brass-bowl hum
	"wind_lp_hz": 110.0,  # TUNING (not in GDD) a low sea wind off the Aegean
	"wind_swells": 2.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.5,  # TUNING (not in GDD)
	"vibrato_depth": 0.006,  # TUNING (not in GDD)
	# The war drum: a skin thump (falling sine plus a noise slap) on every beat,
	# the 4th beat of each bar accented, and a soft ghost hit `ghost_at` of a beat later.
	"drums": {"step": 0.6667, "hz0": 105.0, "hz1": 52.0, "dur": 0.32, "amp": 0.4, "decay": 0.1,
		"accent_every": 4, "accent_amp": 0.62, "slap": 0.12, "ghost_at": 0.75, "ghost_amp": 0.16},  # TUNING (not in GDD)
	# The lyre: plucked triangle notes, one per eighth, up each chord's tones (D Dorian).
	"arp": {"step": 0.3333, "dur": 0.3, "amp": 0.09, "decay": 0.09, "lp0": 3600.0, "wave": "tri",
		"chords": [
			[293.66, 349.23, 440.0, 587.33],
			[261.63, 329.63, 392.0, 523.25],
			[196.0, 246.94, 293.66, 392.0],
			[220.0, 293.66, 349.23, 440.0],
		]},  # TUNING (not in GDD) an octave and a half above the pad
	# The horn: two slow brass swells a loop (a saw and its fifth through a rising low-pass).
	"horn": {"starts": [0.0, 8.0], "dur": 6.5, "attack": 2.0, "decay": 3.0, "amp": 0.07, "lp0": 450.0, "lp1": 1700.0,
		"notes": [[146.83, 220.0], [130.81, 196.0]]},  # TUNING (not in GDD) [root, fifth] (Hz) per swell
}

## "The Setting Sun", the Act V run loop (GDD §15.0 "The Setting Sun and the
## Shogunate sounds", owner-approved proposal: a Japanese feel): the RunLoopSynth
## score of every stage whose STAGE has "music": "sun" (keys in RunLoopSynth's
## header). A low D drone and a thin wind bed under a sparse in-scale pad
## (D, Eb, G, A, Bb: the "in" pentatonic), taiko patterns (don / ka) instead of
## the heartbeat, a plucked koto line and a breathy shakuhachi lead. Rendered
## lazily (Sfx), never under the autotest. 96 bpm: 24 beats per 15 s loop, six
## 4-beat bars.
const SUN_SCORE := {
	"loop_seconds": 15.0,  # TUNING (not in GDD) 24 beats at 96 bpm (0.625 s a beat)
	"root_hz": 36.71,  # TUNING (not in GDD) D1, the drone under the scale's D
	# Open, sparse voicings (no thirds: the scale has none): D-G-A, Eb-G-Bb, G-A-D, D-A-D.
	"chords": [
		[146.83, 196.0, 220.0],
		[155.56, 196.0, 233.08],
		[196.0, 220.0, 293.66],
		[146.83, 220.0, 293.66],
	],  # TUNING (not in GDD)
	"drone_lp_hz": 55.0,  # TUNING (not in GDD) a deep temple hum
	"wind_lp_hz": 200.0,  # TUNING (not in GDD) a thin wind through bamboo
	"wind_swells": 3.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.4,  # TUNING (not in GDD)
	"vibrato_depth": 0.004,  # TUNING (not in GDD)
	# Taiko: 4-beat bars of hits [beat, kind, amp]; "don" = the deep drum head,
	# "ka" = the rim. Bar b plays pattern b % patterns.size().
	"taiko": {"beat": 0.625, "beats_per_bar": 4, "don_hz0": 98.0, "don_hz1": 46.0, "don_dur": 0.42, "don_decay": 0.13,
		"ka_hz0": 260.0, "ka_hz1": 170.0, "ka_dur": 0.12, "ka_decay": 0.03, "slap": 0.14,
		"patterns": [
			[[0.0, "don", 0.62], [1.5, "ka", 0.14], [2.0, "don", 0.34], [3.0, "ka", 0.14], [3.5, "ka", 0.1]],
			[[0.0, "don", 0.62], [0.75, "ka", 0.1], [1.5, "don", 0.3], [2.0, "don", 0.4], [3.0, "ka", 0.14]],
			[[0.0, "don", 0.62], [1.0, "ka", 0.12], [2.0, "don", 0.34], [2.5, "don", 0.26], [3.0, "don", 0.46], [3.5, "ka", 0.12]],
			[[0.0, "don", 0.7], [0.5, "ka", 0.1], [1.0, "ka", 0.1], [2.0, "don", 0.4], [3.25, "don", 0.5], [3.625, "ka", 0.14]],
		]},  # TUNING (not in GDD)
	# Koto: plucked notes [start (s), Hz, amp, glide-to Hz (0 = none)] in the D in scale
	# (D Eb G A Bb): a falling phrase, a rest, an answering rise. Each rings `dur` s.
	"koto": {"dur": 1.3, "decay": 0.34, "lp0": 3800.0, "lp1": 1500.0, "click": 0.05,
		"notes": [
			[0.0, 587.33, 0.1, 0.0], [0.625, 466.16, 0.08, 0.0], [1.25, 392.0, 0.09, 0.0], [2.5, 440.0, 0.08, 392.0],
			[3.75, 293.66, 0.1, 0.0], [4.375, 392.0, 0.08, 0.0], [5.0, 440.0, 0.09, 0.0],
			[6.25, 622.25, 0.1, 0.0], [6.875, 587.33, 0.08, 0.0], [7.5, 466.16, 0.09, 0.0], [8.75, 392.0, 0.08, 0.0],
			[10.0, 311.13, 0.09, 0.0], [10.625, 392.0, 0.08, 0.0], [11.25, 466.16, 0.09, 0.0], [11.875, 587.33, 0.1, 622.25],
			[13.125, 440.0, 0.08, 0.0],
		]},  # TUNING (not in GDD)
	# Shakuhachi: breathy sustained notes [start (s), Hz, length (s)]: a sine with slow
	# vibrato, a late-swelling noise breath and a faint octave overtone.
	"flute": {"amp": 0.09, "breath": 0.07, "attack": 0.28, "decay": 1.6, "vib_hz": 4.6, "vib_depth": 0.012,
		"notes": [[1.25, 587.33, 3.4], [5.6, 783.99, 2.2], [8.1, 622.25, 2.6], [11.9, 587.33, 2.8]]},  # TUNING (not in GDD)
}

## "Hymn of the Pit", the Act VI run loop (GDD §15.0 "Hymn of the Pit and the
## Inferno sounds", owner-approved proposal: an infernal feel): the RunLoopSynth
## score of every stage whose STAGE has "music": "brimstone" (keys in
## RunLoopSynth's header). A deep C drone and a dry furnace-wind bed under a
## dissonant choir pad (tritones and a diminished triad over C Phrygian: C-Gb-Bb,
## Db-G-B, C-Eb-Gb, B-F-Ab), a heavy pipe-organ pedal, slow pounding war drums
## (the Act IV "drums" job, slower and lower), a snarling distorted bass pulse
## and a tolling bell. Rendered lazily (Sfx), never under the autotest. 60 bpm:
## 16 beats per 16 s loop, four 4-beat bars.
const BRIMSTONE_SCORE := {
	"loop_seconds": 16.0,  # TUNING (not in GDD) 16 beats at 60 bpm (1 s a beat)
	"root_hz": 32.7,  # TUNING (not in GDD) C1, the drone under a Phrygian C
	# Dissonant choir voicings (tritones, a diminished triad), low.
	"chords": [
		[130.81, 185.0, 233.08],
		[138.59, 196.0, 246.94],
		[130.81, 155.56, 185.0],
		[123.47, 174.61, 207.65],
	],  # TUNING (not in GDD)
	"drone_lp_hz": 80.0,  # TUNING (not in GDD) a furnace hum, a little brighter than Act IV's
	"wind_lp_hz": 260.0,  # TUNING (not in GDD) a dry scorching draught
	"wind_swells": 4.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.7,  # TUNING (not in GDD) a restless choir
	"vibrato_depth": 0.009,  # TUNING (not in GDD)
	# War drums, slow and pounding: one deep thump a second, every 4th a heavy accent, a soft ghost half a beat later.
	"drums": {"step": 1.0, "hz0": 82.0, "hz1": 36.0, "dur": 0.5, "amp": 0.44, "decay": 0.16,
		"accent_every": 4, "accent_amp": 0.72, "slap": 0.12, "ghost_at": 0.5, "ghost_amp": 0.2},  # TUNING (not in GDD)
	# The organ pedal: a stack of sine partials swelling in under each bar pair (C, then Db: the Phrygian second).
	"organ": {"attack": 1.4, "decay": 5.0, "vib_hz": 0.9, "vib_depth": 0.004,
		"partials": [[1.0, 0.13], [2.0, 0.1], [3.0, 0.06], [4.0, 0.05], [6.0, 0.025]],
		"notes": [[0.0, 65.41, 7.6], [8.0, 69.3, 7.6]]},  # TUNING (not in GDD) [start (s), Hz, length (s)]
	# The snarl: a bass pulse on the bar root; ratios 1 = root, 1.0595 = flat second, 1.4142 = tritone.
	"snarl": {"beat": 1.0, "beats_per_bar": 4, "roots": [65.41, 69.3, 65.41, 61.74],
		"pattern": [[0.0, 1.0, 0.35], [0.75, 1.0, 0.2], [1.5, 1.0595, 0.3], [2.5, 1.0, 0.35], [3.25, 1.4142, 0.4]],
		"drive": 5.0, "amp": 0.13, "decay": 0.28, "lp0": 900.0, "lp1": 320.0},  # TUNING (not in GDD) [beat, ratio, beats]
	# The bell: a struck, dissonant bell every 4 s from 3 s (partials over a low Bb).
	"hits": {"every": 4.0, "offset": 3.0, "root_hz": 233.08, "dur": 2.4, "decay": 0.9,
		"partials": [[1.0, 0.1], [2.76, 0.06], [5.4, 0.035], [8.93, 0.015]], "click": 0.08},  # TUNING (not in GDD)
}

## "Waltz of the Red Moon", the Act VII run loop (GDD §15.0 "Waltz of the Red Moon and
## the Court sounds"): the RunLoopSynth score of every stage whose STAGE has "music":
## "sanguine". A gothic waltz in A minor (harmonic: the E chord carries G sharp), 3/4 at
## 90 bpm: 3 beats of 2/3 s make a 2 s bar, eight bars a 16 s loop. A harpsichord
## arpeggio (the "arp" job: bright, short plucked saws, six eighth notes a bar), a church
## organ (the "organ" job: a full stack of sine partials under each chord), low strings
## swelling bar by bar (the "horn" job: a saw and its fifth through a rising low-pass), a
## plucked oom-pah-pah (the new "waltz" job) and a slow heartbeat (the default heartbeat
## job, once a bar on the downbeat) under a low velvet pad. Rendered lazily (Sfx), never
## under the autotest. Chord order per 4 s segment: Am, Dm, E, Am/C.
const SANGUINE_SCORE := {
	"loop_seconds": 16.0,  # TUNING (not in GDD) eight 3/4 bars of 2 s (90 bpm)
	"root_hz": 55.0,  # TUNING (not in GDD) A1, the drone under A minor
	"chords": [
		[110.0, 164.81, 220.0, 261.63],
		[146.83, 220.0, 293.66, 349.23],
		[164.81, 207.65, 246.94, 329.63],
		[130.81, 164.81, 220.0, 329.63],
	],  # TUNING (not in GDD) Am, Dm, E (G sharp), Am/C
	"drone_lp_hz": 70.0,  # TUNING (not in GDD) a velvet hum
	"wind_lp_hz": 180.0,  # TUNING (not in GDD) a draught through a drawing room
	"wind_swells": 2.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.5,  # TUNING (not in GDD)
	"vibrato_depth": 0.003,  # TUNING (not in GDD)
	"beat_seconds": 2.0,  # TUNING (not in GDD) the heartbeat: one lub-dub a bar, on the downbeat
	# Harpsichord: one note every 1/3 s (six a bar) cycling up the segment's tones.
	"arp": {"step": 0.33333, "dur": 0.3, "amp": 0.045, "decay": 0.08, "lp0": 3400.0, "wave": "saw",
		"chords": [
			[220.0, 261.63, 329.63, 440.0, 329.63, 261.63],
			[293.66, 349.23, 440.0, 587.33, 440.0, 349.23],
			[329.63, 415.3, 493.88, 659.25, 493.88, 415.3],
			[261.63, 329.63, 440.0, 523.25, 440.0, 329.63],
		]},  # TUNING (not in GDD)
	# Church organ: a full stack of sine partials swelling in under each chord root.
	"organ": {"attack": 0.9, "decay": 1.6, "vib_hz": 5.0, "vib_depth": 0.003,
		"partials": [[1.0, 0.1], [2.0, 0.08], [3.0, 0.05], [4.0, 0.04], [5.0, 0.02], [6.0, 0.015]],
		"notes": [[0.0, 110.0, 3.9], [4.0, 146.83, 3.9], [8.0, 164.81, 3.9], [12.0, 110.0, 3.7]]},  # TUNING (not in GDD) [start (s), Hz, length (s)]
	# Low strings: a bar-long swell of a saw and its fifth, root then fifth per chord.
	"horn": {"starts": [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0], "dur": 1.95, "attack": 0.7, "decay": 0.6, "amp": 0.045,
		"lp0": 350.0, "lp1": 1500.0,
		"notes": [[110.0, 164.81], [110.0, 164.81], [146.83, 220.0], [146.83, 220.0],
			[164.81, 246.94], [164.81, 246.94], [110.0, 164.81], [110.0, 164.81]]},  # TUNING (not in GDD)
	# Oom-pah-pah: a plucked bass on beat 1, the chord on beats 2 and 3 (bars Am Am Dm Dm E E Am Am).
	"waltz": {"beat": 0.66667, "beats_per_bar": 3, "dur": 0.5, "bass_amp": 0.2, "chord_amp": 0.05, "decay": 0.16,
		"lp0": 1600.0, "lp1": 600.0,
		"bars": [
			[55.0, [220.0, 261.63, 329.63]], [55.0, [220.0, 261.63, 329.63]],
			[73.42, [220.0, 293.66, 349.23]], [73.42, [220.0, 293.66, 349.23]],
			[82.41, [246.94, 207.65, 329.63]], [82.41, [246.94, 207.65, 329.63]],
			[55.0, [220.0, 261.63, 329.63]], [55.0, [220.0, 261.63, 329.63]],
		]},  # TUNING (not in GDD) [bass Hz, [chord Hz, ...]] per bar
}

## "Sirens at Midnight", the Act VIII run loop (GDD §15.0 "Sirens at Midnight and the City
## sounds"): the RunLoopSynth score of every stage whose STAGE has "music": "siren". A dark
## urban night track in C minor (Cm, Ab, Eb, Bb), 4/4 at 120 bpm: 4 beats of 0.5 s make a
## 2 s bar, eight bars a 16 s loop, four 4 s chord segments. A driving drum machine (the new
## "machine" job: kick, snare, hats on a 16th grid, in place of the heartbeat), a clean sub
## bass (the new "sub" job), a minor saw arpeggio of eighths (the "arp" job), low brass
## stabs for the army (the "horn" job with a fast attack) and, far above it all, a distant
## siren as a slow soft pitch glide (the new "siren" job: tri sweeps through a low-pass,
## never shrill, never fast) over a velvet drone and a low pad. Rendered lazily (Sfx),
## never under the autotest. Chord order per 4 s segment: Cm, Ab, Eb, Bb.
const SIREN_SCORE := {
	"loop_seconds": 16.0,  # TUNING (not in GDD) eight 4/4 bars of 2 s (120 bpm)
	"root_hz": 65.41,  # TUNING (not in GDD) C2, the drone under C minor
	"chords": [
		[130.81, 155.56, 196.0],
		[103.83, 130.81, 155.56],
		[155.56, 196.0, 233.08],
		[116.54, 146.83, 174.61],
	],  # TUNING (not in GDD) Cm, Ab, Eb, Bb, voiced low
	"drone_lp_hz": 80.0,  # TUNING (not in GDD) a city hum
	"wind_lp_hz": 220.0,  # TUNING (not in GDD) night traffic a long way off
	"wind_swells": 4.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.5,  # TUNING (not in GDD)
	"vibrato_depth": 0.002,  # TUNING (not in GDD)
	# Drum machine: 16 steps of 0.125 s a bar (steps counted from the bar start).
	"machine": {"step": 0.125, "steps_per_bar": 16, "kick_steps": [0, 4, 8, 10, 12], "snare_steps": [4, 12],
		"hat_steps": [0, 2, 4, 6, 8, 10, 12, 14], "open_hat_steps": [14], "kick_amp": 0.42, "snare_amp": 0.2,
		"hat_amp": 0.05, "open_hat_amp": 0.07, "kick_hz0": 130.0, "kick_hz1": 48.0, "kick_dur": 0.3,
		"snare_dur": 0.2, "hat_dur": 0.05, "open_hat_dur": 0.22},  # TUNING (not in GDD)
	# Sub bass: clean sine (plus a faint triangle an octave up) on each bar's root.
	"sub": {"beat": 0.5, "beats_per_bar": 4, "amp": 0.2, "octave_amp": 0.05, "decay": 0.34,
		"roots": [65.41, 65.41, 51.91, 51.91, 77.78, 77.78, 58.27, 58.27],
		"pattern": [[0.0, 1.0, 0.75], [1.5, 1.0, 0.5], [2.0, 1.0, 0.75], [3.5, 1.5, 0.5]]},  # TUNING (not in GDD) [beat, ratio, beats]
	# Minor arpeggio: a saw note every eighth up each segment's tones.
	"arp": {"step": 0.25, "dur": 0.2, "amp": 0.038, "decay": 0.07, "lp0": 2200.0, "wave": "saw",
		"chords": [
			[261.63, 311.13, 392.0, 523.25],
			[207.65, 261.63, 311.13, 415.3],
			[311.13, 392.0, 466.16, 622.25],
			[233.08, 293.66, 349.23, 466.16],
		]},  # TUNING (not in GDD)
	# Low brass stabs for the army: two short hits a segment (root and fifth).
	"horn": {"starts": [1.5, 3.0, 5.5, 7.0, 9.5, 11.0, 13.5, 15.0], "dur": 0.5, "attack": 0.03, "decay": 0.22, "amp": 0.05,
		"lp0": 500.0, "lp1": 1700.0,
		"notes": [[130.81, 196.0], [130.81, 196.0], [103.83, 155.56], [103.83, 155.56],
			[155.56, 233.08], [155.56, 233.08], [116.54, 174.61], [116.54, 174.61]]},  # TUNING (not in GDD)
	# The distant siren: slow tri glides up and down (Hz), overlapped so the wail swells.
	"siren": {"amp": 0.045, "attack": 1.4, "decay": 3.5, "lp0": 1000.0, "lp1": 1000.0, "detune": 1.006, "detune_amp": 0.6,
		"sweeps": [[0.4, 3.6, 640.0, 860.0], [3.6, 3.6, 860.0, 640.0], [8.4, 3.6, 640.0, 860.0], [11.6, 3.6, 860.0, 640.0]]},  # TUNING (not in GDD) [start (s), length (s), from Hz, to Hz]
}

# --- Act IX: the Concord of Stars ---
## "The Reaping Stars", the Act IX run loop (GDD §15.0 "The Reaping Stars and the Concord
## sounds"): the RunLoopSynth score of every stage whose STAGE has "music": "starsong". A vast,
## cold space track in D Phrygian dominant (D Eb F# G A Bb C), 24 s: four 6 s chord segments
## (open fifths and seconds, no thirds: Dsus2, Ebsus2, Gsus2, Bbsus2). A slow pulse (the
## existing "pulse" job, one soft low note every 1.5 s) under glassy pads (the existing "organ"
## job with inharmonic partials and a very slow swell), a very low drone, a sparse glint of
## glass (the existing "hits" job), a soft swelling "harvest" horn (the existing "horn" job
## with a slow attack: it is the Reckoning's colour) and a high, choir-like line (the new
## "choir" job). Never shrill: everything above 1 kHz is a sine or low-passed. Rendered lazily
## (Sfx), never under the autotest.
const STARSONG_SCORE := {
	"loop_seconds": 24.0,  # TUNING (not in GDD) four 6 s chord segments
	"root_hz": 36.71,  # TUNING (not in GDD) D1, a very low drone under D
	"chords": [
		[146.83, 220.0, 329.63],
		[155.56, 233.08, 349.23],
		[196.0, 293.66, 440.0],
		[116.54, 174.61, 261.63],
	],  # TUNING (not in GDD) Dsus2, Ebsus2, Gsus2, Bbsus2: open and cold, no thirds
	"drone_lp_hz": 45.0,  # TUNING (not in GDD) a soft, deep void hum
	"wind_lp_hz": 600.0,  # TUNING (not in GDD) a faint starfield hiss
	"wind_swells": 3.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.25,  # TUNING (not in GDD) the pad barely wavers
	"vibrato_depth": 0.002,  # TUNING (not in GDD)
	# The slow pulse (replaces the heartbeat): a soft low note every 1.5 s, a deeper one every 6 s.
	"pulse": {"step": 1.5, "hz": 55.0, "dur": 0.9, "amp": 0.14, "decay": 0.3, "lp0": 380.0, "lp1": 110.0,
		"accent_every": 4, "accent_amp": 0.22},  # TUNING (not in GDD) A1
	# Glass glints: a quiet inharmonic ping every 6 s, 3 s into each segment.
	"hits": {"every": 6.0, "offset": 3.0, "root_hz": 880.0, "dur": 2.2, "decay": 0.7,
		"partials": [[1.0, 0.045], [2.76, 0.022], [4.1, 0.01]], "click": 0.01},  # TUNING (not in GDD)
	# Glassy pads: sine partials at slightly inharmonic ratios, swelling in over 2 s.
	"organ": {"attack": 2.0, "decay": 4.0, "vib_hz": 0.4, "vib_depth": 0.002,
		"partials": [[1.0, 0.05], [2.0, 0.03], [3.01, 0.02], [5.02, 0.012], [7.03, 0.006]],
		"notes": [[0.0, 293.66, 5.9], [6.0, 311.13, 5.9], [12.0, 392.0, 5.9], [18.0, 349.23, 5.8]]},  # TUNING (not in GDD) [start (s), Hz, length (s)]
	# The harvest horn: a long, soft swell of a saw and its fifth that blooms and fades (twice a loop).
	"horn": {"starts": [0.5, 12.5], "dur": 5.6, "attack": 2.6, "decay": 2.4, "amp": 0.04,
		"lp0": 220.0, "lp1": 900.0,
		"notes": [[73.42, 110.0], [98.0, 146.83]]},  # TUNING (not in GDD)
	# The choir: four detuned saws per note through a low-pass, a slow vowel-like swell and vibrato.
	"choir": {"amp": 0.03, "attack": 1.3, "decay": 2.2, "lp0": 1100.0, "lp1": 1500.0, "vib_hz": 4.5, "vib_depth": 0.006,
		"detune": 1.004, "octave_amp": 0.4,
		"notes": [
			[0.5, 440.0, 3.0], [3.5, 369.99, 2.4],
			[6.5, 466.16, 2.8], [9.5, 523.25, 2.4],
			[12.5, 587.33, 3.0], [15.5, 466.16, 2.4],
			[18.5, 698.46, 2.6], [21.5, 440.0, 2.3]]},  # TUNING (not in GDD) [start (s), Hz, length (s)]
}

## Run-loop scores by STAGE "music" id (Sfx.play_music() modes; "" / absent =
## the Act I loop): "tide" = "Below the Tide" (Act II), "iron" = "Iron Requiem"
## (Act III), "bronze" = "Hymn of Bronze" (Act IV), "sun" = "The Setting Sun" (Act V), "brimstone" = "Hymn of the Pit" (Act VI), "sanguine" = "Waltz of the Red Moon" (Act VII), "siren" = "Sirens at Midnight" (Act VIII). Each has its own fixed synth seed (Sfx.SCORE_SEEDS).
const SCORES := {
	"tide": TIDE_SCORE,
	"iron": IRON_SCORE,
	"bronze": BRONZE_SCORE,
	"sun": SUN_SCORE,  # Act V
	"brimstone": BRIMSTONE_SCORE,  # Act VI
	"sanguine": SANGUINE_SCORE,  # Act VII
	"siren": SIREN_SCORE,  # Act VIII
	# --- Act IX: the Concord of Stars ---
	"starsong": STARSONG_SCORE,  # Act IX: "The Reaping Stars"
	# --- the Necropolis Dynasty (Act VII slot) ---
	"weighing": WEIGHING_SCORE,  # "The Weighing of the Heart"
}
## Sound pack each score asks for when its run starts (Sfx.prepare_pack():
## "empire" = EMPIRE_SOUNDS, the Act III effects; "pantheon" = PANTHEON_SOUNDS,
## the Act IV ones; "shogunate" = SHOGUNATE_SOUNDS, the Act V ones; "inferno" = INFERNO_SOUNDS, the Act VI ones; "court" = COURT_SOUNDS, the Act VII ones; "city" = CITY_SOUNDS, the Act VIII ones); absent = none.
const SCORE_PACKS := {
	"iron": "empire",
	"bronze": "pantheon",
	"sun": "shogunate",  # Act V
	"brimstone": "inferno",  # Act VI
	"sanguine": "court",  # Act VII
	"siren": "city",  # Act VIII
	# --- Act IX: the Concord of Stars ---
	"starsong": "concord",  # Act IX: the Concord sound pack
	"weighing": "dynasty",  # the Necropolis Dynasty sound pack
}

## Act III sound effects (the Electronic Empire; recipe keys as SOUNDS). Kept
## OUT of SOUNDS so the startup bank, its order and its per-sound synth seeds
## stay exactly as before: Sfx renders this pack lazily the first time an Act
## III run's music is asked for (Sfx.prepare_pack(); seeds Sfx.PACK_SEED + i).
const EMPIRE_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# Line Trooper three-round burst: three dry cracks with a metal tail.
	"rifle_burst": {"dur": 0.34, "volume_db": -19.0, "max_voices": 3, "min_interval": 90, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.5, "decay": 0.012, "lp0": 5000.0, "lp1": 1800.0},
			{"wave": "noise", "start": 0.12, "dur": 0.05, "amp": 0.45, "decay": 0.012, "lp0": 5000.0, "lp1": 1800.0},
			{"wave": "noise", "start": 0.24, "dur": 0.05, "amp": 0.42, "decay": 0.012, "lp0": 5000.0, "lp1": 1800.0},
			{"wave": "square", "f0": 180.0, "f1": 90.0, "dur": 0.3, "amp": 0.12, "decay": 0.06, "lp0": 1200.0}]},
	# Drone zap: a short electric buzz.
	"drone_zap": {"dur": 0.12, "volume_db": -22.0, "max_voices": 2, "min_interval": 70, "pitch_var": 0.12, "priority": 0,
		"layers": [
			{"wave": "square", "f0": 1400.0, "f1": 700.0, "dur": 0.1, "amp": 0.22, "decay": 0.03, "lp0": 4000.0},
			{"wave": "noise", "dur": 0.06, "amp": 0.2, "decay": 0.015, "lp0": 6000.0}]},
	# Lock-On paint: a rising two-tone targeting beep.
	"lock_on": {"dur": 0.34, "volume_db": -14.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "square", "f0": 1318.5, "dur": 0.09, "amp": 0.2, "decay": 0.05, "lp0": 5000.0},
			{"wave": "square", "f0": 1760.0, "start": 0.16, "dur": 0.12, "amp": 0.2, "decay": 0.06, "lp0": 5000.0}]},
	# Rail shot: a hard electric crack and a falling magnetic whine.
	"rail_shot": {"dur": 0.5, "volume_db": -12.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.08, "amp": 0.6, "decay": 0.02, "lp0": 9000.0, "lp1": 3000.0},
			{"wave": "saw", "f0": 2400.0, "f1": 300.0, "dur": 0.45, "amp": 0.25, "decay": 0.14, "lp0": 6000.0, "lp1": 900.0},
			{"wave": "sine", "f0": 90.0, "f1": 50.0, "dur": 0.3, "amp": 0.4, "decay": 0.1}]},
	# Servo step (phase 2's walkers and mechs): a short hydraulic whirr and clank.
	"servo_step": {"dur": 0.22, "volume_db": -21.0, "max_voices": 2, "min_interval": 140, "pitch_var": 0.1, "priority": 0,
		"layers": [
			{"wave": "saw", "f0": 260.0, "f1": 420.0, "dur": 0.12, "amp": 0.18, "decay": 0.05, "lp0": 1500.0},
			{"wave": "noise", "start": 0.1, "dur": 0.08, "amp": 0.3, "decay": 0.02, "lp0": 2500.0, "lp1": 800.0},
			{"wave": "sine", "f0": 110.0, "f1": 70.0, "start": 0.1, "dur": 0.12, "amp": 0.3, "decay": 0.04}]},
	# Orbital strike (Purge Protocol): a descending shriek and a heavy boom.
	"orbital_strike": {"dur": 0.9, "volume_db": -10.0, "max_voices": 3, "min_interval": 100, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.85, "amp": 0.6, "attack": 0.005, "decay": 0.25, "lp0": 4000.0, "lp1": 120.0},
			{"wave": "sine", "f0": 70.0, "f1": 30.0, "dur": 0.8, "amp": 0.7, "decay": 0.3},
			{"wave": "square", "f0": 900.0, "f1": 120.0, "dur": 0.3, "amp": 0.12, "decay": 0.1, "lp0": 2000.0}]},
	# --- Act III: the Assembly Halls ---
	# Fabricator build: a pneumatic hiss, a stamping clunk and a rising whine.
	"fabricate": {"dur": 0.5, "volume_db": -17.0, "max_voices": 2, "min_interval": 160, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.18, "amp": 0.35, "decay": 0.06, "lp0": 6000.0, "lp1": 2500.0},
			{"wave": "sine", "f0": 140.0, "f1": 70.0, "start": 0.16, "dur": 0.16, "amp": 0.45, "decay": 0.05},
			{"wave": "saw", "f0": 300.0, "f1": 900.0, "start": 0.22, "dur": 0.26, "amp": 0.12, "decay": 0.12, "lp0": 2500.0}]},
	# Furnace channel flaring: a deep roar of heat.
	"furnace_flare": {"dur": 0.8, "volume_db": -16.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.8, "amp": 0.5, "attack": 0.08, "decay": 0.35, "lp0": 900.0, "lp1": 400.0},
			{"wave": "sine", "f0": 55.0, "f1": 45.0, "dur": 0.7, "amp": 0.35, "attack": 0.05, "decay": 0.3}]},
	# Arc Engineer jam: a crackling static burst.
	"arc_jam": {"dur": 0.45, "volume_db": -15.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.1, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.4, "amp": 0.4, "decay": 0.15, "lp0": 8000.0, "lp1": 3000.0},
			{"wave": "square", "f0": 2200.0, "f1": 1600.0, "dur": 0.35, "amp": 0.12, "decay": 0.12, "lp0": 5000.0}]},
	# Arc Engineer repair: a short welding sizzle.
	"arc_repair": {"dur": 0.3, "volume_db": -21.0, "max_voices": 2, "min_interval": 180, "pitch_var": 0.12, "priority": 0,
		"layers": [
			{"wave": "noise", "dur": 0.28, "amp": 0.3, "decay": 0.1, "lp0": 9000.0, "lp1": 5000.0}]},
	# Juggernaut flamethrower: a breathy whoosh of fire.
	"flamethrower": {"dur": 1.2, "volume_db": -15.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 1.2, "amp": 0.45, "attack": 0.06, "decay": 0.5, "lp0": 2600.0, "lp1": 1200.0},
			{"wave": "sine", "f0": 80.0, "f1": 60.0, "dur": 1.0, "amp": 0.2, "attack": 0.05, "decay": 0.4}]},
	# Motherboard Turret bolt: a sharp electric snap.
	"turret_shot": {"dur": 0.18, "volume_db": -19.0, "max_voices": 3, "min_interval": 90, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "square", "f0": 1200.0, "f1": 300.0, "dur": 0.15, "amp": 0.2, "decay": 0.05, "lp0": 4000.0},
			{"wave": "noise", "dur": 0.05, "amp": 0.3, "decay": 0.015, "lp0": 7000.0}]},
	# Crane arms whirring out.
	"crane_whir": {"dur": 0.7, "volume_db": -15.0, "max_voices": 1, "min_interval": 300, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "saw", "f0": 120.0, "f1": 260.0, "dur": 0.65, "amp": 0.2, "attack": 0.05, "decay": 0.3, "lp0": 1400.0}]},
	# Crane claws clamping shut: a heavy metal clack.
	"crane_clamp": {"dur": 0.3, "volume_db": -13.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.08, "amp": 0.55, "decay": 0.02, "lp0": 4000.0, "lp1": 1500.0},
			{"wave": "square", "f0": 220.0, "f1": 110.0, "dur": 0.25, "amp": 0.18, "decay": 0.08, "lp0": 1500.0}]},
	# Crane throw: a rising servo swing.
	"crane_throw": {"dur": 0.5, "volume_db": -15.0, "max_voices": 1, "min_interval": 200, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "saw", "f0": 200.0, "f1": 700.0, "dur": 0.45, "amp": 0.18, "decay": 0.2, "lp0": 2200.0},
			{"wave": "noise", "dur": 0.4, "amp": 0.2, "attack": 0.1, "decay": 0.15, "lp0": 3000.0}]},
	# Press-stamp charging: a hydraulic build-up.
	"press_charge": {"dur": 0.9, "volume_db": -16.0, "max_voices": 1, "min_interval": 300, "pitch_var": 0.0, "priority": 2,
		"layers": [
			{"wave": "saw", "f0": 80.0, "f1": 220.0, "dur": 0.85, "amp": 0.2, "attack": 0.2, "decay": 0.4, "lp0": 900.0, "lp1": 1800.0}]},
	# Press-stamp landing: a crushing industrial slam.
	"press_stamp": {"dur": 0.7, "volume_db": -11.0, "max_voices": 3, "min_interval": 80, "pitch_var": 0.06, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.12, "amp": 0.7, "decay": 0.04, "lp0": 3000.0, "lp1": 800.0},
			{"wave": "sine", "f0": 65.0, "f1": 35.0, "dur": 0.6, "amp": 0.75, "decay": 0.22},
			{"wave": "square", "f0": 160.0, "f1": 90.0, "dur": 0.2, "amp": 0.15, "decay": 0.07, "lp0": 1200.0}]},
	# Magnet pull: a deep electric hum swelling.
	"magnet_pull": {"dur": 1.4, "volume_db": -14.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.0, "priority": 2,
		"layers": [
			{"wave": "square", "f0": 60.0, "f1": 90.0, "dur": 1.4, "amp": 0.22, "attack": 0.2, "decay": 0.5, "lp0": 500.0},
			{"wave": "sine", "f0": 120.0, "f1": 180.0, "dur": 1.3, "amp": 0.18, "attack": 0.2, "decay": 0.5}]},
	# --- Act III: the Scrap Wastes --- (appended last: the pack's earlier seeds stay as they were)
	# Aegis Bot shield breaking (also the Trojan Horse's hull splitting): a
	# glassy electric crackle falling away.
	"shield_break": {"dur": 0.4, "volume_db": -15.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.3, "amp": 0.45, "decay": 0.08, "lp0": 9000.0, "lp1": 2500.0},
			{"wave": "square", "f0": 2200.0, "f1": 400.0, "dur": 0.35, "amp": 0.15, "decay": 0.1, "lp0": 5000.0}]},
	# Mortar Walker launch: a hollow tube thump and a rising whistle.
	"mortar_launch": {"dur": 0.5, "volume_db": -17.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 120.0, "f1": 60.0, "dur": 0.18, "amp": 0.6, "decay": 0.06},
			{"wave": "noise", "dur": 0.1, "amp": 0.35, "decay": 0.03, "lp0": 1800.0},
			{"wave": "sine", "f0": 700.0, "f1": 1400.0, "start": 0.12, "dur": 0.35, "amp": 0.08, "decay": 0.15}]},
	# Trojan Horse rocket volley: a ripple of hissing launches.
	"rocket_launch": {"dur": 0.6, "volume_db": -14.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.5, "amp": 0.5, "attack": 0.02, "decay": 0.2, "lp0": 3000.0, "lp1": 7000.0},
			{"wave": "saw", "f0": 200.0, "f1": 500.0, "dur": 0.4, "amp": 0.12, "decay": 0.15, "lp0": 2500.0}]},
	# Swarm Rocket / blast burst: a short crackling explosion.
	"rocket_burst": {"dur": 0.45, "volume_db": -15.0, "max_voices": 3, "min_interval": 80, "pitch_var": 0.12, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.4, "amp": 0.6, "decay": 0.1, "lp0": 4000.0, "lp1": 400.0},
			{"wave": "sine", "f0": 90.0, "f1": 40.0, "dur": 0.35, "amp": 0.5, "decay": 0.1}]},
	# Signal Pylon toppled: a dying electric whine and a metal crash.
	"pylon_down": {"dur": 1.0, "volume_db": -11.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 900.0, "f1": 80.0, "dur": 0.8, "amp": 0.18, "decay": 0.3, "lp0": 3000.0, "lp1": 600.0},
			{"wave": "noise", "start": 0.35, "dur": 0.55, "amp": 0.55, "decay": 0.15, "lp0": 2500.0, "lp1": 300.0},
			{"wave": "sine", "f0": 70.0, "f1": 35.0, "start": 0.35, "dur": 0.5, "amp": 0.5, "decay": 0.15}]},
	# Scrap storm rolling in: a long gust of gritty wind.
	"storm_wind": {"dur": 2.4, "volume_db": -12.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 2.3, "amp": 0.45, "attack": 0.6, "decay": 0.9, "lp0": 600.0, "lp1": 1500.0},
			{"wave": "noise", "start": 0.4, "dur": 1.6, "amp": 0.2, "attack": 0.3, "decay": 0.6, "lp0": 3500.0, "lp1": 2000.0}]},
	# --- Act III: the Iron Citadel --- (Act III phase 2; appended, so the pack's
	# earlier sounds keep their seeds; Sfx.PACK_SEED + index)
	# Valkyrie jets firing: a roaring thrust with a rising whine.
	"jet_burst": {"dur": 0.45, "volume_db": -15.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.42, "amp": 0.5, "attack": 0.02, "decay": 0.15, "lp0": 2500.0, "lp1": 6000.0},
			{"wave": "saw", "f0": 300.0, "f1": 900.0, "dur": 0.3, "amp": 0.12, "decay": 0.1, "lp0": 3000.0}]},
	# A lunge stopped by a blocker: a bright steel clang.
	"blade_clang": {"dur": 0.4, "volume_db": -14.0, "max_voices": 2, "min_interval": 90, "pitch_var": 0.1, "priority": 2,
		"layers": [
			{"wave": "square", "f0": 1660.0, "dur": 0.35, "amp": 0.18, "decay": 0.12, "lp0": 7000.0},
			{"wave": "square", "f0": 2490.0, "dur": 0.3, "amp": 0.1, "decay": 0.1, "lp0": 8000.0},
			{"wave": "noise", "dur": 0.05, "amp": 0.35, "decay": 0.015, "lp0": 8000.0}]},
	# Valkyrie 2.0's blade storm: whirling metal.
	"blade_storm": {"dur": 1.0, "volume_db": -14.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.95, "amp": 0.35, "attack": 0.05, "decay": 0.4, "lp0": 3000.0, "lp1": 5000.0},
			{"wave": "saw", "f0": 220.0, "f1": 440.0, "dur": 0.9, "amp": 0.1, "decay": 0.3, "lp0": 2000.0}]},
	# Valkyrie 2.0's shield bash: a heavy thud and a metal ring.
	"shield_bash": {"dur": 0.4, "volume_db": -12.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 120.0, "f1": 60.0, "dur": 0.3, "amp": 0.6, "decay": 0.1},
			{"wave": "square", "f0": 880.0, "dur": 0.3, "amp": 0.1, "decay": 0.1, "lp0": 4000.0}]},
	# Sentry Turret burst: two dry electric pops.
	"turret_fire": {"dur": 0.3, "volume_db": -20.0, "max_voices": 3, "min_interval": 100, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "square", "f0": 600.0, "f1": 200.0, "dur": 0.08, "amp": 0.25, "decay": 0.02, "lp0": 4000.0},
			{"wave": "square", "f0": 600.0, "f1": 200.0, "start": 0.16, "dur": 0.08, "amp": 0.25, "decay": 0.02, "lp0": 4000.0}]},
	# A Shield Gate rising: a low electric hum swelling.
	"gate_hum": {"dur": 1.2, "volume_db": -13.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 55.0, "f1": 110.0, "dur": 1.1, "amp": 0.3, "attack": 0.3, "decay": 0.5, "lp0": 600.0, "lp1": 1500.0},
			{"wave": "sine", "f0": 220.0, "dur": 1.1, "amp": 0.15, "attack": 0.4, "decay": 0.5}]},
	# A Shield Gate falling: a power-down whine and a crash.
	"gate_fall": {"dur": 1.0, "volume_db": -11.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 440.0, "f1": 40.0, "dur": 0.9, "amp": 0.25, "decay": 0.3, "lp0": 3000.0, "lp1": 300.0},
			{"wave": "noise", "start": 0.1, "dur": 0.5, "amp": 0.4, "decay": 0.2, "lp0": 3000.0, "lp1": 400.0}]},
	# A laser grid charging: a thin rising tone (its 1 s telegraph).
	"laser_charge": {"dur": 0.9, "volume_db": -16.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 600.0, "f1": 2400.0, "dur": 0.85, "amp": 0.2, "attack": 0.2, "decay": 0.3}]},
	# A laser grid firing: a hard sizzle.
	"laser_fire": {"dur": 0.5, "volume_db": -12.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.45, "amp": 0.45, "decay": 0.18, "lp0": 9000.0, "lp1": 2000.0},
			{"wave": "square", "f0": 2200.0, "f1": 1800.0, "dur": 0.4, "amp": 0.1, "decay": 0.15, "lp0": 6000.0}]},
	# Deus Ex Machina's chaingun: a long rattling roar.
	"chaingun": {"dur": 1.2, "volume_db": -14.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "square", "f0": 14.0, "dur": 1.15, "amp": 0.25, "decay": 0.5, "lp0": 3000.0},
			{"wave": "noise", "dur": 1.15, "amp": 0.3, "decay": 0.5, "lp0": 4000.0, "lp1": 1500.0}]},
	# The missile salvo locking on: four quick beeps.
	"missile_lock": {"dur": 0.5, "volume_db": -13.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "square", "f0": 1760.0, "dur": 0.06, "amp": 0.18, "decay": 0.03, "lp0": 5000.0},
			{"wave": "square", "f0": 1760.0, "start": 0.12, "dur": 0.06, "amp": 0.18, "decay": 0.03, "lp0": 5000.0},
			{"wave": "square", "f0": 1760.0, "start": 0.24, "dur": 0.06, "amp": 0.18, "decay": 0.03, "lp0": 5000.0},
			{"wave": "square", "f0": 2349.3, "start": 0.36, "dur": 0.1, "amp": 0.2, "decay": 0.05, "lp0": 5000.0}]},
	# A leg plate (or the shield drones) breaking: a screech of torn metal.
	"plate_break": {"dur": 0.7, "volume_db": -11.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.08, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 900.0, "f1": 160.0, "dur": 0.6, "amp": 0.25, "decay": 0.2, "lp0": 5000.0, "lp1": 800.0},
			{"wave": "noise", "dur": 0.3, "amp": 0.45, "decay": 0.1, "lp0": 6000.0, "lp1": 1200.0}]},
	# Deus Ex Machina transforming between phases: grinding servos and a boom.
	"deus_transform": {"dur": 1.6, "volume_db": -9.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 80.0, "f1": 160.0, "dur": 1.2, "amp": 0.3, "attack": 0.1, "decay": 0.5, "lp0": 900.0},
			{"wave": "sine", "f0": 60.0, "f1": 28.0, "start": 1.0, "dur": 0.55, "amp": 0.7, "decay": 0.25}]},
	# The Judgment Lance charging: a deep swelling hum.
	"lance_charge": {"dur": 1.4, "volume_db": -12.0, "max_voices": 1, "min_interval": 800, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 70.0, "f1": 280.0, "dur": 1.35, "amp": 0.28, "attack": 0.4, "decay": 0.5, "lp0": 800.0, "lp1": 3000.0}]},
	# The Judgment Lance firing: a roaring blast.
	"lance_fire": {"dur": 2.2, "volume_db": -10.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 2.1, "amp": 0.45, "attack": 0.02, "decay": 0.9, "lp0": 5000.0, "lp1": 1500.0},
			{"wave": "saw", "f0": 140.0, "dur": 2.0, "amp": 0.2, "decay": 0.9, "lp0": 1200.0}]},
	# The hangar doors opening: a hydraulic hiss and a clank.
	"hangar_open": {"dur": 0.9, "volume_db": -13.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.0, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.6, "amp": 0.35, "decay": 0.25, "lp0": 6000.0, "lp1": 2000.0},
			{"wave": "sine", "f0": 140.0, "f1": 70.0, "start": 0.6, "dur": 0.25, "amp": 0.5, "decay": 0.08}]},
	# An overload pulse rolling out: a deep electric thump.
	"overload_pulse": {"dur": 0.9, "volume_db": -9.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 90.0, "f1": 30.0, "dur": 0.8, "amp": 0.8, "decay": 0.3},
			{"wave": "square", "f0": 400.0, "f1": 80.0, "dur": 0.4, "amp": 0.15, "decay": 0.12, "lp0": 2500.0}]},
	# A teleport charging at its destination: a warbling rise.
	"teleport_charge": {"dur": 0.9, "volume_db": -14.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "square", "f0": 300.0, "f1": 1600.0, "dur": 0.85, "amp": 0.15, "attack": 0.1, "decay": 0.3, "lp0": 3000.0}]},
	# A teleport landing: a sharp crack.
	"teleport_land": {"dur": 0.5, "volume_db": -10.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.2, "amp": 0.6, "decay": 0.06, "lp0": 9000.0, "lp1": 2000.0},
			{"wave": "sine", "f0": 110.0, "f1": 40.0, "dur": 0.4, "amp": 0.6, "decay": 0.15}]},
	# Deus Ex Machina falling: a long power-down and a crash.
	"deus_fall": {"dur": 2.4, "volume_db": -8.0, "max_voices": 1, "min_interval": 2000, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 600.0, "f1": 30.0, "dur": 2.2, "amp": 0.25, "decay": 0.9, "lp0": 3000.0, "lp1": 200.0},
			{"wave": "noise", "start": 0.4, "dur": 1.6, "amp": 0.4, "decay": 0.6, "lp0": 2500.0, "lp1": 200.0},
			{"wave": "sine", "f0": 55.0, "f1": 25.0, "start": 0.4, "dur": 1.2, "amp": 0.7, "decay": 0.4}]},
}

## Web build (no worker threads, GDD §15.0 "Web build"): main-thread time
## budget (ms per frame) for rendering the sound bank and the in-run loop in
## small steps (StartupSynth), so the page never freezes while they render.
## 6 ms of a 16.7 ms frame: the menu keeps 60 fps on a desktop browser.
const WEB_SYNTH_BUDGET_MS: float = 6.0  # TUNING (not in GDD)
## Web build: samples per job of the in-run loop's long passes (drone, chords,
## encoding; RunLoopSynth). Only sets how finely the work is split; the
## rendered loop is the same for any value (>= 1).
const WEB_SYNTH_CHUNK_SAMPLES: int = 8192  # TUNING (not in GDD)

## Act IV sound effects (the Olympian Republic; recipe keys as SOUNDS). Like
## EMPIRE_SOUNDS, kept OUT of SOUNDS so the startup bank and its seeds stay
## exactly as before: Sfx renders this pack lazily the first time an Act IV
## run's music ("bronze") is asked for (Sfx.prepare_pack("pantheon"); seeds
## Sfx.PACK_SEED + Sfx.PACK_SEED_OFFSETS["pantheon"] + i). Mapped to game
## events by the foundation's PantheonRulesData sound map.
const PANTHEON_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# Wrath of the Gods, Poseidon's wave: a rolling surf crash, a long hushed roar that swells and drains.
	"wrath_wave": {"dur": 1.4, "volume_db": -12.0, "max_voices": 2, "min_interval": 500, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 1.35, "amp": 0.55, "attack": 0.35, "decay": 0.55, "lp0": 1800.0, "lp1": 500.0},
			{"wave": "noise", "start": 0.1, "dur": 1.2, "amp": 0.18, "attack": 0.5, "decay": 0.4, "lp0": 6000.0, "lp1": 2500.0},
			{"wave": "sine", "f0": 62.0, "f1": 40.0, "dur": 1.1, "amp": 0.38, "attack": 0.3, "decay": 0.4}]},
	# Zeus' lightning: a sharp crack, a falling sizzle and a rolling boom behind it.
	"wrath_thunder": {"dur": 1.2, "volume_db": -10.0, "max_voices": 3, "min_interval": 90, "pitch_var": 0.06, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.07, "amp": 0.8, "attack": 0.001, "decay": 0.015, "lp0": 12000.0, "lp1": 4000.0},
			{"wave": "noise", "start": 0.04, "dur": 0.5, "amp": 0.3, "decay": 0.16, "lp0": 7000.0, "lp1": 900.0},
			{"wave": "sine", "f0": 80.0, "f1": 32.0, "start": 0.06, "dur": 1.1, "amp": 0.6, "attack": 0.01, "decay": 0.4},
			{"wave": "noise", "start": 0.2, "dur": 0.95, "amp": 0.22, "attack": 0.1, "decay": 0.4, "lp0": 500.0, "lp1": 160.0}]},
	# Hades' fissure: grinding rock splitting, a low sub-drop and a thin hiss.
	"wrath_fissure": {"dur": 1.0, "volume_db": -12.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.9, "amp": 0.5, "attack": 0.04, "decay": 0.35, "lp0": 1100.0, "lp1": 300.0},
			{"wave": "saw", "f0": 70.0, "f1": 38.0, "dur": 0.8, "amp": 0.2, "attack": 0.03, "decay": 0.3, "lp0": 400.0},
			{"wave": "noise", "start": 0.3, "dur": 0.65, "amp": 0.16, "attack": 0.1, "decay": 0.25, "lp0": 9000.0, "lp1": 6000.0}]},
	# Phalanx lock: bronze shields clanging into place, three staggered rims.
	"shield_lock": {"dur": 0.55, "volume_db": -15.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.03, "amp": 0.4, "decay": 0.008, "lp0": 6000.0},
			{"wave": "sine", "f0": 430.0, "dur": 0.4, "amp": 0.2, "decay": 0.12},
			{"wave": "sine", "f0": 990.0, "dur": 0.3, "amp": 0.12, "decay": 0.08},
			{"wave": "noise", "start": 0.07, "dur": 0.03, "amp": 0.3, "decay": 0.008, "lp0": 6000.0},
			{"wave": "sine", "f0": 520.0, "start": 0.07, "dur": 0.35, "amp": 0.16, "decay": 0.1},
			{"wave": "noise", "start": 0.14, "dur": 0.03, "amp": 0.3, "decay": 0.008, "lp0": 6000.0},
			{"wave": "sine", "f0": 380.0, "start": 0.14, "dur": 0.4, "amp": 0.18, "decay": 0.14}]},
	# Phalanx break: a bronze clang with a scraping slide.
	"shield_break": {"dur": 0.5, "volume_db": -14.0, "max_voices": 3, "min_interval": 100, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.04, "amp": 0.5, "decay": 0.01, "lp0": 8000.0},
			{"wave": "sine", "f0": 610.0, "dur": 0.4, "amp": 0.22, "decay": 0.1},
			{"wave": "sine", "f0": 1410.0, "dur": 0.25, "amp": 0.1, "decay": 0.06},
			{"wave": "saw", "f0": 900.0, "f1": 240.0, "start": 0.03, "dur": 0.4, "amp": 0.1, "decay": 0.12, "lp0": 2400.0, "lp1": 700.0},
			{"wave": "noise", "start": 0.05, "dur": 0.35, "amp": 0.2, "decay": 0.1, "lp0": 4000.0, "lp1": 1500.0}]},
	# Glory gained: a short bright brass chime, a fifth over its root.
	"glory_gain": {"dur": 0.45, "volume_db": -17.0, "max_voices": 2, "min_interval": 120, "pitch_var": 0.03, "priority": 1,
		"layers": [
			{"wave": "square", "f0": 587.33, "dur": 0.28, "amp": 0.1, "attack": 0.01, "decay": 0.12, "lp0": 3500.0},
			{"wave": "square", "f0": 880.0, "start": 0.07, "dur": 0.34, "amp": 0.1, "attack": 0.01, "decay": 0.14, "lp0": 4500.0},
			{"wave": "sine", "f0": 1760.0, "start": 0.07, "dur": 0.3, "amp": 0.1, "decay": 0.12}]},
	# Hoplite step: a heavy armoured tread, a dull thud and a rattle of bronze plates.
	"hoplite_step": {"dur": 0.2, "volume_db": -22.0, "max_voices": 3, "min_interval": 130, "pitch_var": 0.12, "priority": 0,
		"layers": [
			{"wave": "sine", "f0": 95.0, "f1": 55.0, "dur": 0.14, "amp": 0.5, "decay": 0.04},
			{"wave": "noise", "dur": 0.06, "amp": 0.25, "decay": 0.02, "lp0": 1800.0, "lp1": 700.0},
			{"wave": "sine", "f0": 1250.0, "start": 0.03, "dur": 0.12, "amp": 0.05, "decay": 0.04}]},
	# Bronze Titan rising: a deep bronze groan, a grinding sweep and a heavy boom under it.
	"titan_rise": {"dur": 1.6, "volume_db": -11.0, "max_voices": 2, "min_interval": 600, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 48.0, "f1": 70.0, "dur": 1.5, "amp": 0.3, "attack": 0.4, "decay": 0.7, "lp0": 300.0, "lp1": 600.0},
			{"wave": "sine", "f0": 32.0, "f1": 24.0, "dur": 1.5, "amp": 0.6, "attack": 0.1, "decay": 0.7},
			{"wave": "noise", "dur": 1.3, "amp": 0.3, "attack": 0.3, "decay": 0.5, "lp0": 700.0, "lp1": 200.0},
			{"wave": "sine", "f0": 232.0, "f1": 190.0, "start": 0.2, "dur": 1.2, "amp": 0.08, "attack": 0.3, "decay": 0.5, "vib_hz": 5.0, "vib_depth": 0.02}]},
	# --- Act IV: the Shores of Ilion ---
	# A cyclops hurls a boulder: a heavy grunt and the whoosh of a rock thrown high.
	"boulder_throw": {"dur": 0.6, "volume_db": -15.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "saw", "f0": 110.0, "f1": 80.0, "dur": 0.18, "amp": 0.18, "attack": 0.01, "decay": 0.08, "lp0": 600.0},
			{"wave": "noise", "start": 0.08, "dur": 0.5, "amp": 0.3, "attack": 0.15, "decay": 0.2, "lp0": 900.0, "lp1": 2800.0}]},
	# A boulder lands (and Polyphemus's stomp): a deep thud, a crack of stone and grit.
	"boulder_land": {"dur": 0.7, "volume_db": -12.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 70.0, "f1": 34.0, "dur": 0.5, "amp": 0.7, "attack": 0.002, "decay": 0.18},
			{"wave": "noise", "dur": 0.08, "amp": 0.6, "decay": 0.02, "lp0": 5000.0, "lp1": 1500.0},
			{"wave": "noise", "start": 0.05, "dur": 0.55, "amp": 0.22, "decay": 0.2, "lp0": 1400.0, "lp1": 400.0}]},
	# A siege tower's timbers: a slow wooden groan and the rumble of wheels.
	"siege_creak": {"dur": 0.9, "volume_db": -20.0, "max_voices": 2, "min_interval": 900, "pitch_var": 0.1, "priority": 0,
		"layers": [
			{"wave": "saw", "f0": 180.0, "f1": 140.0, "dur": 0.7, "amp": 0.12, "attack": 0.12, "decay": 0.3, "lp0": 900.0, "lp1": 500.0, "vib_hz": 9.0, "vib_depth": 0.04},
			{"wave": "noise", "dur": 0.85, "amp": 0.18, "attack": 0.2, "decay": 0.35, "lp0": 300.0, "lp1": 180.0}]},
	# A siege tower crashes down: splintering timbers and a long collapsing rumble.
	"siege_collapse": {"dur": 1.3, "volume_db": -11.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.12, "amp": 0.7, "decay": 0.04, "lp0": 6000.0, "lp1": 2000.0},
			{"wave": "noise", "start": 0.05, "dur": 1.2, "amp": 0.4, "attack": 0.05, "decay": 0.5, "lp0": 1200.0, "lp1": 200.0},
			{"wave": "sine", "f0": 55.0, "f1": 30.0, "start": 0.1, "dur": 1.0, "amp": 0.5, "attack": 0.02, "decay": 0.4},
			{"wave": "saw", "f0": 300.0, "f1": 90.0, "start": 0.02, "dur": 0.4, "amp": 0.1, "decay": 0.15, "lp0": 1500.0}]},
	# A blow to Achilles' heel: a bright bronze ring and a short gasp of air.
	"heel_struck": {"dur": 0.5, "volume_db": -14.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 1320.0, "dur": 0.4, "amp": 0.16, "decay": 0.12},
			{"wave": "sine", "f0": 660.0, "dur": 0.45, "amp": 0.14, "decay": 0.15},
			{"wave": "noise", "dur": 0.2, "amp": 0.2, "attack": 0.02, "decay": 0.07, "lp0": 3000.0, "lp1": 900.0}]},
	# Achilles' war cry: a rising brassy roar over a drum-like boom.
	"achilles_rage": {"dur": 1.4, "volume_db": -10.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.02, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 140.0, "f1": 220.0, "dur": 1.2, "amp": 0.22, "attack": 0.15, "decay": 0.5, "lp0": 1200.0, "lp1": 2200.0, "vib_hz": 6.0, "vib_depth": 0.03},
			{"wave": "square", "f0": 210.0, "f1": 330.0, "start": 0.1, "dur": 1.1, "amp": 0.08, "attack": 0.2, "decay": 0.5, "lp0": 2400.0},
			{"wave": "sine", "f0": 60.0, "f1": 38.0, "dur": 0.8, "amp": 0.55, "attack": 0.005, "decay": 0.3},
			{"wave": "noise", "start": 0.05, "dur": 1.1, "amp": 0.15, "attack": 0.3, "decay": 0.4, "lp0": 2000.0, "lp1": 800.0}]},
	# --- Act IV: Mount Olympus --- (appended last: the pack's earlier seeds stay as they were)
	# Ares's war-cry: a hoarse brass bellow over a war drum.
	"ares_warcry": {"dur": 1.1, "volume_db": -11.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 140.0, "f1": 120.0, "dur": 0.9, "amp": 0.3, "attack": 0.05, "decay": 0.4, "lp0": 1400.0, "lp1": 700.0, "vib_hz": 6.0, "vib_depth": 0.03},
			{"wave": "saw", "f0": 210.0, "f1": 180.0, "dur": 0.8, "amp": 0.15, "attack": 0.08, "decay": 0.35, "lp0": 1800.0, "lp1": 900.0},
			{"wave": "sine", "f0": 70.0, "f1": 45.0, "dur": 0.35, "amp": 0.6, "decay": 0.12},
			{"wave": "noise", "dur": 0.25, "amp": 0.25, "decay": 0.08, "lp0": 900.0}]},
	# Ares's spear charge: a rushing scrape and a heavy footfall.
	"ares_charge": {"dur": 0.6, "volume_db": -14.0, "max_voices": 1, "min_interval": 300, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.5, "amp": 0.4, "attack": 0.05, "decay": 0.2, "lp0": 2500.0, "lp1": 5000.0},
			{"wave": "sine", "f0": 90.0, "f1": 50.0, "dur": 0.25, "amp": 0.5, "decay": 0.08}]},
	# Artemis's hunting horn: a clear rising horn call.
	"artemis_horn": {"dur": 0.9, "volume_db": -14.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.03, "priority": 2,
		"layers": [
			{"wave": "square", "f0": 392.0, "f1": 523.0, "dur": 0.8, "amp": 0.12, "attack": 0.06, "decay": 0.35, "lp0": 2200.0, "lp1": 1600.0},
			{"wave": "sine", "f0": 784.0, "f1": 1046.0, "dur": 0.7, "amp": 0.06, "attack": 0.08, "decay": 0.3}]},
	# Artemis's blink: a silvery shimmer, up then gone.
	"artemis_blink": {"dur": 0.5, "volume_db": -16.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 1400.0, "f1": 2600.0, "dur": 0.4, "amp": 0.1, "attack": 0.02, "decay": 0.18, "vib_hz": 18.0, "vib_depth": 0.02},
			{"wave": "noise", "dur": 0.3, "amp": 0.12, "attack": 0.05, "decay": 0.12, "lp0": 9000.0, "lp1": 4000.0}]},
	# Artemis's volley: a ripple of bowstrings.
	"artemis_volley": {"dur": 0.45, "volume_db": -15.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "square", "f0": 220.0, "f1": 110.0, "dur": 0.12, "amp": 0.12, "decay": 0.04, "lp0": 1800.0},
			{"wave": "noise", "start": 0.04, "dur": 0.35, "amp": 0.3, "decay": 0.12, "lp0": 5000.0, "lp1": 2500.0},
			{"wave": "square", "f0": 260.0, "f1": 130.0, "start": 0.08, "dur": 0.12, "amp": 0.08, "decay": 0.04, "lp0": 1800.0}]},
	# Poseidon's trident throw: a whoosh of air and spray.
	"poseidon_trident": {"dur": 0.5, "volume_db": -14.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.45, "amp": 0.45, "attack": 0.03, "decay": 0.2, "lp0": 1500.0, "lp1": 6000.0},
			{"wave": "sine", "f0": 600.0, "f1": 300.0, "dur": 0.3, "amp": 0.08, "decay": 0.1}]},
	# The sea serpent rising: a deep wet surge and a hiss.
	"serpent_rise": {"dur": 1.0, "volume_db": -12.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.9, "amp": 0.4, "attack": 0.2, "decay": 0.4, "lp0": 600.0, "lp1": 1800.0},
			{"wave": "sine", "f0": 55.0, "f1": 80.0, "dur": 0.8, "amp": 0.5, "attack": 0.15, "decay": 0.35},
			{"wave": "noise", "start": 0.55, "dur": 0.4, "amp": 0.18, "decay": 0.15, "lp0": 8000.0, "lp1": 6000.0}]},
	# A Gorgon's gaze: a rising sibilant hiss and a low drone.
	"gorgon_gaze": {"dur": 1.0, "volume_db": -15.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.9, "amp": 0.25, "attack": 0.4, "decay": 0.3, "lp0": 5000.0, "lp1": 9000.0},
			{"wave": "saw", "f0": 110.0, "f1": 165.0, "dur": 0.9, "amp": 0.1, "attack": 0.3, "decay": 0.3, "lp0": 900.0}]},
	# Summons turned to stone: a dry grinding crackle.
	"petrify": {"dur": 0.5, "volume_db": -14.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.45, "amp": 0.5, "decay": 0.15, "lp0": 2000.0, "lp1": 600.0},
			{"wave": "square", "f0": 90.0, "f1": 60.0, "dur": 0.3, "amp": 0.1, "decay": 0.1, "lp0": 700.0}]},
	# An Amazon's leap: a short war shout and a rush of air.
	"amazon_leap": {"dur": 0.4, "volume_db": -17.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "saw", "f0": 330.0, "f1": 440.0, "dur": 0.2, "amp": 0.1, "attack": 0.02, "decay": 0.08, "lp0": 2400.0},
			{"wave": "noise", "start": 0.1, "dur": 0.3, "amp": 0.25, "decay": 0.1, "lp0": 3000.0, "lp1": 6000.0}]},
	# Zeus raising the bolt: a gathering electric whine.
	"zeus_cast": {"dur": 0.8, "volume_db": -13.0, "max_voices": 1, "min_interval": 300, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 200.0, "f1": 900.0, "dur": 0.7, "amp": 0.12, "attack": 0.3, "decay": 0.2, "lp0": 3000.0, "vib_hz": 22.0, "vib_depth": 0.03},
			{"wave": "noise", "dur": 0.7, "amp": 0.15, "attack": 0.3, "decay": 0.2, "lp0": 6000.0, "lp1": 9000.0}]},
	# Zeus's thunderbolt beam: a searing crack and a long roar.
	"zeus_beam": {"dur": 1.2, "volume_db": -10.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.2, "amp": 0.8, "decay": 0.05, "lp0": 12000.0, "lp1": 6000.0},
			{"wave": "noise", "start": 0.05, "dur": 1.1, "amp": 0.45, "decay": 0.5, "lp0": 2500.0, "lp1": 300.0},
			{"wave": "sine", "f0": 60.0, "f1": 35.0, "dur": 1.0, "amp": 0.6, "decay": 0.45}]},
	# Zeus taking his true form: a vast rising roar of storm and stone.
	"zeus_transform": {"dur": 2.0, "volume_db": -9.0, "max_voices": 1, "min_interval": 1500, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 40.0, "f1": 90.0, "dur": 1.9, "amp": 0.3, "attack": 0.6, "decay": 0.8, "lp0": 400.0, "lp1": 1200.0},
			{"wave": "noise", "dur": 1.9, "amp": 0.4, "attack": 0.5, "decay": 0.9, "lp0": 800.0, "lp1": 3000.0},
			{"wave": "sine", "f0": 30.0, "f1": 22.0, "dur": 1.8, "amp": 0.6, "attack": 0.2, "decay": 0.8}]},
	# --- Act IV: the Asphodel Underworld --- (Cerberus, Hades; played by id)
	# Cerberus's fire breath: a roaring rush of flame, low and rough.
	"fire_breath": {"dur": 1.3, "volume_db": -12.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 1.25, "amp": 0.5, "attack": 0.12, "decay": 0.5, "lp0": 2600.0, "lp1": 900.0},
			{"wave": "saw", "f0": 82.0, "f1": 70.0, "dur": 1.2, "amp": 0.16, "attack": 0.1, "decay": 0.5, "lp0": 500.0}]},
	# Cerberus's pounce: a heavy rush of air and claws scraping off.
	"hound_pounce": {"dur": 0.5, "volume_db": -13.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.45, "amp": 0.4, "attack": 0.05, "decay": 0.18, "lp0": 3000.0, "lp1": 800.0},
			{"wave": "sine", "f0": 140.0, "f1": 70.0, "dur": 0.3, "amp": 0.3, "decay": 0.12}]},
	# Cerberus's bite landing: a snapping crunch with a thud under it.
	"hound_bite": {"dur": 0.45, "volume_db": -11.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.08, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.08, "amp": 0.7, "decay": 0.02, "lp0": 7000.0, "lp1": 2000.0},
			{"wave": "sine", "f0": 90.0, "f1": 40.0, "dur": 0.4, "amp": 0.55, "decay": 0.15},
			{"wave": "square", "f0": 210.0, "f1": 120.0, "start": 0.02, "dur": 0.12, "amp": 0.08, "decay": 0.04, "lp0": 1500.0}]},
	# Cerberus's howl: three voices rising and falling a fifth apart, a long wolf howl.
	"hound_howl": {"dur": 1.6, "volume_db": -12.0, "max_voices": 2, "min_interval": 600, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 260.0, "f1": 330.0, "dur": 1.5, "amp": 0.12, "attack": 0.25, "decay": 0.6, "lp0": 1400.0, "vib_hz": 5.5, "vib_depth": 0.02},
			{"wave": "saw", "f0": 390.0, "f1": 495.0, "start": 0.08, "dur": 1.4, "amp": 0.09, "attack": 0.25, "decay": 0.6, "lp0": 1800.0, "vib_hz": 6.0, "vib_depth": 0.02},
			{"wave": "sine", "f0": 195.0, "f1": 230.0, "start": 0.04, "dur": 1.45, "amp": 0.14, "attack": 0.3, "decay": 0.6}]},
	# Hades rising (his arrival, a phase change, his ring): a deep choir-like drone swelling up.
	"hades_rise": {"dur": 2.0, "volume_db": -10.0, "max_voices": 1, "min_interval": 900, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 55.0, "f1": 49.0, "dur": 1.9, "amp": 0.55, "attack": 0.5, "decay": 0.8},
			{"wave": "saw", "f0": 110.0, "f1": 98.0, "dur": 1.8, "amp": 0.14, "attack": 0.6, "decay": 0.7, "lp0": 700.0, "vib_hz": 4.0, "vib_depth": 0.01},
			{"wave": "sine", "f0": 165.0, "f1": 147.0, "start": 0.3, "dur": 1.5, "amp": 0.1, "attack": 0.5, "decay": 0.6},
			{"wave": "noise", "dur": 1.6, "amp": 0.15, "attack": 0.4, "decay": 0.7, "lp0": 600.0, "lp1": 200.0}]},
	# The Helm of Darkness on: a breath drawn inward, a fading hiss.
	"helm_cloak": {"dur": 0.8, "volume_db": -14.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.03, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.75, "amp": 0.35, "attack": 0.4, "decay": 0.15, "lp0": 4000.0, "lp1": 9000.0},
			{"wave": "sine", "f0": 220.0, "f1": 110.0, "dur": 0.7, "amp": 0.12, "attack": 0.3, "decay": 0.3}]},
	# The Helm off: a cold shimmer snapping back into sight.
	"helm_reveal": {"dur": 0.6, "volume_db": -14.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.03, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.15, "amp": 0.4, "decay": 0.05, "lp0": 9000.0, "lp1": 3000.0},
			{"wave": "sine", "f0": 660.0, "f1": 880.0, "dur": 0.5, "amp": 0.12, "decay": 0.2},
			{"wave": "sine", "f0": 990.0, "f1": 1320.0, "start": 0.05, "dur": 0.4, "amp": 0.07, "decay": 0.16}]},
	# Hades marks (his sigils, a god's shade rising): a hollow bell struck under water.
	"hades_mark": {"dur": 1.1, "volume_db": -13.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 311.0, "dur": 1.0, "amp": 0.22, "attack": 0.005, "decay": 0.45},
			{"wave": "sine", "f0": 466.0, "dur": 0.9, "amp": 0.12, "attack": 0.005, "decay": 0.4, "vib_hz": 3.0, "vib_depth": 0.01},
			{"wave": "sine", "f0": 155.5, "dur": 1.05, "amp": 0.16, "attack": 0.01, "decay": 0.5}]},
	# The bident sweep: a heavy whoosh and a ringing bronze edge.
	"bident_sweep": {"dur": 0.55, "volume_db": -12.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.35, "amp": 0.45, "attack": 0.08, "decay": 0.12, "lp0": 1800.0, "lp1": 5000.0},
			{"wave": "sine", "f0": 740.0, "start": 0.12, "dur": 0.4, "amp": 0.1, "decay": 0.14}]},
	# Artemis's shade's volley: a flight of thin whistling arrows.
	"moon_volley": {"dur": 0.6, "volume_db": -14.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.5, "amp": 0.25, "attack": 0.05, "decay": 0.2, "lp0": 9000.0, "lp1": 4000.0},
			{"wave": "sine", "f0": 1800.0, "f1": 1300.0, "dur": 0.45, "amp": 0.06, "decay": 0.18},
			{"wave": "sine", "f0": 2100.0, "f1": 1500.0, "start": 0.06, "dur": 0.4, "amp": 0.05, "decay": 0.16}]},
	# Hades kneels: a long falling choir note over a soft bronze ring (the ending).
	"hades_kneel": {"dur": 2.6, "volume_db": -9.0, "max_voices": 1, "min_interval": 3000, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 196.0, "f1": 130.8, "dur": 2.4, "amp": 0.3, "attack": 0.2, "decay": 1.0, "vib_hz": 4.5, "vib_depth": 0.01},
			{"wave": "sine", "f0": 293.7, "f1": 196.0, "start": 0.1, "dur": 2.3, "amp": 0.18, "attack": 0.25, "decay": 1.0},
			{"wave": "sine", "f0": 587.3, "start": 0.4, "dur": 1.8, "amp": 0.08, "attack": 0.01, "decay": 0.8},
			{"wave": "sine", "f0": 49.0, "dur": 2.5, "amp": 0.4, "attack": 0.3, "decay": 1.0}]},
}

## Act V sound effects (the Shogunate of the Rising Sun; recipe keys as SOUNDS).
## Kept OUT of SOUNDS like the other packs: Sfx renders it lazily the first time
## an Act V run's music ("sun") is asked for (Sfx.prepare_pack("shogunate"); seeds
## Sfx.PACK_SEED + Sfx.PACK_SEED_OFFSETS["shogunate"] + i). Nothing plays them
## until the lead wires the foundation's sound map.
const SHOGUNATE_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# The Draw, the tell: a thin steel ring as a blade leaves the saya.
	"draw_flash": {"dur": 0.5, "volume_db": -17.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.12, "amp": 0.16, "attack": 0.02, "decay": 0.05, "lp0": 3000.0, "lp1": 9000.0},
			{"wave": "sine", "f0": 2640.0, "f1": 3100.0, "start": 0.04, "dur": 0.42, "amp": 0.14, "attack": 0.004, "decay": 0.16},
			{"wave": "sine", "f0": 4180.0, "f1": 4400.0, "start": 0.05, "dur": 0.34, "amp": 0.07, "attack": 0.004, "decay": 0.1},
			{"wave": "sine", "f0": 1320.0, "start": 0.04, "dur": 0.3, "amp": 0.06, "decay": 0.1}]},
	# The Draw, the cut: a fast slicing whoosh with a sharp tail.
	"draw_cut": {"dur": 0.4, "volume_db": -14.0, "max_voices": 3, "min_interval": 90, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.16, "amp": 0.42, "attack": 0.03, "decay": 0.06, "lp0": 1500.0, "lp1": 9000.0},
			{"wave": "noise", "start": 0.13, "dur": 0.05, "amp": 0.4, "attack": 0.001, "decay": 0.012, "lp0": 9000.0, "lp1": 6000.0},
			{"wave": "sine", "f0": 3300.0, "f1": 2200.0, "start": 0.13, "dur": 0.25, "amp": 0.1, "attack": 0.002, "decay": 0.07}]},
	# Ninja smoke bomb: a soft burst and a hiss.
	"smoke_puff": {"dur": 0.7, "volume_db": -18.0, "max_voices": 3, "min_interval": 140, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 120.0, "f1": 55.0, "dur": 0.16, "amp": 0.3, "attack": 0.004, "decay": 0.05},
			{"wave": "noise", "dur": 0.1, "amp": 0.3, "attack": 0.004, "decay": 0.03, "lp0": 2500.0, "lp1": 900.0},
			{"wave": "noise", "start": 0.05, "dur": 0.6, "amp": 0.2, "attack": 0.1, "decay": 0.2, "lp0": 7000.0, "lp1": 3000.0}]},
	# Teppo volley: a ragged crackle of matchlocks, six cracks out of time.
	"teppo_volley": {"dur": 0.9, "volume_db": -15.0, "max_voices": 3, "min_interval": 150, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.6, "attack": 0.001, "decay": 0.012, "lp0": 7000.0, "lp1": 1800.0},
			{"wave": "noise", "start": 0.07, "dur": 0.05, "amp": 0.5, "attack": 0.001, "decay": 0.012, "lp0": 6500.0, "lp1": 1600.0},
			{"wave": "noise", "start": 0.13, "dur": 0.05, "amp": 0.55, "attack": 0.001, "decay": 0.012, "lp0": 7500.0, "lp1": 2000.0},
			{"wave": "noise", "start": 0.25, "dur": 0.05, "amp": 0.42, "attack": 0.001, "decay": 0.012, "lp0": 6000.0, "lp1": 1700.0},
			{"wave": "noise", "start": 0.33, "dur": 0.05, "amp": 0.46, "attack": 0.001, "decay": 0.012, "lp0": 7000.0, "lp1": 1800.0},
			{"wave": "noise", "start": 0.52, "dur": 0.05, "amp": 0.35, "attack": 0.001, "decay": 0.012, "lp0": 6500.0, "lp1": 1500.0},
			{"wave": "sine", "f0": 90.0, "f1": 50.0, "dur": 0.4, "amp": 0.3, "decay": 0.1},
			{"wave": "noise", "start": 0.05, "dur": 0.8, "amp": 0.1, "attack": 0.05, "decay": 0.3, "lp0": 900.0, "lp1": 300.0}]},
	# One deep taiko hit.
	"taiko_hit": {"dur": 0.8, "volume_db": -11.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 105.0, "f1": 42.0, "dur": 0.7, "amp": 0.75, "attack": 0.003, "decay": 0.2},
			{"wave": "sine", "f0": 190.0, "f1": 90.0, "dur": 0.25, "amp": 0.25, "attack": 0.002, "decay": 0.06},
			{"wave": "noise", "dur": 0.06, "amp": 0.35, "attack": 0.001, "decay": 0.015, "lp0": 1600.0, "lp1": 600.0}]},
	# A paper lantern lit: a soft paper whump and a flicker of flame.
	"lantern_lit": {"dur": 0.7, "volume_db": -19.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 140.0, "f1": 70.0, "dur": 0.25, "amp": 0.4, "attack": 0.015, "decay": 0.08},
			{"wave": "noise", "dur": 0.2, "amp": 0.25, "attack": 0.03, "decay": 0.07, "lp0": 800.0, "lp1": 1800.0},
			{"wave": "noise", "start": 0.12, "dur": 0.55, "amp": 0.12, "attack": 0.08, "decay": 0.2, "lp0": 3200.0, "lp1": 1500.0}]},
	# Nightfall: a low falling swell with a temple bell.
	"nightfall": {"dur": 2.4, "volume_db": -12.0, "max_voices": 1, "min_interval": 1500, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 110.0, "f1": 41.0, "dur": 2.3, "amp": 0.26, "attack": 0.7, "decay": 0.9, "lp0": 500.0, "lp1": 140.0},
			{"wave": "sine", "f0": 55.0, "f1": 36.0, "dur": 2.3, "amp": 0.45, "attack": 0.5, "decay": 0.9},
			{"wave": "sine", "f0": 220.0, "start": 0.5, "dur": 1.9, "amp": 0.2, "attack": 0.004, "decay": 0.6},
			{"wave": "sine", "f0": 607.0, "start": 0.5, "dur": 1.5, "amp": 0.1, "attack": 0.004, "decay": 0.35},
			{"wave": "sine", "f0": 1180.0, "start": 0.5, "dur": 1.0, "amp": 0.05, "attack": 0.004, "decay": 0.2}]},
	# An oni's iron club: a heavy impact, a crack of metal and a rolling thud.
	"oni_smash": {"dur": 0.9, "volume_db": -10.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.06, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 80.0, "f1": 30.0, "dur": 0.7, "amp": 0.8, "attack": 0.002, "decay": 0.22},
			{"wave": "noise", "dur": 0.07, "amp": 0.7, "attack": 0.001, "decay": 0.018, "lp0": 6000.0, "lp1": 1500.0},
			{"wave": "sine", "f0": 330.0, "f1": 300.0, "dur": 0.5, "amp": 0.14, "decay": 0.14},
			{"wave": "sine", "f0": 760.0, "dur": 0.35, "amp": 0.07, "decay": 0.09},
			{"wave": "noise", "start": 0.06, "dur": 0.6, "amp": 0.25, "attack": 0.02, "decay": 0.22, "lp0": 1200.0, "lp1": 300.0}]},
	# --- Act V: the Burning Province ---
	# A sake barrel bursts into fire: splintering staves, a splash and a whoosh of flame.
	"sake_burst": {"dur": 0.9, "volume_db": -12.0, "max_voices": 3, "min_interval": 110, "pitch_var": 0.07, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.09, "amp": 0.6, "attack": 0.001, "decay": 0.025, "lp0": 5000.0, "lp1": 1600.0},
			{"wave": "sine", "f0": 95.0, "f1": 40.0, "dur": 0.4, "amp": 0.45, "attack": 0.002, "decay": 0.12},
			{"wave": "noise", "start": 0.04, "dur": 0.25, "amp": 0.22, "attack": 0.01, "decay": 0.08, "lp0": 2400.0, "lp1": 800.0},
			{"wave": "noise", "start": 0.1, "dur": 0.75, "amp": 0.24, "attack": 0.12, "decay": 0.3, "lp0": 900.0, "lp1": 3200.0}]},
	# Kage's chained kunai: a fast throw and a rattle of chain links.
	"kunai_chain": {"dur": 0.6, "volume_db": -15.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.12, "amp": 0.3, "attack": 0.02, "decay": 0.05, "lp0": 2000.0, "lp1": 8000.0},
			{"wave": "sine", "f0": 2900.0, "start": 0.12, "dur": 0.08, "amp": 0.1, "decay": 0.03},
			{"wave": "sine", "f0": 3400.0, "start": 0.2, "dur": 0.08, "amp": 0.09, "decay": 0.03},
			{"wave": "sine", "f0": 3100.0, "start": 0.28, "dur": 0.08, "amp": 0.08, "decay": 0.03},
			{"wave": "noise", "start": 0.12, "dur": 0.4, "amp": 0.1, "attack": 0.01, "decay": 0.15, "lp0": 6000.0, "lp1": 3000.0}]},
	# Kage splits into her shadows: a hollow swirl that drops away.
	"kage_split": {"dur": 1.0, "volume_db": -13.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.9, "amp": 0.25, "attack": 0.3, "decay": 0.35, "lp0": 600.0, "lp1": 3500.0},
			{"wave": "sine", "f0": 440.0, "f1": 220.0, "dur": 0.8, "amp": 0.14, "attack": 0.1, "decay": 0.3, "vib_hz": 7.0, "vib_depth": 0.04},
			{"wave": "sine", "f0": 660.0, "f1": 330.0, "start": 0.1, "dur": 0.7, "amp": 0.07, "attack": 0.1, "decay": 0.25}]},
	# --- Act V: the Road to the Sun ---
	# The Kirin's gallop: a rush of hooves on stone and a bright chime.
	"kirin_gallop": {"dur": 0.7, "volume_db": -12.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.5, "amp": 0.4, "attack": 0.02, "decay": 0.2, "lp0": 1200.0, "lp1": 2600.0},
			{"wave": "sine", "f0": 90.0, "f1": 60.0, "dur": 0.4, "amp": 0.4, "attack": 0.005, "decay": 0.15},
			{"wave": "sine", "f0": 1568.0, "start": 0.05, "dur": 0.6, "amp": 0.08, "attack": 0.005, "decay": 0.25}]},
	# The Horn of Heaven: a pure rising tone and a shimmer of bells.
	"kirin_horn": {"dur": 1.0, "volume_db": -13.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.02, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 784.0, "f1": 1046.0, "dur": 0.9, "amp": 0.16, "attack": 0.05, "decay": 0.35},
			{"wave": "sine", "f0": 1568.0, "f1": 2093.0, "start": 0.05, "dur": 0.8, "amp": 0.07, "attack": 0.02, "decay": 0.3},
			{"wave": "noise", "dur": 0.6, "amp": 0.1, "attack": 0.1, "decay": 0.25, "lp0": 9000.0, "lp1": 5000.0}]},
	# Amaterasu rises (and crosses the sky): a swelling choir chord in the D in scale.
	"amaterasu_rise": {"dur": 2.2, "volume_db": -10.0, "max_voices": 1, "min_interval": 1500, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 146.8, "dur": 2.1, "amp": 0.26, "attack": 0.8, "decay": 0.8, "vib_hz": 4.0, "vib_depth": 0.008},
			{"wave": "sine", "f0": 220.0, "start": 0.2, "dur": 1.9, "amp": 0.18, "attack": 0.7, "decay": 0.7},
			{"wave": "sine", "f0": 293.7, "start": 0.4, "dur": 1.7, "amp": 0.12, "attack": 0.6, "decay": 0.6},
			{"wave": "noise", "dur": 2.0, "amp": 0.08, "attack": 0.9, "decay": 0.8, "lp0": 3000.0, "lp1": 7000.0}]},
	# Her mirror gathers light: a bright rising whine.
	"sun_charge": {"dur": 0.9, "volume_db": -15.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 660.0, "f1": 1320.0, "dur": 0.85, "amp": 0.12, "attack": 0.4, "decay": 0.2},
			{"wave": "noise", "dur": 0.8, "amp": 0.1, "attack": 0.4, "decay": 0.2, "lp0": 4000.0, "lp1": 9000.0}]},
	# A beam of the sun strikes: a searing roar.
	"sun_beam": {"dur": 0.8, "volume_db": -11.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.7, "amp": 0.45, "attack": 0.01, "decay": 0.3, "lp0": 6000.0, "lp1": 1500.0},
			{"wave": "saw", "f0": 220.0, "f1": 110.0, "dur": 0.6, "amp": 0.12, "attack": 0.01, "decay": 0.25, "lp0": 1800.0}]},
	# A sun-disc mine bursts: a bright crack and a hiss.
	"sun_mine": {"dur": 0.5, "volume_db": -13.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.06, "amp": 0.6, "attack": 0.001, "decay": 0.02, "lp0": 9000.0, "lp1": 4000.0},
			{"wave": "noise", "start": 0.04, "dur": 0.4, "amp": 0.2, "attack": 0.01, "decay": 0.18, "lp0": 5000.0, "lp1": 2000.0},
			{"wave": "sine", "f0": 1200.0, "f1": 600.0, "dur": 0.2, "amp": 0.1, "decay": 0.08}]},
	# The noon glare: a long building white hiss.
	"noon_glare": {"dur": 1.6, "volume_db": -13.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.0, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 1.5, "amp": 0.3, "attack": 1.0, "decay": 0.3, "lp0": 3000.0, "lp1": 9000.0},
			{"wave": "sine", "f0": 1046.0, "f1": 1568.0, "dur": 1.4, "amp": 0.06, "attack": 1.0, "decay": 0.3}]},
	# The sun goes out: a vast falling chord and a final temple bell.
	"sun_goes_out": {"dur": 3.0, "volume_db": -8.0, "max_voices": 1, "min_interval": 3000, "pitch_var": 0.0, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 293.7, "f1": 73.4, "dur": 2.8, "amp": 0.3, "attack": 0.05, "decay": 1.2},
			{"wave": "sine", "f0": 440.0, "f1": 110.0, "dur": 2.6, "amp": 0.18, "attack": 0.05, "decay": 1.1},
			{"wave": "sine", "f0": 36.7, "dur": 2.9, "amp": 0.45, "attack": 0.2, "decay": 1.2},
			{"wave": "sine", "f0": 220.0, "start": 1.2, "dur": 1.7, "amp": 0.18, "attack": 0.004, "decay": 0.6},
			{"wave": "sine", "f0": 607.0, "start": 1.2, "dur": 1.4, "amp": 0.08, "attack": 0.004, "decay": 0.4}]},
	# --- Act V: Castle Kurogane ---
	# A cavalry charge (Kiba-musha, the General of the Left): drumming hooves under a rising whinny.
	"cavalry_charge": {"dur": 0.9, "volume_db": -15.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.08, "amp": 0.45, "decay": 0.03, "lp0": 900.0, "lp1": 300.0},
			{"wave": "noise", "start": 0.16, "dur": 0.08, "amp": 0.45, "decay": 0.03, "lp0": 900.0, "lp1": 300.0},
			{"wave": "noise", "start": 0.32, "dur": 0.08, "amp": 0.45, "decay": 0.03, "lp0": 900.0, "lp1": 300.0},
			{"wave": "noise", "start": 0.48, "dur": 0.08, "amp": 0.45, "decay": 0.03, "lp0": 900.0, "lp1": 300.0},
			{"wave": "saw", "f0": 520.0, "f1": 760.0, "start": 0.05, "dur": 0.5, "amp": 0.06, "attack": 0.08, "decay": 0.2, "lp0": 2200.0, "vib_hz": 11.0, "vib_depth": 0.05}]},
	# A regiment breaks (its Hatamoto falls): a banner pole snapping and a low taiko roll fading out.
	"regiment_break": {"dur": 1.2, "volume_db": -11.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.1, "amp": 0.6, "decay": 0.03, "lp0": 5000.0, "lp1": 1500.0},
			{"wave": "sine", "f0": 70.0, "f1": 45.0, "start": 0.05, "dur": 0.4, "amp": 0.55, "attack": 0.003, "decay": 0.15},
			{"wave": "sine", "f0": 66.0, "f1": 42.0, "start": 0.35, "dur": 0.4, "amp": 0.4, "attack": 0.003, "decay": 0.15},
			{"wave": "sine", "f0": 62.0, "f1": 40.0, "start": 0.65, "dur": 0.5, "amp": 0.28, "attack": 0.003, "decay": 0.18}]},
}

## Act VI sound effects (the Inferno; recipe keys as SOUNDS). Kept OUT of SOUNDS
## like the other packs: Sfx renders it lazily the first time an Act VI run's music
## ("brimstone") is asked for (Sfx.prepare_pack("inferno"); seeds Sfx.PACK_SEED +
## Sfx.PACK_SEED_OFFSETS["inferno"] + i). Nothing plays them until the lead wires the
## foundation's sound map (InfernoRulesData).
const INFERNO_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# A pit opens: a rumbling crack of rock and a long lava hiss.
	"pit_open": {"dur": 1.4, "volume_db": -11.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 70.0, "f1": 30.0, "dur": 1.0, "amp": 0.7, "attack": 0.01, "decay": 0.35},
			{"wave": "noise", "dur": 0.08, "amp": 0.7, "attack": 0.001, "decay": 0.02, "lp0": 5000.0, "lp1": 1200.0},
			{"wave": "noise", "start": 0.05, "dur": 0.9, "amp": 0.35, "attack": 0.04, "decay": 0.3, "lp0": 600.0, "lp1": 200.0},
			{"wave": "noise", "start": 0.15, "dur": 1.2, "amp": 0.16, "attack": 0.2, "decay": 0.5, "lp0": 7000.0, "lp1": 3000.0}]},
	# Something burning in a pit: a short sizzle.
	"pit_burn": {"dur": 0.35, "volume_db": -20.0, "max_voices": 4, "min_interval": 90, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.3, "amp": 0.3, "attack": 0.01, "decay": 0.08, "lp0": 8000.0, "lp1": 4000.0},
			{"wave": "noise", "start": 0.02, "dur": 0.04, "amp": 0.3, "attack": 0.001, "decay": 0.01, "lp0": 3000.0},
			{"wave": "noise", "start": 0.12, "dur": 0.03, "amp": 0.25, "attack": 0.001, "decay": 0.008, "lp0": 2500.0},
			{"wave": "sine", "f0": 90.0, "f1": 60.0, "dur": 0.15, "amp": 0.15, "decay": 0.05}]},
	# A demon portal tears open: a deep whoosh and a dissonant choir swell.
	"portal_open": {"dur": 1.8, "volume_db": -12.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 1.5, "amp": 0.5, "attack": 0.6, "decay": 0.5, "lp0": 300.0, "lp1": 1800.0},
			{"wave": "sine", "f0": 60.0, "f1": 45.0, "dur": 1.7, "amp": 0.45, "attack": 0.5, "decay": 0.7},
			{"wave": "tri", "f0": 196.0, "dur": 1.6, "amp": 0.14, "attack": 0.7, "decay": 0.6, "vib_hz": 5.0, "vib_depth": 0.01},
			{"wave": "tri", "f0": 277.2, "dur": 1.6, "amp": 0.12, "attack": 0.75, "decay": 0.6, "vib_hz": 5.3, "vib_depth": 0.01},
			{"wave": "tri", "f0": 392.0, "dur": 1.5, "amp": 0.08, "attack": 0.8, "decay": 0.5, "vib_hz": 4.7, "vib_depth": 0.01}]},
	# A portal sealed: a heavy slam and a tolling bell.
	"portal_seal": {"dur": 1.6, "volume_db": -10.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 90.0, "f1": 32.0, "dur": 0.6, "amp": 0.8, "attack": 0.002, "decay": 0.18},
			{"wave": "noise", "dur": 0.07, "amp": 0.6, "attack": 0.001, "decay": 0.018, "lp0": 4000.0, "lp1": 900.0},
			{"wave": "sine", "f0": 233.0, "start": 0.08, "dur": 1.5, "amp": 0.22, "attack": 0.003, "decay": 0.55},
			{"wave": "sine", "f0": 643.0, "start": 0.08, "dur": 1.1, "amp": 0.12, "attack": 0.003, "decay": 0.35},
			{"wave": "sine", "f0": 1258.0, "start": 0.08, "dur": 0.7, "amp": 0.05, "attack": 0.003, "decay": 0.18}]},
	# Temptation lands: a soft kiss (a lip pop, a rising "mwah") over a shimmering chime.
	"charm_kiss": {"dur": 0.9, "volume_db": -15.0, "max_voices": 3, "min_interval": 150, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.2, "attack": 0.008, "decay": 0.015, "lp0": 2500.0, "lp1": 1200.0},
			{"wave": "sine", "f0": 380.0, "f1": 640.0, "start": 0.02, "dur": 0.12, "amp": 0.2, "attack": 0.01, "decay": 0.05},
			{"wave": "noise", "start": 0.14, "dur": 0.025, "amp": 0.25, "attack": 0.001, "decay": 0.006, "lp0": 4500.0},
			{"wave": "sine", "f0": 1568.0, "start": 0.12, "dur": 0.7, "amp": 0.1, "attack": 0.004, "decay": 0.25, "vib_hz": 7.0, "vib_depth": 0.004},
			{"wave": "sine", "f0": 2349.0, "start": 0.16, "dur": 0.6, "amp": 0.06, "attack": 0.004, "decay": 0.2, "vib_hz": 8.0, "vib_depth": 0.004},
			{"wave": "sine", "f0": 3136.0, "start": 0.2, "dur": 0.5, "amp": 0.035, "attack": 0.004, "decay": 0.15}]},
	# A charm breaks: a glassy snap.
	"charm_break": {"dur": 0.5, "volume_db": -14.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.03, "amp": 0.6, "attack": 0.001, "decay": 0.008, "lp0": 9000.0, "lp1": 5000.0},
			{"wave": "sine", "f0": 3520.0, "f1": 2200.0, "dur": 0.3, "amp": 0.14, "attack": 0.001, "decay": 0.07},
			{"wave": "sine", "f0": 4700.0, "f1": 3000.0, "dur": 0.2, "amp": 0.08, "attack": 0.001, "decay": 0.045},
			{"wave": "noise", "start": 0.05, "dur": 0.3, "amp": 0.12, "attack": 0.002, "decay": 0.06, "lp0": 9000.0, "lp1": 6000.0}]},
	# An imp's cackle: a short chittering laugh, five square blips rising and falling.
	"imp_cackle": {"dur": 0.6, "volume_db": -18.0, "max_voices": 3, "min_interval": 180, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "square", "f0": 620.0, "f1": 760.0, "dur": 0.07, "amp": 0.14, "attack": 0.004, "decay": 0.03, "lp0": 3000.0},
			{"wave": "square", "f0": 720.0, "f1": 880.0, "start": 0.1, "dur": 0.07, "amp": 0.14, "attack": 0.004, "decay": 0.03, "lp0": 3000.0},
			{"wave": "square", "f0": 660.0, "f1": 820.0, "start": 0.2, "dur": 0.07, "amp": 0.13, "attack": 0.004, "decay": 0.03, "lp0": 3000.0},
			{"wave": "square", "f0": 560.0, "f1": 700.0, "start": 0.3, "dur": 0.07, "amp": 0.12, "attack": 0.004, "decay": 0.03, "lp0": 3000.0},
			{"wave": "square", "f0": 480.0, "f1": 620.0, "start": 0.4, "dur": 0.08, "amp": 0.11, "attack": 0.004, "decay": 0.035, "lp0": 3000.0},
			{"wave": "noise", "dur": 0.5, "amp": 0.04, "attack": 0.02, "decay": 0.2, "lp0": 5000.0, "lp1": 3500.0}]},
	# A brute's slam: a ground-shaking impact, a crack and a long rolling rumble.
	"brute_slam": {"dur": 1.2, "volume_db": -9.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 70.0, "f1": 24.0, "dur": 0.9, "amp": 0.95, "attack": 0.002, "decay": 0.28},
			{"wave": "noise", "dur": 0.08, "amp": 0.8, "attack": 0.001, "decay": 0.02, "lp0": 5000.0, "lp1": 1000.0},
			{"wave": "sine", "f0": 140.0, "f1": 60.0, "dur": 0.4, "amp": 0.3, "decay": 0.1},
			{"wave": "noise", "start": 0.05, "dur": 1.0, "amp": 0.35, "attack": 0.03, "decay": 0.35, "lp0": 700.0, "lp1": 150.0}]},
	# --- Act VI: the Burning Gate --- (appended at the END: the pack's seeds follow its order)
	# Moloch's furnace roars: a deep bull's bellow over a rising roar of flame.
	"moloch_roar": {"dur": 1.6, "volume_db": -10.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 82.0, "f1": 62.0, "dur": 1.2, "amp": 0.28, "attack": 0.08, "decay": 0.45, "lp0": 600.0, "lp1": 300.0, "vib_hz": 6.0, "vib_depth": 0.03},
			{"wave": "sine", "f0": 55.0, "f1": 40.0, "dur": 1.4, "amp": 0.5, "attack": 0.1, "decay": 0.5},
			{"wave": "noise", "start": 0.1, "dur": 1.4, "amp": 0.32, "attack": 0.4, "decay": 0.5, "lp0": 400.0, "lp1": 2400.0}]},
	# The Gatekeeper's chains fly out: a heavy rattle of iron links and a whip.
	"chain_haul": {"dur": 0.8, "volume_db": -13.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.15, "amp": 0.35, "attack": 0.02, "decay": 0.06, "lp0": 1500.0, "lp1": 6000.0},
			{"wave": "sine", "f0": 1900.0, "start": 0.12, "dur": 0.07, "amp": 0.1, "decay": 0.025},
			{"wave": "sine", "f0": 2300.0, "start": 0.2, "dur": 0.07, "amp": 0.09, "decay": 0.025},
			{"wave": "sine", "f0": 1700.0, "start": 0.28, "dur": 0.07, "amp": 0.08, "decay": 0.025},
			{"wave": "sine", "f0": 2100.0, "start": 0.36, "dur": 0.07, "amp": 0.07, "decay": 0.025},
			{"wave": "noise", "start": 0.12, "dur": 0.6, "amp": 0.12, "attack": 0.01, "decay": 0.2, "lp0": 4000.0, "lp1": 1800.0}]},
	# A Pit Cultist's rite: a low muttered chant swelling into a dissonant hum.
	"cultist_chant": {"dur": 1.4, "volume_db": -17.0, "max_voices": 2, "min_interval": 500, "pitch_var": 0.05, "priority": 1,
		"layers": [
			{"wave": "tri", "f0": 110.0, "dur": 1.3, "amp": 0.2, "attack": 0.4, "decay": 0.5, "vib_hz": 3.0, "vib_depth": 0.02},
			{"wave": "tri", "f0": 155.6, "dur": 1.3, "amp": 0.14, "attack": 0.5, "decay": 0.5, "vib_hz": 3.4, "vib_depth": 0.02},
			{"wave": "noise", "dur": 1.2, "amp": 0.08, "attack": 0.4, "decay": 0.4, "lp0": 500.0, "lp1": 900.0}]},
	# --- Act VI: the Palace of Silk and Ash --- (appended: the pack's seeds follow this order)
	# A reflection steps out of a mirror: a glassy shimmer, three falling chimes.
	"mirror_lure": {"dur": 0.9, "volume_db": -16.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.4, "amp": 0.08, "attack": 0.05, "decay": 0.15, "lp0": 9000.0, "lp1": 6000.0},
			{"wave": "sine", "f0": 2637.0, "dur": 0.5, "amp": 0.1, "attack": 0.004, "decay": 0.18, "vib_hz": 6.0, "vib_depth": 0.006},
			{"wave": "sine", "f0": 2093.0, "start": 0.12, "dur": 0.5, "amp": 0.09, "attack": 0.004, "decay": 0.18, "vib_hz": 6.0, "vib_depth": 0.006},
			{"wave": "sine", "f0": 1661.0, "start": 0.24, "dur": 0.6, "amp": 0.08, "attack": 0.004, "decay": 0.22, "vib_hz": 6.0, "vib_depth": 0.006}]},
	# Lilith's charm wave lands: a deep breathy swell under a ring of pink chimes.
	"lilith_wave": {"dur": 1.3, "volume_db": -10.0, "max_voices": 1, "min_interval": 400, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 110.0, "f1": 82.0, "dur": 1.1, "amp": 0.45, "attack": 0.08, "decay": 0.4},
			{"wave": "noise", "dur": 0.9, "amp": 0.18, "attack": 0.1, "decay": 0.35, "lp0": 1800.0, "lp1": 600.0},
			{"wave": "sine", "f0": 1319.0, "start": 0.1, "dur": 0.8, "amp": 0.08, "attack": 0.004, "decay": 0.3, "vib_hz": 5.0, "vib_depth": 0.008},
			{"wave": "sine", "f0": 1760.0, "start": 0.2, "dur": 0.8, "amp": 0.07, "attack": 0.004, "decay": 0.3, "vib_hz": 5.0, "vib_depth": 0.008},
			{"wave": "sine", "f0": 2217.0, "start": 0.3, "dur": 0.8, "amp": 0.06, "attack": 0.004, "decay": 0.3, "vib_hz": 5.0, "vib_depth": 0.008}]},
	# A twin's rage: a falling shriek over a growl.
	"twin_rage": {"dur": 1.0, "volume_db": -11.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 980.0, "f1": 420.0, "dur": 0.7, "amp": 0.16, "attack": 0.01, "decay": 0.25, "lp0": 4000.0, "lp1": 1800.0},
			{"wave": "square", "f0": 90.0, "f1": 70.0, "dur": 0.8, "amp": 0.18, "attack": 0.02, "decay": 0.3, "lp0": 600.0},
			{"wave": "noise", "dur": 0.6, "amp": 0.15, "attack": 0.01, "decay": 0.2, "lp0": 3000.0, "lp1": 900.0}]},
}

## Act VII sound effects (the Sanguine Court; recipe keys as SOUNDS). Kept OUT of SOUNDS
## like the other packs: Sfx renders it lazily the first time an Act VII run's music
## ("sanguine") is asked for (Sfx.prepare_pack("court"); seeds Sfx.PACK_SEED +
## Sfx.PACK_SEED_OFFSETS["court"] + i). Nothing plays them until the lead wires the
## foundation's sound map.
const COURT_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# A vampire feeds: a wet bite (a puncture click, a squelch) and a sip.
	"bite_feed": {"dur": 0.55, "volume_db": -15.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.03, "amp": 0.5, "attack": 0.001, "decay": 0.008, "lp0": 6000.0, "lp1": 2500.0},
			{"wave": "sine", "f0": 320.0, "f1": 120.0, "start": 0.02, "dur": 0.14, "amp": 0.3, "attack": 0.004, "decay": 0.05},
			{"wave": "noise", "start": 0.03, "dur": 0.12, "amp": 0.2, "attack": 0.01, "decay": 0.04, "lp0": 1400.0, "lp1": 500.0},
			{"wave": "sine", "f0": 260.0, "f1": 520.0, "start": 0.24, "dur": 0.1, "amp": 0.14, "attack": 0.01, "decay": 0.04},
			{"wave": "noise", "start": 0.26, "dur": 0.1, "amp": 0.14, "attack": 0.02, "decay": 0.04, "lp0": 2200.0, "lp1": 900.0}]},
	# A blood shield rises: a dark shimmer, a low swell under falling glass partials.
	"blood_shield": {"dur": 1.0, "volume_db": -14.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 90.0, "f1": 140.0, "dur": 0.9, "amp": 0.3, "attack": 0.25, "decay": 0.4},
			{"wave": "tri", "f0": 440.0, "dur": 0.9, "amp": 0.1, "attack": 0.2, "decay": 0.5, "vib_hz": 7.0, "vib_depth": 0.012},
			{"wave": "tri", "f0": 523.0, "dur": 0.9, "amp": 0.08, "attack": 0.25, "decay": 0.5, "vib_hz": 6.0, "vib_depth": 0.012},
			{"wave": "sine", "f0": 1760.0, "f1": 1320.0, "start": 0.1, "dur": 0.8, "amp": 0.05, "attack": 0.1, "decay": 0.4, "vib_hz": 9.0, "vib_depth": 0.01},
			{"wave": "noise", "dur": 0.8, "amp": 0.06, "attack": 0.2, "decay": 0.4, "lp0": 5000.0, "lp1": 2500.0}]},
	# A bat's cry: a high chittering screech, four quick falling squeaks.
	"bat_screech": {"dur": 0.5, "volume_db": -19.0, "max_voices": 4, "min_interval": 110, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 3600.0, "f1": 2400.0, "dur": 0.07, "amp": 0.12, "attack": 0.003, "decay": 0.03},
			{"wave": "sine", "f0": 3900.0, "f1": 2600.0, "start": 0.09, "dur": 0.07, "amp": 0.12, "attack": 0.003, "decay": 0.03},
			{"wave": "sine", "f0": 4200.0, "f1": 2800.0, "start": 0.18, "dur": 0.07, "amp": 0.11, "attack": 0.003, "decay": 0.03},
			{"wave": "sine", "f0": 3500.0, "f1": 2000.0, "start": 0.27, "dur": 0.14, "amp": 0.11, "attack": 0.003, "decay": 0.06},
			{"wave": "noise", "dur": 0.4, "amp": 0.04, "attack": 0.01, "decay": 0.15, "lp0": 8000.0, "lp1": 5000.0}]},
	# The Blood Moon rises: a low swell and a distant howl above it.
	"moon_rise": {"dur": 2.4, "volume_db": -11.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.02, "priority": 3,
		"layers": [
			{"wave": "sine", "f0": 55.0, "f1": 82.0, "dur": 2.2, "amp": 0.5, "attack": 1.0, "decay": 0.9},
			{"wave": "noise", "dur": 2.2, "amp": 0.18, "attack": 1.0, "decay": 0.9, "lp0": 200.0, "lp1": 900.0},
			{"wave": "tri", "f0": 330.0, "f1": 520.0, "start": 0.9, "dur": 1.2, "amp": 0.08, "attack": 0.4, "decay": 0.6, "vib_hz": 5.5, "vib_depth": 0.02},
			{"wave": "tri", "f0": 520.0, "f1": 410.0, "start": 1.9, "dur": 0.5, "amp": 0.06, "attack": 0.05, "decay": 0.25, "vib_hz": 5.5, "vib_depth": 0.02}]},
	# The Blood Moon sets: a fading minor chord, a bell-like tail.
	"moon_set": {"dur": 2.2, "volume_db": -14.0, "max_voices": 1, "min_interval": 1000, "pitch_var": 0.02, "priority": 3,
		"layers": [
			{"wave": "tri", "f0": 220.0, "dur": 2.1, "amp": 0.14, "attack": 0.05, "decay": 1.4},
			{"wave": "tri", "f0": 261.6, "dur": 2.1, "amp": 0.12, "attack": 0.05, "decay": 1.4},
			{"wave": "tri", "f0": 329.6, "dur": 2.1, "amp": 0.1, "attack": 0.05, "decay": 1.4},
			{"wave": "sine", "f0": 110.0, "f1": 90.0, "dur": 2.1, "amp": 0.25, "attack": 0.03, "decay": 1.2},
			{"wave": "sine", "f0": 880.0, "dur": 1.6, "amp": 0.04, "attack": 0.01, "decay": 0.9}]},
	# A werewolf's howl: a long rising-then-falling cry with a rasp of breath.
	"wolf_howl": {"dur": 2.0, "volume_db": -12.0, "max_voices": 2, "min_interval": 500, "pitch_var": 0.06, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 200.0, "f1": 420.0, "dur": 0.9, "amp": 0.16, "attack": 0.25, "decay": 0.3, "lp0": 1400.0, "lp1": 1800.0, "vib_hz": 5.0, "vib_depth": 0.02},
			{"wave": "saw", "f0": 420.0, "f1": 230.0, "start": 0.9, "dur": 1.0, "amp": 0.16, "attack": 0.02, "decay": 0.6, "lp0": 1800.0, "lp1": 900.0, "vib_hz": 5.5, "vib_depth": 0.025},
			{"wave": "sine", "f0": 400.0, "f1": 840.0, "dur": 0.9, "amp": 0.06, "attack": 0.25, "decay": 0.3},
			{"wave": "noise", "dur": 1.9, "amp": 0.07, "attack": 0.3, "decay": 0.7, "lp0": 1500.0, "lp1": 800.0}]},
	# A coffin lid groans open: wood creaking, a low scrape and a hollow thud.
	"coffin_creak": {"dur": 1.3, "volume_db": -13.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.07, "priority": 2,
		"layers": [
			{"wave": "saw", "f0": 140.0, "f1": 210.0, "dur": 0.5, "amp": 0.12, "attack": 0.05, "decay": 0.2, "lp0": 700.0, "lp1": 1200.0, "vib_hz": 23.0, "vib_depth": 0.08},
			{"wave": "saw", "f0": 170.0, "f1": 120.0, "start": 0.5, "dur": 0.6, "amp": 0.11, "attack": 0.03, "decay": 0.25, "lp0": 900.0, "lp1": 500.0, "vib_hz": 17.0, "vib_depth": 0.09},
			{"wave": "noise", "dur": 1.0, "amp": 0.1, "attack": 0.1, "decay": 0.4, "lp0": 600.0, "lp1": 1600.0},
			{"wave": "sine", "f0": 80.0, "f1": 45.0, "start": 1.05, "dur": 0.22, "amp": 0.4, "attack": 0.002, "decay": 0.08}]},
	# A noble turns to mist: a breathy whoosh that rises and thins.
	"mist_form": {"dur": 1.1, "volume_db": -15.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 1.0, "amp": 0.4, "attack": 0.25, "decay": 0.5, "lp0": 600.0, "lp1": 4500.0},
			{"wave": "noise", "start": 0.1, "dur": 0.9, "amp": 0.15, "attack": 0.3, "decay": 0.4, "lp0": 3000.0, "lp1": 7000.0},
			{"wave": "sine", "f0": 180.0, "f1": 360.0, "dur": 0.9, "amp": 0.08, "attack": 0.3, "decay": 0.4}]},
	# --- Act VII: Ravensmoor --- (appended at the END: the pack's seeds follow its order)
	# A ghoul sets to eating: wet tearing and a crunch of bone, twice.
	"ghoul_feed": {"dur": 0.7, "volume_db": -17.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.18, "amp": 0.3, "attack": 0.01, "decay": 0.08, "lp0": 1200.0, "lp1": 500.0},
			{"wave": "noise", "start": 0.06, "dur": 0.06, "amp": 0.35, "attack": 0.002, "decay": 0.02, "lp0": 4000.0, "lp1": 2500.0},
			{"wave": "noise", "start": 0.32, "dur": 0.2, "amp": 0.26, "attack": 0.01, "decay": 0.09, "lp0": 1000.0, "lp1": 450.0},
			{"wave": "noise", "start": 0.4, "dur": 0.05, "amp": 0.3, "attack": 0.002, "decay": 0.02, "lp0": 3500.0, "lp1": 2200.0},
			{"wave": "sine", "f0": 120.0, "f1": 70.0, "dur": 0.15, "amp": 0.15, "decay": 0.06}]},
	# Vargr roars as he calls his moon: a deep snarling roar under a rising howl.
	"vargr_roar": {"dur": 1.8, "volume_db": -10.0, "max_voices": 1, "min_interval": 800, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 95.0, "f1": 70.0, "dur": 1.0, "amp": 0.26, "attack": 0.05, "decay": 0.4, "lp0": 700.0, "lp1": 350.0, "vib_hz": 19.0, "vib_depth": 0.06},
			{"wave": "noise", "dur": 1.0, "amp": 0.22, "attack": 0.05, "decay": 0.4, "lp0": 900.0, "lp1": 400.0},
			{"wave": "saw", "f0": 180.0, "f1": 380.0, "start": 0.7, "dur": 1.0, "amp": 0.12, "attack": 0.2, "decay": 0.5, "lp0": 1300.0, "lp1": 1700.0, "vib_hz": 5.0, "vib_depth": 0.02},
			{"wave": "sine", "f0": 55.0, "f1": 42.0, "dur": 1.2, "amp": 0.4, "attack": 0.04, "decay": 0.5}]},
	# --- Act VII: the Witchwood --- (appended at the END: the pack's seeds follow its order)
	# A coven's circle bites: three low voices chanting a minor third under a breathy hiss.
	"hex_chant": {"dur": 1.6, "volume_db": -16.0, "max_voices": 2, "min_interval": 600, "pitch_var": 0.04, "priority": 2,
		"layers": [
			{"wave": "tri", "f0": 146.8, "dur": 1.5, "amp": 0.18, "attack": 0.35, "decay": 0.6, "vib_hz": 4.0, "vib_depth": 0.02},
			{"wave": "tri", "f0": 174.6, "dur": 1.5, "amp": 0.14, "attack": 0.4, "decay": 0.6, "vib_hz": 4.4, "vib_depth": 0.02},
			{"wave": "tri", "f0": 220.0, "dur": 1.4, "amp": 0.1, "attack": 0.45, "decay": 0.55, "vib_hz": 3.6, "vib_depth": 0.025},
			{"wave": "noise", "dur": 1.4, "amp": 0.06, "attack": 0.4, "decay": 0.5, "lp0": 2500.0, "lp1": 900.0}]},
	# A Bloated Thrall bursts (or a cauldron bomb lands): a wet pop and a splatter.
	"blood_burst": {"dur": 0.7, "volume_db": -12.0, "max_voices": 3, "min_interval": 150, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 160.0, "f1": 60.0, "dur": 0.18, "amp": 0.45, "attack": 0.002, "decay": 0.08},
			{"wave": "noise", "dur": 0.12, "amp": 0.5, "attack": 0.001, "decay": 0.05, "lp0": 3000.0, "lp1": 800.0},
			{"wave": "noise", "start": 0.08, "dur": 0.55, "amp": 0.18, "attack": 0.01, "decay": 0.25, "lp0": 1800.0, "lp1": 500.0}]},
	# The Bog Mother's ropes: a gurgling drag of water and a low groan.
	"bog_drag": {"dur": 1.3, "volume_db": -12.0, "max_voices": 1, "min_interval": 500, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 98.0, "f1": 70.0, "dur": 1.1, "amp": 0.18, "attack": 0.1, "decay": 0.5, "lp0": 500.0, "lp1": 260.0, "vib_hz": 5.0, "vib_depth": 0.04},
			{"wave": "noise", "dur": 1.2, "amp": 0.22, "attack": 0.15, "decay": 0.5, "lp0": 700.0, "lp1": 300.0},
			{"wave": "sine", "f0": 300.0, "f1": 180.0, "start": 0.2, "dur": 0.15, "amp": 0.08, "decay": 0.06},
			{"wave": "sine", "f0": 260.0, "f1": 160.0, "start": 0.55, "dur": 0.15, "amp": 0.07, "decay": 0.06}]},
	# Isolde's cackle: a rising, wavering laugh over a hiss.
	"isolde_cackle": {"dur": 1.4, "volume_db": -12.0, "max_voices": 1, "min_interval": 900, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 520.0, "f1": 760.0, "dur": 0.3, "amp": 0.1, "attack": 0.02, "decay": 0.12, "lp0": 2400.0, "lp1": 3200.0, "vib_hz": 11.0, "vib_depth": 0.06},
			{"wave": "saw", "f0": 600.0, "f1": 820.0, "start": 0.32, "dur": 0.3, "amp": 0.09, "attack": 0.02, "decay": 0.12, "lp0": 2400.0, "lp1": 3200.0, "vib_hz": 12.0, "vib_depth": 0.06},
			{"wave": "saw", "f0": 680.0, "f1": 900.0, "start": 0.64, "dur": 0.5, "amp": 0.08, "attack": 0.02, "decay": 0.25, "lp0": 2400.0, "lp1": 3400.0, "vib_hz": 13.0, "vib_depth": 0.07},
			{"wave": "noise", "dur": 1.2, "amp": 0.05, "attack": 0.1, "decay": 0.5, "lp0": 4000.0, "lp1": 2000.0}]},
	# A hex stone breaks: a stony crack and a dying hum.
	"stone_break": {"dur": 1.0, "volume_db": -12.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.06, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.2, "amp": 0.55, "attack": 0.001, "decay": 0.07, "lp0": 4000.0, "lp1": 900.0},
			{"wave": "sine", "f0": 110.0, "f1": 55.0, "dur": 0.3, "amp": 0.35, "attack": 0.002, "decay": 0.12},
			{"wave": "tri", "f0": 220.0, "f1": 110.0, "start": 0.1, "dur": 0.8, "amp": 0.08, "attack": 0.02, "decay": 0.4}]},
}

# --- Act VIII: the Last Line ---
## Act VIII sound effects (the city; recipe keys as SOUNDS). Kept OUT of SOUNDS like the other
## packs: Sfx renders it lazily the first time an Act VIII run's music ("siren") is asked for
## (Sfx.prepare_pack("city"); seeds Sfx.PACK_SEED + Sfx.PACK_SEED_OFFSETS["city"] + i).
## Nothing plays them until the lead wires the foundation's sound map.
const CITY_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# A distant siren: one slow rise and fall, soft and never shrill.
	"siren_wail": {"dur": 2.8, "volume_db": -18.0, "max_voices": 1, "min_interval": 1500, "pitch_var": 0.03, "priority": 1,
		"layers": [
			{"wave": "tri", "f0": 600.0, "f1": 860.0, "dur": 1.5, "amp": 0.14, "attack": 0.5, "decay": 1.6, "lp0": 1300.0},
			{"wave": "tri", "f0": 860.0, "f1": 600.0, "start": 1.3, "dur": 1.5, "amp": 0.14, "attack": 0.3, "decay": 0.9, "lp0": 1300.0},
			{"wave": "tri", "f0": 603.0, "f1": 866.0, "dur": 1.5, "amp": 0.06, "attack": 0.5, "decay": 1.6, "lp0": 1000.0},
			{"wave": "noise", "dur": 2.6, "amp": 0.03, "attack": 0.6, "decay": 1.0, "lp0": 700.0}]},
	# A short dry burst: five pistol cracks with a low thump each.
	"gun_burst": {"dur": 0.55, "volume_db": -20.0, "max_voices": 3, "min_interval": 90, "pitch_var": 0.07, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.04, "amp": 0.5, "attack": 0.001, "decay": 0.01, "lp0": 6500.0, "lp1": 2500.0},
			{"wave": "noise", "start": 0.08, "dur": 0.04, "amp": 0.46, "attack": 0.001, "decay": 0.01, "lp0": 6500.0, "lp1": 2500.0},
			{"wave": "noise", "start": 0.16, "dur": 0.04, "amp": 0.5, "attack": 0.001, "decay": 0.01, "lp0": 6500.0, "lp1": 2500.0},
			{"wave": "noise", "start": 0.25, "dur": 0.04, "amp": 0.44, "attack": 0.001, "decay": 0.01, "lp0": 6500.0, "lp1": 2500.0},
			{"wave": "noise", "start": 0.32, "dur": 0.04, "amp": 0.4, "attack": 0.001, "decay": 0.01, "lp0": 6500.0, "lp1": 2500.0},
			{"wave": "sine", "f0": 150.0, "f1": 70.0, "dur": 0.1, "amp": 0.25, "attack": 0.002, "decay": 0.04},
			{"wave": "sine", "f0": 150.0, "f1": 70.0, "start": 0.16, "dur": 0.1, "amp": 0.22, "attack": 0.002, "decay": 0.04},
			{"wave": "sine", "f0": 140.0, "f1": 65.0, "start": 0.32, "dur": 0.1, "amp": 0.2, "attack": 0.002, "decay": 0.04},
			{"wave": "noise", "start": 0.33, "dur": 0.2, "amp": 0.06, "attack": 0.01, "decay": 0.08, "lp0": 2000.0, "lp1": 700.0}]},
	# An engine revs up: a rising growl with a ragged throb.
	"engine_rev": {"dur": 1.3, "volume_db": -14.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "saw", "f0": 55.0, "f1": 150.0, "dur": 1.1, "amp": 0.2, "attack": 0.08, "decay": 0.5, "lp0": 450.0, "lp1": 1300.0, "vib_hz": 26.0, "vib_depth": 0.05},
			{"wave": "square", "f0": 110.0, "f1": 300.0, "dur": 1.1, "amp": 0.07, "attack": 0.1, "decay": 0.5, "lp0": 700.0, "lp1": 1500.0, "vib_hz": 21.0, "vib_depth": 0.04},
			{"wave": "noise", "dur": 1.2, "amp": 0.12, "attack": 0.1, "decay": 0.5, "lp0": 400.0, "lp1": 1600.0}]},
	# A vehicle wreck: a crunch of metal, then a fire whoomp.
	"vehicle_wreck": {"dur": 1.6, "volume_db": -11.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.3, "amp": 0.55, "attack": 0.001, "decay": 0.08, "lp0": 5500.0, "lp1": 800.0},
			{"wave": "sine", "f0": 310.0, "f1": 250.0, "dur": 0.4, "amp": 0.1, "attack": 0.002, "decay": 0.12},
			{"wave": "sine", "f0": 730.0, "f1": 640.0, "start": 0.03, "dur": 0.35, "amp": 0.07, "attack": 0.002, "decay": 0.1},
			{"wave": "sine", "f0": 1190.0, "f1": 1000.0, "start": 0.06, "dur": 0.3, "amp": 0.05, "attack": 0.002, "decay": 0.08},
			{"wave": "sine", "f0": 80.0, "f1": 36.0, "start": 0.15, "dur": 0.8, "amp": 0.5, "attack": 0.03, "decay": 0.35},
			{"wave": "noise", "start": 0.15, "dur": 1.3, "amp": 0.26, "attack": 0.06, "decay": 0.5, "lp0": 350.0, "lp1": 120.0}]},
	# A crowd cries out: several alarmed voices rising together over a gasp. Not graphic.
	"crowd_panic": {"dur": 1.1, "volume_db": -17.0, "max_voices": 2, "min_interval": 500, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "saw", "f0": 300.0, "f1": 470.0, "dur": 0.7, "amp": 0.07, "attack": 0.06, "decay": 0.3, "lp0": 1500.0, "lp1": 1900.0, "vib_hz": 6.0, "vib_depth": 0.03},
			{"wave": "saw", "f0": 360.0, "f1": 560.0, "start": 0.08, "dur": 0.7, "amp": 0.06, "attack": 0.06, "decay": 0.3, "lp0": 1700.0, "lp1": 2100.0, "vib_hz": 6.5, "vib_depth": 0.03},
			{"wave": "saw", "f0": 250.0, "f1": 400.0, "start": 0.15, "dur": 0.8, "amp": 0.06, "attack": 0.08, "decay": 0.35, "lp0": 1400.0, "lp1": 1800.0, "vib_hz": 5.5, "vib_depth": 0.035},
			{"wave": "tri", "f0": 520.0, "f1": 700.0, "start": 0.05, "dur": 0.6, "amp": 0.05, "attack": 0.05, "decay": 0.25, "vib_hz": 7.0, "vib_depth": 0.03},
			{"wave": "noise", "dur": 1.0, "amp": 0.07, "attack": 0.1, "decay": 0.4, "lp0": 3000.0, "lp1": 1500.0}]},
	# A Super arrives: a rising whoosh into a bright chord.
	"super_arrive": {"dur": 1.8, "volume_db": -12.0, "max_voices": 2, "min_interval": 500, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.85, "amp": 0.3, "attack": 0.6, "decay": 0.25, "lp0": 400.0, "lp1": 6500.0},
			{"wave": "sine", "f0": 180.0, "f1": 1100.0, "dur": 0.85, "amp": 0.14, "attack": 0.5, "decay": 0.3},
			{"wave": "tri", "f0": 523.25, "start": 0.8, "dur": 0.95, "amp": 0.12, "attack": 0.01, "decay": 0.6},
			{"wave": "tri", "f0": 659.25, "start": 0.8, "dur": 0.95, "amp": 0.1, "attack": 0.01, "decay": 0.6},
			{"wave": "tri", "f0": 783.99, "start": 0.8, "dur": 0.95, "amp": 0.09, "attack": 0.01, "decay": 0.6},
			{"wave": "sine", "f0": 1568.0, "start": 0.82, "dur": 0.9, "amp": 0.04, "attack": 0.005, "decay": 0.5},
			{"wave": "sine", "f0": 65.4, "start": 0.8, "dur": 0.9, "amp": 0.25, "attack": 0.01, "decay": 0.5}]},
	# A Super's weak point breaks: a glassy crack and a tinkle.
	"weakness_crack": {"dur": 0.7, "volume_db": -13.0, "max_voices": 2, "min_interval": 150, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.06, "amp": 0.5, "attack": 0.001, "decay": 0.015, "lp0": 9000.0, "lp1": 4000.0},
			{"wave": "sine", "f0": 2400.0, "f1": 2100.0, "start": 0.01, "dur": 0.3, "amp": 0.14, "attack": 0.001, "decay": 0.09},
			{"wave": "sine", "f0": 3100.0, "f1": 2800.0, "start": 0.02, "dur": 0.3, "amp": 0.1, "attack": 0.001, "decay": 0.08},
			{"wave": "sine", "f0": 4700.0, "start": 0.03, "dur": 0.4, "amp": 0.06, "attack": 0.001, "decay": 0.12},
			{"wave": "sine", "f0": 5300.0, "start": 0.12, "dur": 0.4, "amp": 0.04, "attack": 0.001, "decay": 0.14},
			{"wave": "sine", "f0": 160.0, "f1": 80.0, "dur": 0.12, "amp": 0.2, "attack": 0.002, "decay": 0.05}]},
	# A new tier arrives: a radio squelch, then a low two-tone klaxon.
	"tier_alarm": {"dur": 1.5, "volume_db": -12.0, "max_voices": 1, "min_interval": 1200, "pitch_var": 0.02, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.14, "amp": 0.3, "attack": 0.005, "decay": 0.05, "lp0": 3800.0, "lp1": 2200.0},
			{"wave": "square", "f0": 1900.0, "f1": 1300.0, "start": 0.02, "dur": 0.1, "amp": 0.05, "attack": 0.003, "decay": 0.04, "lp0": 3000.0},
			{"wave": "saw", "f0": 110.0, "start": 0.18, "dur": 0.55, "amp": 0.22, "attack": 0.02, "decay": 0.35, "lp0": 800.0, "lp1": 600.0},
			{"wave": "saw", "f0": 82.4, "start": 0.72, "dur": 0.7, "amp": 0.22, "attack": 0.02, "decay": 0.4, "lp0": 800.0, "lp1": 500.0},
			{"wave": "sine", "f0": 55.0, "start": 0.18, "dur": 1.2, "amp": 0.25, "attack": 0.05, "decay": 0.6}]},
	# --- Act VIII: Skid Row --- (appended at the END: the pack's seeds follow its order)
	# Don Marrow's gold minigun: a rising whir and a long, dense rattle of shots.
	"minigun": {"dur": 1.4, "volume_db": -13.0, "max_voices": 1, "min_interval": 600, "pitch_var": 0.03, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 60.0, "f1": 140.0, "dur": 0.4, "amp": 0.12, "attack": 0.05, "decay": 0.2, "lp0": 900.0, "lp1": 1400.0},
			{"wave": "square", "f0": 28.0, "start": 0.25, "dur": 1.1, "amp": 0.18, "attack": 0.01, "decay": 0.3, "lp0": 2600.0, "lp1": 1800.0},
			{"wave": "noise", "start": 0.25, "dur": 1.1, "amp": 0.3, "attack": 0.01, "decay": 0.35, "lp0": 4200.0, "lp1": 2400.0},
			{"wave": "sine", "f0": 90.0, "f1": 70.0, "start": 0.25, "dur": 1.0, "amp": 0.2, "attack": 0.02, "decay": 0.4}]},
	# A riot cop's tear-gas canister lands: a clunk and a long soft hiss.
	"gas_hiss": {"dur": 1.1, "volume_db": -19.0, "max_voices": 2, "min_interval": 500, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.35, "attack": 0.002, "decay": 0.02, "lp0": 1800.0, "lp1": 900.0},
			{"wave": "sine", "f0": 220.0, "f1": 160.0, "dur": 0.08, "amp": 0.14, "attack": 0.002, "decay": 0.04},
			{"wave": "noise", "start": 0.06, "dur": 1.0, "amp": 0.22, "attack": 0.08, "decay": 0.6, "lp0": 7000.0, "lp1": 4000.0}]},
}

# --- Act IX: the Concord of Stars ---
## Act IX sound effects (the Concord; recipe keys as SOUNDS). Kept OUT of SOUNDS like the other
## packs: Sfx renders it lazily the first time an Act IX run's music ("starsong") is asked for
## (Sfx.prepare_pack("concord"); seeds Sfx.PACK_SEED + Sfx.PACK_SEED_OFFSETS["concord"] + i).
## Nothing plays them until the lead wires the foundation's sound map.
const CONCORD_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# The aiming line: a thin, rising whine with a faint beating twin.
	"beam_charge": {"dur": 1.0, "volume_db": -18.0, "max_voices": 3, "min_interval": 250, "pitch_var": 0.03, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 600.0, "f1": 2600.0, "dur": 0.95, "amp": 0.16, "attack": 0.75, "decay": 0.5},
			{"wave": "sine", "f0": 608.0, "f1": 2640.0, "dur": 0.95, "amp": 0.08, "attack": 0.75, "decay": 0.5},
			{"wave": "tri", "f0": 1200.0, "f1": 5000.0, "dur": 0.9, "amp": 0.03, "attack": 0.7, "decay": 0.4, "lp0": 5000.0},
			{"wave": "noise", "dur": 0.9, "amp": 0.02, "attack": 0.7, "decay": 0.3, "lp0": 3000.0, "lp1": 7000.0}]},
	# A held, buzzing laser tone that tapers and ends cleanly.
	"beam_fire": {"dur": 1.3, "volume_db": -16.0, "max_voices": 3, "min_interval": 200, "pitch_var": 0.03, "priority": 2,
		"layers": [
			{"wave": "saw", "f0": 220.0, "dur": 1.25, "amp": 0.14, "attack": 0.02, "decay": 3.0, "lp0": 2800.0, "vib_hz": 38.0, "vib_depth": 0.02},
			{"wave": "square", "f0": 440.0, "dur": 1.25, "amp": 0.04, "attack": 0.03, "decay": 3.0, "lp0": 2200.0},
			{"wave": "sine", "f0": 880.0, "dur": 1.25, "amp": 0.08, "attack": 0.02, "decay": 3.0},
			{"wave": "sine", "f0": 55.0, "dur": 1.25, "amp": 0.14, "attack": 0.03, "decay": 2.5}]},
	# A bright glassy ping, then a short reversed swell as its tail.
	"beam_reflect": {"dur": 0.7, "volume_db": -16.0, "max_voices": 4, "min_interval": 80, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 2600.0, "f1": 2500.0, "dur": 0.35, "amp": 0.2, "attack": 0.001, "decay": 0.1},
			{"wave": "sine", "f0": 3900.0, "start": 0.005, "dur": 0.3, "amp": 0.1, "attack": 0.001, "decay": 0.08},
			{"wave": "sine", "f0": 5200.0, "start": 0.01, "dur": 0.25, "amp": 0.05, "attack": 0.001, "decay": 0.06},
			{"wave": "sine", "f0": 3300.0, "f1": 4200.0, "start": 0.2, "dur": 0.3, "amp": 0.08, "attack": 0.26, "decay": 0.05},
			{"wave": "noise", "start": 0.2, "dur": 0.3, "amp": 0.03, "attack": 0.27, "decay": 0.04, "lp0": 6000.0, "lp1": 9000.0}]},
	# A low, wobbling hum.
	"tractor_beam": {"dur": 1.5, "volume_db": -17.0, "max_voices": 2, "min_interval": 400, "pitch_var": 0.03, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 92.0, "dur": 1.45, "amp": 0.3, "attack": 0.25, "decay": 2.5, "vib_hz": 6.0, "vib_depth": 0.07},
			{"wave": "saw", "f0": 92.5, "dur": 1.45, "amp": 0.1, "attack": 0.25, "decay": 2.5, "lp0": 320.0, "vib_hz": 5.0, "vib_depth": 0.08},
			{"wave": "sine", "f0": 184.0, "dur": 1.45, "amp": 0.07, "attack": 0.3, "decay": 2.5, "vib_hz": 6.5, "vib_depth": 0.06}]},
	# A summon is taken: a rising whoosh that thins out into a high whisper.
	"abduction": {"dur": 1.6, "volume_db": -13.0, "max_voices": 2, "min_interval": 300, "pitch_var": 0.04, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 1.2, "amp": 0.3, "attack": 0.55, "decay": 0.3, "lp0": 300.0, "lp1": 5500.0},
			{"wave": "sine", "f0": 200.0, "f1": 2200.0, "dur": 1.0, "amp": 0.14, "attack": 0.7, "decay": 0.3},
			{"wave": "sine", "f0": 2200.0, "f1": 4200.0, "start": 0.9, "dur": 0.65, "amp": 0.05, "attack": 0.05, "decay": 0.2},
			{"wave": "tri", "f0": 90.0, "f1": 60.0, "dur": 0.8, "amp": 0.14, "attack": 0.2, "decay": 0.4, "lp0": 400.0}]},
	# A saucer is shot down: electric sputters, a falling whine, then a crash.
	"saucer_down": {"dur": 1.4, "volume_db": -11.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "noise", "dur": 0.06, "amp": 0.3, "attack": 0.001, "decay": 0.02, "lp0": 7000.0, "lp1": 3000.0},
			{"wave": "noise", "start": 0.1, "dur": 0.05, "amp": 0.26, "attack": 0.001, "decay": 0.015, "lp0": 7000.0, "lp1": 3000.0},
			{"wave": "noise", "start": 0.19, "dur": 0.07, "amp": 0.32, "attack": 0.001, "decay": 0.02, "lp0": 7000.0, "lp1": 3000.0},
			{"wave": "noise", "start": 0.33, "dur": 0.05, "amp": 0.24, "attack": 0.001, "decay": 0.015, "lp0": 7000.0, "lp1": 3000.0},
			{"wave": "saw", "f0": 420.0, "f1": 60.0, "dur": 0.9, "amp": 0.18, "attack": 0.01, "decay": 0.4, "lp0": 2500.0, "lp1": 500.0, "vib_hz": 30.0, "vib_depth": 0.15},
			{"wave": "noise", "start": 0.55, "dur": 0.8, "amp": 0.4, "attack": 0.004, "decay": 0.25, "lp0": 3500.0, "lp1": 250.0},
			{"wave": "sine", "f0": 80.0, "f1": 32.0, "start": 0.55, "dur": 0.7, "amp": 0.4, "attack": 0.005, "decay": 0.3}]},
	# Spell fire burning alien ground: a soft sizzle and hiss with a few crackles.
	"ground_burn": {"dur": 1.0, "volume_db": -21.0, "max_voices": 3, "min_interval": 180, "pitch_var": 0.08, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.95, "amp": 0.12, "attack": 0.05, "decay": 0.4, "lp0": 7500.0, "lp1": 4000.0},
			{"wave": "noise", "start": 0.08, "dur": 0.012, "amp": 0.14, "attack": 0.001, "decay": 0.004, "lp0": 9000.0},
			{"wave": "noise", "start": 0.26, "dur": 0.012, "amp": 0.12, "attack": 0.001, "decay": 0.004, "lp0": 9000.0},
			{"wave": "noise", "start": 0.41, "dur": 0.012, "amp": 0.14, "attack": 0.001, "decay": 0.004, "lp0": 9000.0},
			{"wave": "noise", "start": 0.6, "dur": 0.012, "amp": 0.1, "attack": 0.001, "decay": 0.004, "lp0": 9000.0},
			{"wave": "sine", "f0": 130.0, "f1": 80.0, "dur": 0.5, "amp": 0.04, "attack": 0.1, "decay": 0.25}]},
	# Insects: a short, uneven clicking, quiet.
	"brood_chitter": {"dur": 0.45, "volume_db": -22.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.12, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.012, "amp": 0.4, "attack": 0.001, "decay": 0.004, "lp0": 6500.0, "lp1": 3500.0},
			{"wave": "noise", "start": 0.05, "dur": 0.012, "amp": 0.32, "attack": 0.001, "decay": 0.004, "lp0": 7000.0, "lp1": 3500.0},
			{"wave": "noise", "start": 0.09, "dur": 0.012, "amp": 0.38, "attack": 0.001, "decay": 0.004, "lp0": 6000.0, "lp1": 3000.0},
			{"wave": "noise", "start": 0.17, "dur": 0.012, "amp": 0.3, "attack": 0.001, "decay": 0.004, "lp0": 7000.0, "lp1": 3500.0},
			{"wave": "noise", "start": 0.21, "dur": 0.012, "amp": 0.36, "attack": 0.001, "decay": 0.004, "lp0": 6500.0, "lp1": 3000.0},
			{"wave": "noise", "start": 0.3, "dur": 0.012, "amp": 0.28, "attack": 0.001, "decay": 0.004, "lp0": 7000.0, "lp1": 3500.0},
			{"wave": "sine", "f0": 3200.0, "f1": 3600.0, "start": 0.06, "dur": 0.03, "amp": 0.05, "attack": 0.002, "decay": 0.01},
			{"wave": "sine", "f0": 3000.0, "f1": 3400.0, "start": 0.22, "dur": 0.03, "amp": 0.04, "attack": 0.002, "decay": 0.01}]},
	# The Final Harvest: a deep opening groan and a low horn that blooms.
	"harvest_eye": {"dur": 3.6, "volume_db": -9.0, "max_voices": 1, "min_interval": 3000, "pitch_var": 0.02, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 40.0, "f1": 72.0, "dur": 2.8, "amp": 0.22, "attack": 1.2, "decay": 1.5, "lp0": 150.0, "lp1": 520.0, "vib_hz": 3.0, "vib_depth": 0.03},
			{"wave": "noise", "dur": 2.6, "amp": 0.14, "attack": 1.0, "decay": 1.2, "lp0": 200.0, "lp1": 650.0},
			{"wave": "sine", "f0": 36.7, "start": 0.2, "dur": 3.0, "amp": 0.34, "attack": 0.7, "decay": 1.6},
			{"wave": "saw", "f0": 73.42, "start": 0.9, "dur": 2.6, "amp": 0.2, "attack": 0.9, "decay": 1.2, "lp0": 350.0, "lp1": 1200.0, "vib_hz": 4.5, "vib_depth": 0.004},
			{"wave": "saw", "f0": 110.0, "start": 1.0, "dur": 2.5, "amp": 0.11, "attack": 0.9, "decay": 1.2, "lp0": 350.0, "lp1": 1100.0, "vib_hz": 4.5, "vib_depth": 0.004},
			{"wave": "sine", "f0": 220.0, "start": 1.2, "dur": 2.3, "amp": 0.05, "attack": 0.8, "decay": 1.1}]},
	# --- Act IX: the Crash Site --- (appended at the END: the pack's seeds follow its order)
	# A Burrower's mound heaves and bursts: a low earthy rumble and a crack of dirt.
	"burrow_rumble": {"dur": 0.9, "volume_db": -15.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.7, "amp": 0.3, "attack": 0.15, "decay": 0.35, "lp0": 260.0, "lp1": 180.0},
			{"wave": "sine", "f0": 55.0, "f1": 38.0, "dur": 0.8, "amp": 0.3, "attack": 0.1, "decay": 0.4},
			{"wave": "noise", "start": 0.55, "dur": 0.08, "amp": 0.35, "attack": 0.002, "decay": 0.05, "lp0": 2400.0, "lp1": 900.0}]},
	# An Acid Spitter's lob: a wet hork, then a sizzling splash.
	"acid_spit": {"dur": 0.7, "volume_db": -18.0, "max_voices": 3, "min_interval": 150, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.08, "amp": 0.3, "attack": 0.005, "decay": 0.05, "lp0": 1400.0, "lp1": 700.0},
			{"wave": "sine", "f0": 320.0, "f1": 180.0, "dur": 0.1, "amp": 0.12, "attack": 0.005, "decay": 0.06},
			{"wave": "noise", "start": 0.1, "dur": 0.55, "amp": 0.16, "attack": 0.03, "decay": 0.35, "lp0": 8000.0, "lp1": 4500.0}]},
	# An Infestation egg breaks open: a soft wet crack and a short chitter.
	"egg_hatch": {"dur": 0.5, "volume_db": -19.0, "max_voices": 2, "min_interval": 200, "pitch_var": 0.12, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.05, "amp": 0.35, "attack": 0.002, "decay": 0.03, "lp0": 3000.0, "lp1": 1200.0},
			{"wave": "sine", "f0": 520.0, "f1": 380.0, "dur": 0.06, "amp": 0.1, "attack": 0.003, "decay": 0.04},
			{"wave": "noise", "start": 0.12, "dur": 0.012, "amp": 0.3, "attack": 0.001, "decay": 0.004, "lp0": 6500.0},
			{"wave": "noise", "start": 0.18, "dur": 0.012, "amp": 0.26, "attack": 0.001, "decay": 0.004, "lp0": 7000.0},
			{"wave": "noise", "start": 0.25, "dur": 0.012, "amp": 0.24, "attack": 0.001, "decay": 0.004, "lp0": 6500.0}]},
	# The Hive Mother's (and the Matriarch's) rasping shriek: a gliding buzz over a low growl.
	"hive_scream": {"dur": 1.4, "volume_db": -12.0, "max_voices": 1, "min_interval": 900, "pitch_var": 0.05, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 420.0, "f1": 260.0, "dur": 1.2, "amp": 0.16, "attack": 0.08, "decay": 0.6, "lp0": 2600.0, "lp1": 1400.0, "vib_hz": 22.0, "vib_depth": 0.04},
			{"wave": "square", "f0": 210.0, "f1": 130.0, "dur": 1.1, "amp": 0.08, "attack": 0.1, "decay": 0.6, "lp0": 1600.0, "lp1": 900.0, "vib_hz": 18.0, "vib_depth": 0.05},
			{"wave": "noise", "dur": 1.2, "amp": 0.12, "attack": 0.1, "decay": 0.6, "lp0": 3000.0, "lp1": 1500.0},
			{"wave": "sine", "f0": 70.0, "f1": 50.0, "dur": 1.3, "amp": 0.22, "attack": 0.1, "decay": 0.7}]},
}


# --- the Necropolis Dynasty (Act VII slot; stage key dynasty) ---
## "The Weighing of the Heart", the Dynasty's run loop (GDD §15.0 "The Necropolis Dynasty art and audio"): the
## RunLoopSynth score of every stage whose STAGE has "music": "weighing". Frame drums, a reed drone and a
## mournful modal melody in G Hijaz (G Ab B C D Eb F#), 24 s: eight 3 s bars of eight steps (0.375 s), four 6 s
## chord segments (G5, Ab over Eb, G with F#, C5). The frame drums are the existing "machine" job in the
## maqsum pattern (dum on 0 and 4, tek on 2, 3 and 6, a faint finger-cymbal tick on every step, in place of the
## heartbeat); the reed drone is the existing "organ" job on odd partials (a reedy hum on a low G) over a very
## deep drone; the melody is the existing "flute" job (a breathy ney with a wide vibrato); a sparse sistrum
## shimmer is the existing "hits" job; a low "horn" swell blooms twice a loop (the Reckoning's colour: the
## Devourer's Hour). Never shrill: everything above 1 kHz is a sine or low-passed. Rendered lazily (Sfx), never
## under the autotest; its fixed seed is Sfx.SCORE_SEEDS["weighing"].
const WEIGHING_SCORE := {
	"loop_seconds": 24.0,  # TUNING (not in GDD) eight bars of 3 s
	"root_hz": 49.0,  # TUNING (not in GDD) G1, a very low desert hum under G
	"chords": [
		[98.0, 146.83, 196.0],
		[103.83, 155.56, 196.0],
		[98.0, 146.83, 185.0],
		[130.81, 196.0, 261.63],
	],  # TUNING (not in GDD) G5 (open), Ab over Eb, G with the F# leading tone, C5
	"drone_lp_hz": 70.0,  # TUNING (not in GDD) a soft, deep hum
	"wind_lp_hz": 420.0,  # TUNING (not in GDD) blown sand
	"wind_swells": 3.0,  # TUNING (not in GDD)
	"vibrato_hz": 0.3,  # TUNING (not in GDD)
	"vibrato_depth": 0.002,  # TUNING (not in GDD)
	# Frame drums in the maqsum: 8 steps of 0.375 s a bar (dum, tek, tek / dum, tek), a faint finger-cymbal tick on each step.
	"machine": {"step": 0.375, "steps_per_bar": 8, "kick_steps": [0, 4], "snare_steps": [2, 3, 6],
		"hat_steps": [0, 1, 2, 3, 4, 5, 6], "open_hat_steps": [7], "kick_amp": 0.38, "snare_amp": 0.1,
		"hat_amp": 0.022, "open_hat_amp": 0.035, "kick_hz0": 150.0, "kick_hz1": 72.0, "kick_dur": 0.28,
		"snare_dur": 0.12, "hat_dur": 0.04, "open_hat_dur": 0.2},  # TUNING (not in GDD)
	# The reed drone: a low G on odd partials (a reedy hum), swelling in over a second, re-struck each segment.
	"organ": {"attack": 1.0, "decay": 3.0, "vib_hz": 5.0, "vib_depth": 0.002,
		"partials": [[1.0, 0.05], [3.0, 0.035], [5.0, 0.022], [7.0, 0.012]],
		"notes": [[0.0, 98.0, 5.9], [6.0, 103.83, 5.9], [12.0, 98.0, 5.9], [18.0, 130.81, 5.8]]},  # TUNING (not in GDD) [start (s), Hz, length (s)]
	# The mournful reed melody (G Hijaz): four phrases of six seconds, each answering the last.
	"flute": {"amp": 0.09, "breath": 0.06, "attack": 0.18, "decay": 1.1, "vib_hz": 5.2, "vib_depth": 0.014,
		"notes": [
			[0.4, 587.33, 1.6], [2.2, 523.25, 1.0], [3.4, 493.88, 0.9], [4.4, 415.3, 1.5],
			[6.4, 493.88, 1.4], [8.0, 523.25, 1.0], [9.2, 587.33, 2.2],
			[12.4, 622.25, 1.5], [14.0, 587.33, 1.0], [15.2, 493.88, 1.0], [16.4, 415.3, 1.4],
			[18.4, 392.0, 1.8], [20.4, 415.3, 0.9], [21.5, 493.88, 1.0], [22.6, 392.0, 1.0]]},  # TUNING (not in GDD) [start (s), Hz, length (s)]
	# A sistrum shimmer: a quiet, thin ping every 6 s, 3 s into each segment.
	"hits": {"every": 6.0, "offset": 3.0, "root_hz": 2400.0, "dur": 0.9, "decay": 0.3,
		"partials": [[1.0, 0.012], [1.51, 0.008], [2.3, 0.005]], "click": 0.008},  # TUNING (not in GDD)
	# The Devourer's swell: a low G and D that bloom and fade twice a loop.
	"horn": {"starts": [0.5, 12.5], "dur": 5.6, "attack": 2.6, "decay": 2.4, "amp": 0.035,
		"lp0": 200.0, "lp1": 800.0,
		"notes": [[49.0, 73.42], [49.0, 73.42]]},  # TUNING (not in GDD)
}

## Necropolis Dynasty sound effects (recipe keys as SOUNDS). Kept OUT of SOUNDS like the other packs: Sfx renders
## it lazily the first time a Dynasty run's music ("weighing") is asked for (Sfx.prepare_pack("dynasty"); seeds
## Sfx.PACK_SEED + Sfx.PACK_SEED_OFFSETS["dynasty"] + i, offset 9000). Nothing plays them until the stage agents wire the sound map.
const DYNASTY_SOUNDS: Dictionary = {  # TUNING (not in GDD)
	# A Name appears on a cartouche over a fallen body: a bright little bell, two partials, a faint shimmer.
	"cartouche_chime": {"dur": 0.9, "volume_db": -17.0, "max_voices": 4, "min_interval": 90, "pitch_var": 0.06, "priority": 1,
		"layers": [
			{"wave": "sine", "f0": 1568.0, "dur": 0.8, "amp": 0.16, "attack": 0.002, "decay": 0.3},
			{"wave": "sine", "f0": 4328.0, "dur": 0.5, "amp": 0.05, "attack": 0.002, "decay": 0.15},
			{"wave": "sine", "f0": 2349.0, "start": 0.07, "dur": 0.6, "amp": 0.07, "attack": 0.002, "decay": 0.22},
			{"wave": "noise", "dur": 0.02, "amp": 0.03, "attack": 0.001, "decay": 0.006, "lp0": 8000.0}]},
	# A body returns (Rebirth): a low groan that rises through a dry rasp, ending on a thump.
	"rebirth_groan": {"dur": 1.7, "volume_db": -12.0, "max_voices": 2, "min_interval": 250, "pitch_var": 0.06, "priority": 3,
		"layers": [
			{"wave": "saw", "f0": 52.0, "f1": 84.0, "dur": 1.4, "amp": 0.2, "attack": 0.5, "decay": 0.7, "lp0": 200.0, "lp1": 600.0, "vib_hz": 6.0, "vib_depth": 0.03},
			{"wave": "noise", "dur": 1.2, "amp": 0.12, "attack": 0.5, "decay": 0.5, "lp0": 300.0, "lp1": 1400.0},
			{"wave": "sine", "f0": 110.0, "f1": 140.0, "start": 0.3, "dur": 1.2, "amp": 0.1, "attack": 0.6, "decay": 0.5, "vib_hz": 5.0, "vib_depth": 0.04},
			{"wave": "sine", "f0": 90.0, "f1": 42.0, "start": 1.15, "dur": 0.5, "amp": 0.3, "attack": 0.004, "decay": 0.18}]},
	# The Sandstorm blows in: a long, swelling roar of sand and a low wind moan.
	"sandstorm": {"dur": 3.4, "volume_db": -17.0, "max_voices": 1, "min_interval": 3000, "pitch_var": 0.02, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 3.2, "amp": 0.22, "attack": 1.4, "decay": 1.4, "lp0": 500.0, "lp1": 2600.0},
			{"wave": "noise", "start": 0.4, "dur": 2.6, "amp": 0.08, "attack": 1.2, "decay": 1.2, "lp0": 3500.0, "lp1": 6000.0},
			{"wave": "sine", "f0": 70.0, "f1": 95.0, "dur": 3.2, "amp": 0.18, "attack": 1.3, "decay": 1.5, "vib_hz": 0.8, "vib_depth": 0.08},
			{"wave": "sine", "f0": 196.0, "f1": 233.0, "start": 0.6, "dur": 2.4, "amp": 0.04, "attack": 1.2, "decay": 1.0, "vib_hz": 5.0, "vib_depth": 0.03}]},
	# A Canopic Jar breaks: a crack, bright pottery shards and a low thud.
	"jar_shatter": {"dur": 0.8, "volume_db": -12.0, "max_voices": 3, "min_interval": 100, "pitch_var": 0.08, "priority": 2,
		"layers": [
			{"wave": "noise", "dur": 0.1, "amp": 0.4, "attack": 0.001, "decay": 0.03, "lp0": 9000.0, "lp1": 3500.0},
			{"wave": "tri", "f0": 1900.0, "f1": 1500.0, "start": 0.03, "dur": 0.08, "amp": 0.08, "attack": 0.001, "decay": 0.03},
			{"wave": "tri", "f0": 2600.0, "f1": 2000.0, "start": 0.09, "dur": 0.07, "amp": 0.07, "attack": 0.001, "decay": 0.025},
			{"wave": "tri", "f0": 1300.0, "f1": 1000.0, "start": 0.16, "dur": 0.09, "amp": 0.06, "attack": 0.001, "decay": 0.03},
			{"wave": "noise", "start": 0.12, "dur": 0.4, "amp": 0.1, "attack": 0.002, "decay": 0.2, "lp0": 6000.0, "lp1": 2500.0},
			{"wave": "sine", "f0": 130.0, "f1": 60.0, "dur": 0.4, "amp": 0.34, "attack": 0.003, "decay": 0.15}]},
	# A scarab swarm rushes: dense little clicks and a faint wobbling whirr.
	"scarab_swarm": {"dur": 0.9, "volume_db": -21.0, "max_voices": 3, "min_interval": 150, "pitch_var": 0.1, "priority": 1,
		"layers": [
			{"wave": "noise", "dur": 0.7, "amp": 0.06, "attack": 0.15, "decay": 0.3, "lp0": 6500.0, "lp1": 3500.0},
			{"wave": "sine", "f0": 2900.0, "f1": 3300.0, "dur": 0.7, "amp": 0.03, "attack": 0.1, "decay": 0.3, "vib_hz": 28.0, "vib_depth": 0.05},
			{"wave": "noise", "start": 0.04, "dur": 0.01, "amp": 0.3, "attack": 0.001, "decay": 0.004, "lp0": 6500.0},
			{"wave": "noise", "start": 0.11, "dur": 0.01, "amp": 0.26, "attack": 0.001, "decay": 0.004, "lp0": 7000.0},
			{"wave": "noise", "start": 0.17, "dur": 0.01, "amp": 0.32, "attack": 0.001, "decay": 0.004, "lp0": 6000.0},
			{"wave": "noise", "start": 0.26, "dur": 0.01, "amp": 0.24, "attack": 0.001, "decay": 0.004, "lp0": 7000.0},
			{"wave": "noise", "start": 0.33, "dur": 0.01, "amp": 0.3, "attack": 0.001, "decay": 0.004, "lp0": 6500.0},
			{"wave": "noise", "start": 0.43, "dur": 0.01, "amp": 0.22, "attack": 0.001, "decay": 0.004, "lp0": 7000.0},
			{"wave": "noise", "start": 0.52, "dur": 0.01, "amp": 0.26, "attack": 0.001, "decay": 0.004, "lp0": 6000.0}]},
	# A Heka glyph is written on a summon: a rising whisper of two glassy tones and a small bell at the end.
	"heka_glyph": {"dur": 1.0, "volume_db": -16.0, "max_voices": 3, "min_interval": 120, "pitch_var": 0.05, "priority": 2,
		"layers": [
			{"wave": "sine", "f0": 440.0, "f1": 880.0, "dur": 0.7, "amp": 0.12, "attack": 0.4, "decay": 0.25},
			{"wave": "sine", "f0": 447.0, "f1": 893.0, "dur": 0.7, "amp": 0.07, "attack": 0.4, "decay": 0.25},
			{"wave": "tri", "f0": 220.0, "f1": 330.0, "dur": 0.6, "amp": 0.06, "attack": 0.3, "decay": 0.25, "lp0": 700.0},
			{"wave": "noise", "dur": 0.6, "amp": 0.04, "attack": 0.4, "decay": 0.15, "lp0": 1500.0, "lp1": 5000.0},
			{"wave": "sine", "f0": 1760.0, "start": 0.62, "dur": 0.38, "amp": 0.09, "attack": 0.002, "decay": 0.14}]},
}
