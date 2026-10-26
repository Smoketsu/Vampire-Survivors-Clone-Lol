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

## Run-loop scores by STAGE "music" id (Sfx.play_music() modes; "" / absent =
## the Act I loop): "tide" = "Below the Tide" (Act II), "iron" = "Iron Requiem"
## (Act III), "bronze" = "Hymn of Bronze" (Act IV), "sun" = "The Setting Sun" (Act V). Each has its own fixed synth seed (Sfx.SCORE_SEEDS).
const SCORES := {
	"tide": TIDE_SCORE,
	"iron": IRON_SCORE,
	"bronze": BRONZE_SCORE,
	"sun": SUN_SCORE,  # Act V
}
## Sound pack each score asks for when its run starts (Sfx.prepare_pack():
## "empire" = EMPIRE_SOUNDS, the Act III effects; "pantheon" = PANTHEON_SOUNDS,
## the Act IV ones; "shogunate" = SHOGUNATE_SOUNDS, the Act V ones); absent = none.
const SCORE_PACKS := {
	"iron": "empire",
	"bronze": "pantheon",
	"sun": "shogunate",  # Act V
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
}
