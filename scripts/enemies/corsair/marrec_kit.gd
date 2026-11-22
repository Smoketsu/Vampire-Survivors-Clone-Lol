## MarrecKit — Admiral Marrec's kit (MarrecData.BOSS "kit"; Act X, the Black
## Tide, the Treasure Galleon; GDD §15.0 "Admiral Isabeau Marrec, the Sea Wolf
## (Act X)"). A CorsairKit only so that THE WATER TEST (CorsairKit
## .is_in_water()) sees her while she stands on her flagship or her plank:
## the deck clamp (DeckBounds.contain_all()) then leaves her where BossMarrec
## puts her. BossMarrec sets `in_water` (true on her flagship and the plank,
## false once she is aboard); her own physics runs everything else (Boss).
## Determinism: no RNG.
class_name MarrecKit
extends CorsairKit
