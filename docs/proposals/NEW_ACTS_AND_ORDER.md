# Necropathy: Three New Acts and the Act Order

Proposal for the owner. Documentation only: no game code is touched. Every number is a starting point for playtests.

**Source.** The owner's ideas (Nov 2, 2026): a **pirate act** on a small boat where enemies board from boats and sea creatures strike from the water; a **prehistoric act** of dinosaurs, won by calling down a meteor and raising the dead as an army; an **Egyptian act**; and the note that the stages are disjointed and the acts must be reordered so the journey escalates.

**Format.** The format of `docs/act7`–`act9/PROPOSAL.md`. The campaign rules every act keeps are in `docs/act4/PROPOSAL.md` and CLAUDE.md. They are: the 20:00 clock, the stage boss with 3:00 left, the Reckoning at 0:00 (dying after 0:00 is a victory), enemies always advance, undead never dodge, the Bone Ring is the only formation, **summons never get act-only rules**, one code path per rule switched by a STAGE key, three stages per act, and a spell + paired passive + playable character per boss. A finale summon class, two counter-passives and three achievements close each act. Female figures use the figure-redesign style. Every figure below has its sex named. Animals are given a sex where it matters (an alpha, a boss).

**Order.** The existing act-order proposal (Claude Doc "Necropathy: A New Act Order", https://claude.ai/artifact/B76vzD659dz2dAyy5P4bqh, owner has not answered it) puts the acts in this order: I Covenant, II Sanguine Court, III Last Line, IV Shogunate, V Olympus, VI Inferno (end of Part One), VII Ancient Eye, VIII Electronic Empire, IX Concord, X Turning Year. Part 4 of this document keeps that proposal's logic and slots the three new acts into it.

---

## Part 1. Act: The Black Tide (the pirate act)

The Covenant is ash, and the only road out of the burning country is the sea. The sea has captains. The Corsair Brotherhood is a loose fleet of cutthroats, gunners, duellists and navigators who sail under the black flag. They have heard that a man raises the dead, and they want what he took from the church's vaults: gold, and the secret of a crew that never dies. They come to him on small boats, hook the rail and climb aboard. Under the ship, the sea has its own opinions: sharks, crabs, squid, serpents and a kraken that the Brotherhood has fed for a century and half-controls.

The look is **tarred oak, sailcloth cream, brass, powder-smoke grey and sash red** under storm-grey sky, with lantern amber for every telegraph. Avoid soul-teal for water (it is the undead's colour) and avoid Gullhaven's drowned green and biolume (Act II). The sea is **deep navy-black with white foam lines**.

### How this act differs from Act II's Gullhaven Harbour
| Gullhaven (built) | The Black Tide |
|---|---|
| Rising tide that slows everyone but swimmers; surges every 4 min | **No tide.** The water is a wall around the deck, not a zone you walk through |
| Deep Kin, Tide Caller, Netcaster: drowned fish-people of the Ancient Eye | **Natural beasts only** (sharks, crabs, squid, serpents, a kraken). No fish-folk, nothing cosmic |
| Enemies walk in from the screen edge on a land arena | **Enemies arrive by boat.** The arena is one deck |
| Claims, Dread (the Eye's rules) | Neither. This is a plain mortal-and-beast act |
| Undertow / Maelstrom spell pulls enemies in | This act's spells knock back, chain and bombard; none pull (see Rewards) |

### Shared rules (stage key `corsair`, object `game.corsair`, class `CorsairRules`; null on every other act)
1. **Boarding** (the headline). Pirates do not appear at the screen edge. Boats pull alongside the rail and pour their crews aboard.
   - A boat shows its **lane** 3 s ahead (a dotted wake line and an amber lantern at the rail point). It then **hooks** the rail with two grapple lines. Each hook is a small structure (40 HP) with a visible rope. Once hooked the boat pours one crewman every 0.6 s for as long as it has crew.
   - **Three sizes (starting points):** skiff (6 crew, 150 hull HP), longboat (12 crew, 300), raider ship (24 crew, 900, two planks). The timeline lists boats, not individual spawns.
   - **Repel:** cut **both** hooks and the boat drifts off for 6 s, its remaining crew cancelled (those already aboard stay). **Sink:** destroy the hull and the remaining crew drown (no XP, one floating crate of loot). Ranged summons, spells and fliers hit boats. Melee summons hit the hooks and the planks.
   - **Budget:** the boats spend the same spawn budget the wave director already uses. No extra enemies, only a different door. The boat lane is chosen from the seeded RNG, so a run stays deterministic.
   - **One path:** `BoardingParty` is the only spawn route on corsair stages. `EnemyDirector` asks it for the next spawn point; if every boarding point is busy the spawn waits in a capped queue. Boats are pooled structures (cap 4 at a time).
2. **The Deck.** The necromancer, every summon and every boarder stay on the boat. The deck is the arena.
   - **One bounds path:** `DeckBounds` (`game.deck`) holds the walkable shape (a rounded rectangle with a bow and a stern) in arena coordinates. `DeckBounds.clamp(pos, r)` runs in `Arena.resolve_all()` as the last step, in the slot where the obstacle push-out already runs (the same place Ul-Thalos's `SinkingDirector` bounds the island). It clamps the player, summons and every enemy flagged `on_deck`. Swimmers and boats carry the flag `water` and ignore it.
   - **Overboard:** the necromancer and summons cannot fall; they stop at the rail (no damage, no loss). A deck enemy pushed past the rail by knockback, a Bone Wall or a powder blast **drowns** and drops its XP at the rail. This makes knockback the act's counterplay.
   - **Furniture:** masts, hatches, barrels, cannons and rigging are ordinary Arena obstacles on an `aligned` fixed layout (like Act VIII's city blocks and the Sanctum's pillars), authored per stage, not scattered by hash.
   - **Fliers** (Gargoyles, Banshees, Fallen Seraphs and the like) may hover up to 120 px past the rail to hit boats, and are pulled back when they leave that band. This is a world rule for every flier on this map, not a class rule.
   - **Camera:** the cutter fits one screen and the camera sits still. The larger decks scroll with the necromancer, clamped to the deck plus a water margin. In co-op both necromancers share the deck, and the fixed co-op view size still drives spawns.
   - **How the Bone Ring fits.** The ring is computed exactly as today (radius from the army size, 60-150 px, two deep when overfull). Each post then passes through `DeckBounds.walkable_point()`, the same hook where `Arena.free_point()` already moves a post out of an obstacle. A post that would hang over water slides inward along the line to the necromancer. Mid-deck the ring is a ring. Beside the rail it becomes a half-ring whose open side faces the water, which is where the boats are. On the 360 px-wide cutter a 150 px ring fills most of the beam, so the ring flattens fore and aft and the extra posts stack two deep (the rule already exists). Priests and catapults stay inside. Volleys fly outward over the water and may hit boats. No class gets a rule.
3. **Strikes from the Sea.** Water creatures swim freely around and under the ship (they ignore the deck, move along the hull and cannot enter the deck). They strike the **rail band** (120 px inside the rail) and sometimes beyond it. A **strike** is a telegraphed circle (1.0 s, dark-water ring) that hits both armies. Types:
   - **Tentacle:** grabs one summon, holds it 5 s with the existing `held_until` hook, then drags it overboard (lost until the next replenish). Kill the tentacle (200 HP, surfaced 3 s) to free it.
   - **Leap:** a shark or serpent breaches with a 0.8 s shadow on the deck and lands inside the ring as an ordinary deck enemy.
   - **Surfacing:** creatures can only be hit while surfaced (2 s); otherwise ranged shots pass over them.
   - The rail band is dangerous, so the army wants to stand mid-deck, but boarders arrive at the rail: the central tension.
   - **One path:** `SeaStrikes` (a scheduler in the style of `DivineWrath`), seeded, with at most 8 swimmers alive.

### Roster
| Kind | Tier | What it does | How you beat it |
|---|---|---|---|
| Deckhand (male) | Fodder | Cutlass mobs that come off the boats in streams | Anything; Warriors at the boarding point |
| Musketeer (male) | Ranged fodder | Fires from the boat while it is hooked, then from the deck. Ordinary projectiles, no line rules | Sink or repel the boat; Archers |
| Powder Runner (male) | Fodder | Sprints with a lit keg, 1 s fuse, blast hits both sides and knocks everyone 60 px | Kill at range; let the blast push the crew overboard |
| Swashbuckler (female, figure style) | Soldier | Rapier lunge that jumps the first blocker and duels the nearest summon | Rogues, Gargoyles, area damage |
| Grappler (male) | Soldier | Throws a hook line that drags one summon to the rail (into the rail band) | Kill first; Sea Legs passive |
| Gunnery Mate (female, figure style) | Ranged elite | Lobs grenadoes with a landing circle that ignore the ring | Kill on the boat; Gargoyles |
| Boatswain (male) | Support | Bellow: +20% move speed and a short shield to crew within 200 px | Priority target |
| Voodoo Navigator (female, figure style) | Support | Marks a Strike circle on the ring; the sea answers 1.5 s later. Dies to cancel it | Priority target; Grave Step |
| Boarding Bruiser (male) | Heavy | Axe that chops the Bone Wall and hooks; flat armour 3 | Siegecraft, Wither; push overboard |
| Gunboat | Boat | Never boards; shells the deck with arcing cannonballs on a landing circle | Sink with ranged units and spells |
| Reef Shark | Swimmer / leaper | Circles; leaps at the ring every ~10 s | Hit it at the leap; Orb Shield |
| Hull Crab (giant) | Swimmer / climber | Climbs the hull, boards at the rail band, armour 4 | Armour-piercing damage |
| Kraken Arm | Swimmer elite (structure) | Tentacle Strike; grabs a summon | Kill it while surfaced |
| Sea Serpent | Swimmer heavy | Breaches in a line across the rail band, then submerges | Step out of the line |

**Reckoning, the Black Tide:** at 0:00 every boat in the sea closes on the ship at once, the whole rail is a boarding point, gunboats shell in lines, and the kraken surfaces. The rail band is struck every 3 s and a great wave shoves everything toward the far rail every 20 s.

### Stage A: The Smuggler's Cutter
A small night-time sloop slipping out of a ruined harbour, with the Covenant's burning coast behind it. A deck 960 × 360 px, a single mast, one hatch, powder barrels along the rails. Boarding points: two per side. Tier cap: skiffs and longboats only.

Zones: the Harbour Mouth, Open Water, the Fog Bank, the Cove.

**Stage mechanic: Powder Barrels.** Barrels stack against the rails. Any hit breaks one: a blast that hurts both sides and knocks everyone 120 px (overboard if near the rail). The fog zone hides boats until 2 s before the lane shows, so the stage teaches "watch the rail".

Miniboss: **Bosun Gorran and the Ram Longboat** (male). A heavy longboat rams the hull (a stagger that knocks every summon back) before it boards.

Boss: **Captain Ezekiel Crow, the Gull King** (male).
- **Broadside:** his sloop pulls alongside; three telegraphed cannon lines cross the deck every 20 s while his crew boards double.
- **The Duel:** he swings aboard and fights the necromancer with a cutlass and a pistol; he leaps the ring on a landing circle.
- **Fire Ship:** he sets his own ship ablaze and rams the cutter; burning planks spread as short fire patches (the Hell Pits ground path, not a new one) until he falls.

### Stage B: The Treasure Galleon
A captured galleon on open water at dawn, with a quarterdeck, a forecastle, three masts and eight deck cannons. A deck 1,500 × 540 px. Boarding points: five. Tier cap: up to raider ships and gunboats.

Zones: the Convoy Lane, the Reef, the Storm, the Gun Deck.

**Stage mechanic: Broadsides.** Every 70 s an enemy galleon pulls alongside and fires a 6-line broadside (1.5 s telegraph, damage to both armies). The galleon's own deck cannons are obstacles that the army can use: any cannon a unit stands next to for 3 s fires once at the nearest boat (a seeded pick, so it is deterministic). The quarterdeck steps are a choke point the ring flows around.

Miniboss: **The Kraken's Arm, Old Hollow-Eye** (a swimmer; tentacles in the rail band). Every tentacle grabs a summon. It teaches the cut-the-tentacle rule before the boss.

Boss: **Admiral Isabeau Marrec, the Sea Wolf** (female, figure style).
- **The Fleet:** her flagship's broadsides on a 30 s rhythm and a raider ship boards with a plank.
- **The Boarding:** she leads her marines across the plank. Cut both hooks and the plank falls, with her crew in the water.
- **Gold Fever:** she throws cursed coins that become short barriers around her marines; clear them with area damage, then she falls to a duel on the quarterdeck.

### Stage C: The Maelstrom (the finale)
The ghost ship *Hollow Queen*, caught in a whirlpool at midnight. Her deck is 1,300 × 500 px and rotting. Boarding points: the whole rail. Tier cap: the full roster, including the ghost crew.

Zones: the Fog of Ships, the Gyre, the Eye of the Storm, the Drowned Helm.

**Stage mechanic: Heave.** The whirlpool tilts the deck. Everyone slides toward the low side at 30 px/s, and the low side flips every 12 s with a 3 s creaking telegraph and a HUD arrow. Units near the low rail are swept into the rail band (strikes). Ghost crews do leave corpses (they are the dead of the sea), so the necromancer raises the Brotherhood's own dead here. It is the act's reward for a good deck.

Miniboss: **The Ghost Bosun** (male), whose whistle summons a spectral longboat.

Boss: **Captain Cornelius Vandermere, Master of the Hollow Queen** (male).
- **The Crew:** his spectral crew works the ship; ghost boats circle the gyre.
- **The Maelstrom:** the tilt peaks. The kraken's arms strike the low rail whenever the deck leans toward them.
- **Dead Men's Oath:** he is lashed to the wheel behind an Oath shield. Every ghost crewman the army raises chips the Oath (2% each). When it is empty he is vulnerable for 15 s, then the Oath refills and the crew returns. The necromancer's own craft is the weapon.

When he falls, the whirlpool closes and the sea is calm.

### Rewards
| Boss | Spell (paired passive) | Its character |
|---|---|---|
| Crow | Chain Shot: a spectral chain-shot spins through a line of enemies and returns → Keelhauler (+ Bosun's Whistle) | The Marooned Quartermaster (male) |
| Marrec | Cannonade: spectral cannonballs arc down on three marked groups → Dead Men's Broadside (+ Black Powder) | The Corsair Queen (female, figure style) |
| Vandermere | Anchor Drop: a spectral anchor slams the strongest enemy, stuns it and shocks a ring around it (no pull) → Abyssal Mooring (+ Dead Reckoning) | The Ghost Helmsman (male) |

Finale summon class: the **Powder Wraith**, a skeleton carrying a lit keg that walks into a pack and bursts (area damage and a 60 px knockback), then reforms at the ring after 12 s (evolution Magazine Lord). It is a class special, so it works on every stage.

Counter-passives (Act only): **Sea Legs** (the Heave drift and grapple pulls are halved for the army), **Barnacle Bones** (summon hits on boats, hooks and surfaced creatures deal more).

Achievements: **Not One Aboard** (sink five boats before a single crewman climbs aboard, on the Cutter), **Walked the Plank** (push 200 enemies overboard in one run), **Dead Men Tell Tales** (beat Vandermere with the Oath broken three times; opens the act's epilogue part).

### Risks
The deck is the biggest technical change in this proposal. Prototype the Cutter alone first: a `DeckBounds` that clamps and a `BoardingParty` that spawns one boat, with the Bone Ring on a 360 px beam. A small spike answers "does the ring look right?" before any art.

---

## Part 2. Act: The Age of Titans (the prehistoric act)

A world with no gods, no armies and no walls. The land belongs to animals the size of houses. Nothing here commands the dead, and nothing here is afraid of the necromancer: the beasts are hungry, and a man with an army is a herd that smells of meat. The dead are plentiful. Every big animal that falls leaves a skeleton, and a skeleton is something the necromancer can use.

The look is **fern green, volcanic orange, tar black, dust ochre and bone white**. The sky carries a thin white streak that grows through the act: the meteor.

### How the necromancer gets there (two framings)
- **Framing A, recommended: the Last Harvest.** This act sits after the Concord of Stars. The Concord's Ark holds a harvest log of every world it has reaped. The oldest entry is this one: the Harvesters seeded the world, let it grow, then **called down a meteor** to clear the beasts for the harvest. The necromancer takes the Harvesters' tractor-beam array and follows the log back through a rift in the harvest vault to the day before the impact. He does not just visit the meteor: he takes over **the Harvesters' Call** and decides when the sky falls. This explains why the necromancer, not the Concord, calls it, and it ties the meteor to a story we already have.
- **Framing B: the oldest graveyard.** Every graveyard in the world is cut into the same stone. Digging deeper through fossil beds, the necromancer's power reaches the oldest dead and a rift opens onto the age they lived in. Standalone, and it fits any slot, but the rift is arbitrary and the meteor has no author.

### How this act differs from the others
| Act | Hazard rule | This act |
|---|---|---|
| IV Olympus, Wrath of the Gods | God-sent strikes on a rhythm; hits both armies | Herds are live animals, killable, neutral, and give corpses. Not a schedule |
| VIII Last Line, Armour | Vehicles drive straight lines and leave wrecks | A stampede is a wide living front; it leaves bodies to raise, not wrecks |
| VIII Last Line, Civilians | A crowd at the start that flees and drops XP | Herds are huge, wander all run, stampede when frightened, and drop mega-corpses |
| VII Court, Night Wings | Fliers that the ring cannot block | Pterosaurs share the `flies` flag but steal pickups instead of biting |

### Shared rules (stage key `primeval`, object `game.primeval`, class `PrimevalRules`)
1. **Packs** (the headline). Predators hunt in packs with an **alpha**. A pack circles the ring for a moment (rustling ferns show each flank), holds 1.5 s, and rushes together with +40% speed and a flank path. **Kill the alpha and the pack loses its bonus** and charges straight in, uncoordinated. (Nobody retreats: enemies always advance.) A pack is a group in the spawn timeline with one alpha flagged. One path: `PackBrain`, a per-group steering state the enemy kit reads. Bone Hounds' Pack Hunt is a summon-side feature and is unrelated.
2. **Herds.** Big herbivores (Longnecks, Duckbills) wander the arena as **neutral** bodies. They do not attack. They drop big XP and a **heavy corpse** when killed, and they **stampede** when hurt or when a fight is close: a living front 600 px wide runs in a telegraphed straight direction (dust line 2 s ahead), trampling everyone it crosses, both armies. Rocks and fossil arches in the arena are **shelter**: the stampede passes around them. Counterplay: take shelter, Bone Wall behind a rock, Grave Step through the gap, or lure predators into the herd's path. A heavy corpse raises as a **Fossil Giant** (a temporary summon: HP ×4, lasts 30 s, at most 2 alive). That is the act's gift to the necromancer, through `HordeDirector.raise_corpse()` / `spawn_temporary()`. One path: `Herds`.
3. **Scavengers.** Pterosaurs snatch XP crystals and drops: every 8 s a Skyraider dives (a shadow circle first), takes the nearest pile worth up to 10 crystals and flies to a cliff nest at the arena's edge. **Kill it in the air and the pile drops where it dies.** Anything within 200 px of the necromancer is safe from snatching. This pressures the economy, not the army. One path: `Scavengers`, a thin scheduler over the pickup pool; it never changes XP values.

### Roster
Sex is named for the figures where it matters (alphas, bosses); no human fights in this act.

| Kind | Tier | What it does | How you beat it |
|---|---|---|---|
| Scuttler (swarm of 12) | Fodder | Fast, tiny, chittering swarm | Anything; area damage |
| Razorclaw (female alpha, males in the pack) | Soldier | Pack leap over the first blocker, rakes the nearest summon | Kill the alpha first |
| Frill-Spitter (male) | Ranged | Lobs a venom bolt that leaves a short puddle; arcing | Kill on approach; Wither |
| Horncharger (male) | Heavy | Telegraphed straight charge that stuns summons; stuck in a rock for 2 s on a miss | Dodge by Grave Step; Bone Wall |
| Clubtail (female) | Heavy | Flat armour 5; a tail sweep that knocks summons back | Siegecraft, Wither, Rot |
| Longneck (male, female mix) | Herd (neutral) | Huge, slow, bleeds XP; stampedes | Shelter, lure, kill for the corpse |
| Duckbill | Herd (neutral) | Smaller herd; the crest horn calls the whole herd to run | Same |
| Skyraider (male) | Flier, thief | Dives, snatches a pile (Scavengers) | Archers, Gargoyles, spells |
| Stormwing (female) | Flier elite | Wing gust that pushes the ring 100 px; lands to peck | Hit her at the landing circle |
| Bog Croc (male) | Ambush | Hides in tar and river tiles; lunges at the rail of the ring | Wither, Area, avoid the tar |
| Tyrant (female / male) | Miniboss kind | Bite that swallows a summon for 4 s; a roar that stuns the ring 1.2 s | Burst; Bone Wall; the swallowed summon cuts its way out |

**Reckoning, the Stampede of Ash (Stages A and B):** at 0:00 the sky burns. Every herd stampedes at once from every side, volcanic bombs fall on telegraphed circles, packs double and Tyrants roam. **The Impact (Stage C, below).**

### Stage A: The Fern Basin
A river basin deep in jungle. The sky is still blue and the white streak is faint.

Zones: the Fern Floor, the Tar Seep, the River Ford, the Nesting Hollow.

**Stage mechanic: Tar Seeps.** Pools of tar slow everyone through the existing `TerrainSlow` ground path. Herbivores get stuck in tar: a trapped Longneck is a free kill and a free heavy corpse. Bog Crocs ambush from the seeps.

Miniboss: **Ironjaw, the Nest Mother** (female), a bulky predator who defends a nest: the nest spawns Scuttlers until it is destroyed.

Boss: **Scarmaw, the Great Raptor** (female alpha).
- **The Hunt:** she commands three packs in turn and leaps over the ring.
- **The Ambush:** she vanishes into marked fern patches and lunges from one every 8 s.
- **Blood Up:** at half health her pack respawns for every kill and she moves faster; kill her alpha-guard to end it.

### Stage B: The Great Plain
Open grassland under a hot sky with a bright streak. Herds dominate the screen.

Zones: the Dust Flats, the Watering Hole, the Canyon, the Bone Gate.

**Stage mechanic: The Watering Hole.** A central lake gathers herds; fighting near it triggers stampedes. A Canyon zone makes the stampede lanes narrow.

Miniboss: **Mother Clubtail** (female), an armoured matriarch who guards a herd.

Boss: **Old Ironbrow, the Horned Titan** (male ceratopsian).
- **The Herd:** he leads a stampede himself; the front runs behind him.
- **The Charge:** straight-line charges at the necromancer. Missing into a rock stuns him for 3 s.
- **The Break:** he snaps one horn on a rock; the shards fly as 3 short lines, then he charges with the stump.

### Stage C: The Last Day (the finale)
The impact basin. The sky is white and the meteor is the size of a moon. Ash falls.

Zones: the Scorched Plain, the Ash Forest, the Lava Fields, the Impact Rim.

**Stage mechanic: Fire from the Sky.** Small meteorites strike telegraphed circles every 12 s, hurting both armies, with the interval shrinking each zone. The HUD clock shows the meteor growing as the time runs out.

Miniboss: **Thunderwing, the Sky King** (male), a giant pterosaur whose wing gusts clear the ring.

Boss: **Old Gravejaw, the Tyrant King** (male).
- **The Roar:** a roar that stuns the ring and calls every beast on the map to him.
- **The Hunt:** he hunts the necromancer, ignoring summons; he bites through the ring and swallows.
- **The Last Day:** the sky is white. He turns toward the impact and rampages toward the Mound.

The boss's kill is what unlocks his spell and the next act. The meteor kills everyone else.

### The meteor: two options
The owner's idea is "win by calling down a meteor to kill them all, then raise them as your army". The structure says the Reckoning ends every run and dying after 0:00 is a victory. Here are two ways to fit them.

**Option A (recommended): the meteor is the Reckoning on the finale stage.**
- The 20:00 clock stays. On Stage C the sky shows the meteor growing with the clock. At 3:00 the boss arrives, as everywhere. The necromancer has taken the Harvesters' Call (Framing A), so the meteor is *his*.
- **At 0:00 the meteor lands** and replaces the swarm Reckoning with the **Extinction**, a 45 s scripted finale:
  1. A 5 s telegraph: the screen whites out and shock rings expand. The necromancer is protected by a one-time ward.
  2. The impact kills every enemy on the map. A boss still alive drops to 10% HP and does not give his spell (the spell is for the player who killed him before the fall).
  3. **The dead rise.** Every corpse on the map becomes a temporary **Fossil Host** (cap 60, 45 s). The army you built raises the world's beasts, and the Host cleans up the last survivors.
  4. The run ends in **Victory**. If the necromancer dies at any point after 0:00 it is still a victory, as the rule says.
- Why it fits: the Reckoning still ends the run; dying after 0:00 is still a victory; no early-end path appears; the bots and the same-seed gates keep their shape; the "call" is the story, and the Host is the payoff of the idea.
- Cost: one new Reckoning kind (`Extinction`), one mass-raise helper (`raise_corpse()` called in a capped loop), and a victory scene. Stages A and B keep the normal Reckoning (the Stampede of Ash).
- Optional polish (later): **lit beacons**. Three optional beacons on the map, each channelled for 15 s under fire. Each brings the impact 30 s sooner and adds +10% Soul Ash for the run: a risk-and-reward lever in the spirit of the Profane Pact. It gives the player the feeling of "calling it", without breaking the clock.

**Option B: a stage objective.**
- At 3:00 left the three beacons activate. The player defends each while it charges. When all three are lit he may call the meteor at any time: it lands at once, kills everything, raises the Host, and the run ends in Victory early.
- Pros: real agency; the player literally wins by calling the meteor.
- Cons: a new early-victory path breaks the 20:00 run structure and the "dying after 0:00" pillar; Soul Ash and pacing need new rules (is a 17:00 victory worth less?); bots need beacon logic; and a strong build would skip the boss entirely. It needs several owner decisions, which is why it is not the recommendation.

### Rewards
| Boss | Spell (paired passive) | Its character |
|---|---|---|
| Scarmaw | Pack Leap: three spectral raptors leap at marked enemies → Apex Pack (+ Pack Instinct) | The Fern Huntress (female, figure style) |
| Old Ironbrow | Stampede: a spectral horned charger tramples a line → Herd of Ages (+ Calcified Hide) | The Herd-Warden (male) |
| Old Gravejaw | Meteor Call: a telegraphed meteor lands on the densest group → Extinction Event (+ Cosmic Dust) | The Skywatcher (female, figure style) |

Finale summon class: the **Bonehorn**, a skeletal ceratopsian that charges in a straight line through a pack, trampling and knocking back, then trots back to the ring (evolution Fossil Tyrant). It is a class special, so it works on every stage.

Counter-passives (Act only): **Hoarder's Bones** (crystals and drops within 300 px cannot be snatched; a snatched pile drops sooner), **Thick Marrow** (summons take less damage from trampling, charges and stomps).

Achievements: **Nothing Taken** (finish the Great Plain without losing a crystal pile to a Skyraider), **Trampled** (a stampede kills 100 enemies in one run), **The Day the Sky Fell** (reach the Extinction with no summon lost; opens the act's epilogue part).

### Risks
Neutral herds and a mass raise are new to the pool: cap bodies (herds at 6 alive, Fossil Giants at 2, Fossil Host at 60) and test the Web build on a phone. The meteor visuals should be a few large textures and white-out rects (no screen-reading shader, the rule from the Web death crash).

---

## Part 3. Act: The Necropolis Dynasty (the Egyptian act)

The Black Land is the oldest empire of the dead in the world. For three thousand years its people prepared for a second life with a precision no one else bothered with: names written in stone and on linen, hearts weighed, organs kept in jars, every body wrapped, every tomb guarded. The gods of that second life are the oldest **masters of the dead** there are, and every mummy belongs to one of them by name. When the necromancer's army took the world's dead, it pulled at strings the Dynasty tied for three millennia. The Dynasty's priests, guardians, jackal-warriors and god-avatars come to take their dead back, and to take the necromancer's with them.

The look is **gold, lapis blue, sandstone, carnelian red and papyrus green**, with blue-black desert night. Gold is already the game's colour for evolution, chests and selection, so the act uses a **duller bronze-gold** for enemies and keeps true gold for the player's rewards.

### How this act differs from Act II (Claims) and Act IV (Wrath)
| Built rule | What it does | This act |
|---|---|---|
| Act II Claims | The Eye takes the necromancer's *fallen summons* and raises them as thralls | Here the *enemy* dead are bound to a master and **return** unless the necromancer takes them first. The contest is over the enemy's corpses |
| Act IV Wrath of the Gods | A patron god's hazard strikes the arena on a rhythm, both armies | No god-sent strikes. The gods are bosses who stand on the field; the arena's hazard is weather and curses |
| Act VII Bloodfeast | Enemies heal by hitting | None. Enemies come back, they do not heal |

### Shared rules (stage key `dynasty`, object `game.dynasty`, class `DynastyRules`)
1. **Rebirth** (the headline). Dynasty dead wear their **Name** on a cartouche. When a mummy or a guardian falls, a gold cartouche floats over the corpse for **6 s**. If it is not **raised** in that time, or smashed (one hit from any source), the body **returns** at 70% HP with a +20% damage stamp (at most twice per body). Raising it with `HordeDirector.raise_corpse()` steals the Name and the dead one becomes the necromancer's own temporary summon: **raising is the counter**. Embalmers speed the timer. Canopic Jars (structures) hold the Names of every body within 300 px: break the jar and its bodies return no more. One path: `Rebirth` (corpse hook in the enemy death path, called once, like `Enemy.leaves_corpse()` for Steel). Steel-like exceptions: scarabs and animals do not return.
2. **The Black Land.** The desert is the arena. Dunes slow (quicksand patches through `TerrainSlow`) and, every 5:00, a **Sandstorm** blows for 40 s (shown 10 s ahead on the HUD). During it **ranged weapons have half range for both armies** (arrows, spells aimed by range, volleys) and enemies are partially hidden beyond 300 px. Melee armies prosper, and the Nile Archers fall silent. One clock path: `Sandstorm`, like Act VII's `BloodMoon`.
3. **Heka** (words of power). A priest writes a **glyph** on a summon (a gold sigil above it): the summon deals less damage and moves slower (−20% each). Every 2 s the glyph jumps to an adjacent summon, so on the Bone Ring it runs around the circle. Cleanses: a Mender's heal, a Warder's ward, or the priest's death (all glyphs from that priest vanish). A curse lasts at most 10 s. One path: `CombatResolver.curse_unit()` (the only way a summon is cursed), read by `compute_stats()` like the other debuffs. This is the act that asks for priests.

### Roster
| Kind | Tier | What it does | How you beat it |
|---|---|---|---|
| Mummy (male) | Fodder | Slow, wrapped, Rebirth; fire (Rot burn, Mages) does ×1.5 | Raise it; area damage |
| Mummy (female) | Fodder | Same, a faster walker | Same |
| Scarab Swarm | Fodder swarm | 12 beetles, fast, gnaw a summon's barrier or Orb Shield; no Rebirth | Area damage; Warders recast barriers |
| Khopesh Guard (male) | Soldier | Curved blades, a spinning slash; Rebirth | Raise it |
| Nile Archer (female, figure style) | Ranged | Arrows; silenced by sandstorms | Kill early; wait out the storm |
| Heka Priest (male) | Support | Writes the glyph; casting circle on his feet | Priority target; Gargoyles |
| Embalmer (female, figure style) | Support | Wraps the fallen: the cartouche timer −3 s nearby and heals soldiers | Priority target |
| Jackal Warrior (male, jackal-headed) | Elite | Fast lunge; Rebirth; pack of two | Blockers; raise it |
| Bastet Hunter (female, figure style, cat-masked) | Elite | A fast duellist; vanishes into the sand and ambushes a ranged summon | Area damage reveals her |
| Crocodile Warden (male) | Heavy | Rises from quicksand; armour 3; drags a summon in | Wither; avoid the quicksand |
| Ushabti Statue | Heavy | A stone servant; wakes from an alcove; no Rebirth; armour 5 | Siegecraft |
| Canopic Jar | Structure | Holds the Names within 300 px | Break it |
| Sand Colossus | Miniboss kind | A huge statue; ground slam | Burst; stay at range |

**Reckoning, the Devourer's Hour:** at 0:00 every sarcophagus in the necropolis opens: Rebirth has no limit, the Sandstorm becomes permanent, and a huge shadow, the Devourer, sweeps telegraphed lanes across the map, eating every corpse and unit in them.

### Stage A: The Necropolis of Sand
The tomb road at dusk: dunes, rock-cut tombs and mortuary temples. This is the outer edge of the Dynasty.

Zones: the Dunes, the Tomb Road, the Sandstorm Pass, the Mortuary Temple.

**Stage mechanic: Canopic Jars.** Jars sit beside tombs. Break one and Rebirth stops in its radius. This teaches the core rule.

Miniboss: **The Sand Colossus** (a statue).

Boss: **Anubis, Opener of the Way** (male, jackal-headed).
- **The Procession:** he leads a funeral march of mummies; every jar must be broken to end Rebirth.
- **The Embalmer:** he wraps the fallen on the whole map; the cartouche timer is 3 s while he does.
- **The Jackal:** he drops the wrapped pose and duels: fast, with afterimage lunges.

### Stage B: The Temple of the Lioness
A sun-baked temple of colonnades and statue-lined courts, sacred to the goddess of war and plague.

Zones: the Avenue of Statues, the Courtyard, the Hypostyle Hall, the Sanctuary.

**Stage mechanic: Awakening Statues.** Statues on the walls and along the avenue are ordinary Arena obstacles until a zone change or an event wakes a row (eyes glow for 2 s): each becomes an Ushabti or a Sand Colossus enemy, leaving a gap in the layout. No enemy appears from outside; the stone itself walks.

Miniboss: **The Lion Warden** (male), a huge statue-warrior that stands in a doorway and must be killed to pass.

Boss: **Sekhmet, the Lioness of Retribution** (female, lioness-masked, figure style).
- **The Hunt:** she leaps between pillars and rakes the ring on a landing circle.
- **The Red Wind:** she calls a Sandstorm early and the Heka glyph spreads at double speed.
- **The Feast:** enraged, she cannot be stopped. Three red-wine jars (structures) fill the arena; break all three while she drinks from each and she stumbles for 4 s, which is when she can be hurt.

### Stage C: The Hall of Two Truths (the finale)
The judgment hall of the dead: gate of reeds, river of fire, the great scales.

Zones: the Gate of Reeds, the River of Fire, the Hall of the Scales, the Throne of Osiris.

**Stage mechanic: The Scales.** A great pair of scales stands in the hall, and a Balance bar appears on the HUD. Each Rebirth tips the scale toward the Dynasty; each raise tips it toward the necromancer. Past a threshold either way: toward the necromancer, Dynasty enemies deal −15% damage (Ma'at's favour); toward the Dynasty, they gain +15% and Rebirth timers are 2 s shorter. Raising the dead is the way to win the scale.

Miniboss: **The Devourer's Whelp** (a young hippo-lion-crocodile beast), who eats corpses.

Boss: **Osiris, Lord of the Dead, and Ammit the Devourer** (Osiris male; Ammit a monster).
- **The Judge:** Osiris on the throne; Heka glyphs and Rebirth at speed; his court fills the hall.
- **The Weighing:** the necromancer's heart (a glowing orb) is placed on the scales for 60 s. If the Balance ends toward the Dynasty, **Ammit eats 30% of the summons**. If it ends toward the necromancer, Osiris's shield breaks by 25%. Every raise matters.
- **The Devourer:** Osiris gives the throne to Ammit. She eats every corpse on the map, charging in lanes, and leaves no Rebirth. Slay her and the throne is empty.

When Osiris falls, no old master has a claim on the dead.

### Rewards
| Boss | Spell (paired passive) | Its character |
|---|---|---|
| Anubis | Linen Bind: spectral bandages wrap up to 5 enemies and hold them 1.2 s; wrapped enemies that die rise as temporary Mummies → Eternal Shroud (+ Natron Salts) | The Embalmer (female, figure style) |
| Sekhmet | Burning Eye: a solar eye fires a beam that sweeps a 90° arc → Eye of Retribution (+ Desert Fury) | The Lion-Priestess (female, figure style) |
| Osiris and Ammit | Feather's Verdict: a gold feather lands on the strongest enemy and executes weak enemies in a ring around it → Heart Devoured (+ Heavy Heart) | The Pharaoh's Shade (male) |

Finale summon class: the **Ushabti Sentinel**, a stone servant that **reassembles** once every 25 s when slain, at half health (evolution Eternal Guard). It is a class special, so it works everywhere.

Counter-passives (Act only): **Embalmed Bones** (summons shed a curse glyph faster and take less damage while cursed), **Dune Walkers** (quicksand slows summons by half as much and Sandstorm range loss is smaller for the army).

Achievements: **Names Taken** (raise 100 Dynasty dead before their cartouches expire in one run), **No Jars Left** (break every Canopic Jar on the Necropolis), **A Light Heart** (win the Weighing with the Balance toward the necromancer; opens the act's epilogue part).

### Risks
The mass of cartouche timers is a UI risk: show one gold cartouche per corpse, hide the timer text and shrink the icon with the count. Heka needs a clear visual on a ring full of summons (a gold sigil above each cursed head). Sandstorm uses a flat rect overlay, never a screen-reading shader.

---

## Part 4. The new act order

### The throughline
The necromancer's journey is a climb from **who owns the dead in the living world** to **who owned them before the world began**. It escalates on two axes at once: who comes (a church, cutthroats, a secret court, the modern world, an empire, the oldest death-gods, the Olympians, hell, then forces from outside the world, then the deep past, then the world itself) and how hard the act's rules bend the game (a plain pressure, a constrained arena, an anti-army rule, a shared-resource rule). Part One is the mortal and divine claims on the dead. Part Two is what lies outside and before them.

### The order, one line each
Recommended: thirteen acts, thirty-nine stages. The built acts keep their ids and rules; only the act number, stage numbers and unlock chain change.

**Part One: the claim on the dead (I-VIII).** Every power that ever owned the dead comes to take them back. Chapter one is the living (I-IV), chapter two the old powers (V-VIII). The Inferno ends Part One, as the owner decided.

| # | Act | Stages | Why it sits there |
|---|---|---|---|
| I | **The Crimson Covenant** (built) | 1-3 | The plainest act (no shared rules): the tutorial for the army. A church militia is the smallest threat there is |
| II | **The Black Tide** (new, pirates) | 4-6 | A fleet of cutthroats, still mortal. It is the first act that changes the arena (the deck), so a player learns "the map can be a constraint" while the enemy tier is still low. The Covenant's gold is what draws them |
| III | **The Sanguine Court** (built) | 7-9 | The first monster: a secret, local horror. Its Bloodfeast rule teaches "kill fast" before the arena itself starts bending |
| IV | **The Last Line** (built) | 10-12 | Humanity at full strength: gangs, police, army, heroes. The strongest mortal power and the last mortal act |
| V | **The Shogunate** (built) | 13-15 | An empire of men that has yokai at night and a goddess: the bridge from men to gods. Its numbers do not change |
| VI | **The Necropolis Dynasty** (new, Egypt) | 16-18 | The oldest masters of the dead. The first act whose rule is about the *ownership* of corpses (Rebirth). It is a god-act that still fights with men and beasts, so it follows the Shogunate's goddess and precedes the full pantheon |
| VII | **The Olympian Republic** (built) | 19-21 | A whole pantheon commanding legions. Its hazards hit both armies. Hades's empty kingdom leads straight to hell |
| VIII | **The Inferno** (built) | 22-24 | Hell collects what was owed. It turns the army against you (Temptation) and ends Part One: the necromancer holds the throne below |

**Part Two: beyond the world and before it (IX-XIII).** With heaven, earth and hell answering to him, he draws the attention of what lives outside, then of what lived before.

| # | Act | Stages | Why it sits there |
|---|---|---|---|
| IX | **The Ancient Eye** (built) | 25-27 | An elder god in the deep: the first outside power. Claims and Dread fight for the army itself |
| X | **The Electronic Empire** (built) | 28-30 | Saw the Eye's beacons and came. The link already exists in the story, so the two stay a pair |
| XI | **The Concord of Stars** (planned) | 31-33 | The ones who planted life to reap the dead. Beams, Abduction and Terraforming target the army |
| XII | **The Age of Titans** (new, prehistoric) | 34-36 | The Concord's oldest harvest: the day the sky burned. It reverses the pattern: here the necromancer *calls* the disaster. It also needs the Concord's story (Framing A) |
| XIII | **The Turning Year** (concept) | 37-39 | The world itself, seasons and nature, the finale. After the beasts, the planet remembers how to bury things |

Order note: the Shogunate happens to keep stages 13-15 and the Covenant keeps 1-3. Every other built act moves.

### The closing cards
Each act ends on a card that names the next enemy without showing it. The existing cards from the earlier order proposal are kept where the neighbour is unchanged; the new or changed ones are below (drafts for the owner to rewrite).

| After | Card | Line (draft) |
|---|---|---|
| I Covenant | The Tithe Fleet | The Covenant is ash, and its tithe fleet is adrift with the gold of a hundred cathedrals. The only road out of the burning country is the sea, and the sea has captains. |
| II Black Tide | The Feast Has No Guests | The black flag is down, and the last ship carried a coffin that was never meant to see the sea. Where it came from, a court that has fed on the living for a thousand years finds its cups empty. |
| III Court | The Veil Falls | (kept) |
| IV Last Line | The Sun Still Rises | (kept, first sentence changed) |
| V Shogunate | The Names Are Pulled | The sun goddess is dark. Far to the south-west, in a land of river and sand, the oldest dead in the world lie wrapped in their masters' names, and the masters have felt someone pulling. |
| VI Dynasty | The River Runs Dry | The old judges are gone. Across the sea, another king of the dead finds his kingdom a desert, and complains to a mountain. |
| VII Olympus | The Pit Keeps Count | (kept) |
| VIII Inferno | Something Old Wakes | (kept, as in the earlier proposal) |
| IX Eye | The Beacons Burn | (kept) |
| X Empire | The Harvest Stops | (kept) |
| XI Concord | The Harvest Log | The Ark's vault holds a log of every world it has reaped. The oldest entry is a single day, long ago, when the sky burned. The door in the vault is open. |
| XII Titans | The World Remembers | A star fell once, and the world buried everything under it. Now it remembers how to bury things. |

### What moving the acts costs
It is mostly data and text. The rules are keyed to the STAGE (`eye`, `empire`, `pantheon`, `shogunate`, `inferno`, and so on), not to an act number, so no gameplay code moves.
- **Stage data:** each stage's `act`, the unlock chain (which boss opens which stage), the act tabs (13 tabs will not fit at 1280 px; use the Part groups: two rows or a Part switch), the Codex tabs and the "Stage N" labels. Display numbers can be derived from one ordered list, so renumbering is one table.
- **Soul Ash per-act rule** (×1 / ×1.25 / ×1.5 per stage; it restarts each act): follows the act automatically. With 13 acts the later acts earn the same per-stage multipliers as the first, so the Ossuary economy (`docs/ossuary/ECONOMY.md`, `tools/ash_measure.py`) needs one look: either keep it (every act is a fresh start) or add a gentle act ladder. This is an open question below.
- **Balance:** enemy HP and damage multipliers rise with an act's place. The Eye and the Empire move from II-III to IX-X (a big step up); Olympus and the Inferno shift later; the Shogunate and the Court shift too. A bot pass per moved act, with the owner making the calls. The new acts are tuned to their slots from the start.
- **Unlocks:** Seraphine opens Hyper and the Fallen Seraph, unchanged. Act II's lockable spells and passives and the counter-passives are currently tied to an act number in places ("Act II only through the card row's `act`"). Change them to key on the faction so they follow their act.
- **Saves:** stages are saved by id, so players keep every stage they unlocked. `scripts/core/save_migration.gd` today only carries the Gravebound-to-Necropathy rename. A one-time step is needed here (a new `StageOrderMigration`, or an extension of `SaveMigration`, with a Meta `SAVE_VERSION` bump): grant "unlocked" to every stage the old chain had opened, never close one, and re-derive the pointer to "the next stage" from the new chain. Nobody loses access. A player who has cleared the Eye but not the Inferno would see the Eye in a "later" slot yet still open it.
- **Story text:** the closing cards above, stage descriptions and boss endings that name the previous act ("With Olympus fallen..."), the epilogue parts (they move with their acts; the Inferno's part becomes the Part One finale, "The Throne Below"), and a "Part Two" title card after it.
- **Tests and CI:** the same-seed gate compares stages by id and keeps working. Its "stages 1-N unchanged" wording and the CI job names change. The new acts add their own jobs (one army autotest per stage) and the new stage keys join the autotest `--stage=` list.
- **Co-op:** both machines must run the same build; the order change is data, so it needs no protocol change.
- **Unbuilt gaps while it lands:** the chain skips acts that do not exist yet, and unbuilt acts show "Coming soon" in their slots. Until the Court and the Last Line are built or in their new slots the chain must tolerate gaps (the earlier proposal already says so).

### Which new act to build first
**Recommended: the Necropolis Dynasty (Egypt) first, with a Cutter spike beside it.**
- **Egypt is the cheapest.** Its rules reuse existing paths: the corpse hook and `raise_corpse()` (Rebirth), `TerrainSlow` and a clock path (the Black Land), and a debuff path (Heka). It needs no arena change.
- **It is the best test of the move.** It lands in slot VI, mid-campaign, in the middle of the built acts. It proves the new chain, the Part grouping and the migration on a real insertion before a harder act depends on them.
- **It does not depend on an unbuilt act.** The prehistoric act's best framing needs the Concord, which is still a draft.
- **The Pirates are the riskiest and the most wanted.** The deck, the boarding path and the Bone Ring on a narrow beam are new. Build a tiny spike in parallel (the Cutter, one boat, one swimmer, the ring on a 360 px beam) so the ring question is answered early and the owner can see it. If the spike works, the Black Tide is the second act, and it also fills slot II, the first new gap in the opening of the game.
- **The Age of Titans is last.** It needs the Concord (Framing A), a mass-raise helper, neutral herds and a meteor scene. Its three-stage build should follow once the Concord exists, or earlier only with Framing B.
- Alternative: if the owner wants the most visible new thing first, build the Pirates first. The cost is a larger first risk.

---

## Part 5. Open questions for the owner
Each has a recommendation.

1. **Take this thirteen-act order?** Recommend yes. The alternatives are the original ten-act order (without the three new acts) or the swap of the Shogunate and the Last Line (kept second in the earlier proposal).
2. **Is the pirate act second?** Recommend yes: a mortal threat that introduces the deck while the enemy tier is low. Alternative: place it fourth, after the Last Line, as "the last mortals". It would then sit beside the Shogunate's sea voyage.
3. **Prehistoric framing: A (the Last Harvest, after the Concord) or B (the oldest graveyard, any slot)?** Recommend A: the meteor has an author, the necromancer takes the Call, and it needs only a rift in the Ark's vault.
4. **The meteor: Option A (the Extinction as the finale's Reckoning) or Option B (a stage objective that ends the run early)?** Recommend A, with the optional lit beacons later as a risk-and-reward lever. B needs new early-victory rules.
5. **Does the meteor-killed boss count?** Recommend: no. Only a boss the player kills before impact gives the spell and the next-stage unlock. The meteor still wins the run.
6. **Egypt: real deity names (Anubis, Sekhmet, Osiris, Ammit)?** Recommend yes, as the Greek and Japanese acts do. They are ancient mythology, not trademarks.
7. **Which new act first?** Recommend Egypt, with a Cutter spike for the deck.
8. **Soul Ash across thirteen acts: keep the per-act restart (×1 / ×1.25 / ×1.5) or add an act ladder?** Recommend keep; check once with `ash_measure.py` after the first moved act.
9. **Act tabs on the stage select: thirteen tabs?** Recommend grouping by Part (two rows, or a Part switch with act tabs under it).
10. **Where does the Throne phase come back?** The earlier proposal asks whether the Morning Star's cut phase should return as the Turning Year's finale boss rush. Recommend yes, in the Turning Year, since a boss rush of every act's rule fits the end of everything. This is unchanged by this proposal.
11. **Concept art first for the three new acts?** Recommend a lineup, a boss and a stage image each (the Act VII-IX pattern), with the sex named in every prompt, before any sprite.
