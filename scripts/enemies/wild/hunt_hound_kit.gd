## HuntHoundKit — the kit of a HOUND OF THE WILD HUNT (WildEnemyData "hunt_hound";
## temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood (Act XV phase
## 2)"; owner-approved proposal: "Rider of the Wild Hunt (male) | Elite | A
## spectral horseman and two hounds; sweeps across the arena in a line"). A fast
## melee beast that comes with its Rider (WildRiderKit spawns two); it never
## charges on its own (row charge_every 0): when its Rider sweeps, it blinks to
## the Rider's flank and sweeps the same line beside him (WildChargeKit.lead()).
## Determinism: no RNG, no instance ids.
class_name HuntHoundKit
extends WildChargeKit
