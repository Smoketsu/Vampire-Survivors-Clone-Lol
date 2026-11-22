## DraugrKit — the kit of the Draugr (NorseEnemyData "draugr"; the Hall of the
## Slain, temporarily Act XI; GDD §15.0 "The Hall of the Slain foundation (phase
## 1)"; owner-approved proposal: "Draugr (male and female) | Soldier |
## Barrow-dead in rusted mail; armour 3; a cold touch that slows a summon |
## Wither, Rot"). No special of its own here: the flat armour is its row's
## (the Sanctum's flat armour path), and THE COLD TOUCH is NorseRules
## .on_unit_struck() (called once from CombatResolver.damage_unit() with the
## attacker: its own blow chills the struck summon through
## CombatResolver.chill_unit(), the row's chill_slow for chill_time s). Already
## dead, a draugr is no warrior of the hall: neither chosen nor berserk.
class_name DraugrKit
extends NorseKit
