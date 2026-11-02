## FieldMedicKit — the kit of the Field Medic (CityEnemyData "field_medic";
## Act VIII, GDD §15.0 "Act VIII foundation (phase 1)"): SWAT support (female,
## figure style). She heals soldiers near her through the existing enemy-heal
## path (row behavior "healer": Enemy._try_heal() -> CombatResolver
## .heal_enemy(); never a civilian, Enemy._pick_heal_target()); the CityKit
## keeps her facing. No RNG.
class_name FieldMedicKit
extends CityKit
