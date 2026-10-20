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

## Run-loop scores by STAGE "music" id (Sfx.play_music() modes; "" / absent =
## the Act I loop): "tide" = "Below the Tide" (Act II), "iron" = "Iron Requiem"
## (Act III). Each has its own fixed synth seed (Sfx.SCORE_SEEDS).
const SCORES := {
	"tide": TIDE_SCORE,
	"iron": IRON_SCORE,
}
## Sound pack each score asks for when its run starts (Sfx.prepare_pack():
## "empire" = EMPIRE_SOUNDS, the Act III effects); absent = none.
const SCORE_PACKS := {
	"iron": "empire",
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
