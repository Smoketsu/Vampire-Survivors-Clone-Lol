# Necropathy: Act VII Proposal (The Sanguine Court)

Owner-approved, with the owner's answers. This copies the Act VII part of the Claude Docs proposal "Necropathy: Acts IV–IX
Proposal" (https://claude.ai/artifact/R4bwVB2JHPiDELgtfCTGBg) into the repo, with the owner's answers that bear on it. The
campaign rules every act keeps are in `docs/act4/PROPOSAL.md`; Act VI's decisions are in `docs/act6/PROPOSAL.md`.

**Build (Oct 31, 2026).** The owner: "Finish implementing all the rest of the planned content. Then we can talk about the
order of it again, so don't worry about epilogue stuff of each act until we nailed down what we're doing with the order."
- **No epilogue part and no closing card** for this act yet.
- The act keeps its current number and stage numbers until the act order is settled (Claude Doc "Necropathy: A New Act
  Order", https://claude.ai/artifact/B76vzD659dz2dAyy5P4bqh).
- Soul Ash follows the per-act rule: ×1, ×1.25, ×1.5.
- Concept art (a lineup, a boss and a stage image) is made first and approved by the owner before the sprites.
- Every prompt names the figure's sex. The mixed lineup holds: male soldiers, and the female kinds in the figure-redesign
  style.

## The owner's answers for Act VII (Oct 31, 2026)
- **Bloodfeast: as written.** Vampires heal 50% of the melee damage they deal, the other Court kinds 25%, and Rot and
  Wither halve it.

## Act VII: The Sanguine Court
The dead who never served. Vampires are the one kind of undead the necromancer has never commanded: they kept their own will, and for a thousand years their Court has fed on the living in secret. Now the necromancer has turned the world's living into his dead, and the Court is starving. It comes with its thralls, its bats, its bat-folk, its werewolf hunters and its witches. The look is blood red, black velvet, candle gold and moonlit silver, with fresh blood as the act's signature colour (it reads against the undead's bone and soul-teal, and against Act VI's lava orange).

### Shared rules
1. Bloodfeast (your idea, as the headline). Court enemies heal on melee hits: each bite, claw or blade heals the attacker for a share of the damage it deals to a summon or the necromancer (about 50% for vampires, 25% for everything else), shown as a red thread from the victim to the attacker. Healing past full HP banks as a blood shield of up to 25% of max HP, so a vampire left feeding on your Warriors gets harder to kill. One path, Bloodfeast, called once from CombatResolver.damage_unit() and damage_player(); enemy healing already flows through CombatResolver, so nothing new heals anywhere else. Counterplay comes from tools the player already has: Rot and Wither halve feeding on the enemies they touch, ranged summons and spells hit without being fed on, and blockers that kill fast feed the Court less than blockers that trade blows.
2. Night Wings. Bats and bat-folk fly over the Bone Ring: the ring cannot body-block them, so they reach the necromancer and the priests inside. They must land to bite (a 0.5 s swoop shown by a shadow on the ground), and in flight only airborne summons, ranged attacks and spells can hit them. It is the act that asks for Gargoyles, Archers, Mages and Banshees, with no act-only summon rule. One flag on the enemy row (flies) read by the existing body-block code.
3. The Blood Moon. Every 4:00 the moon turns red for 45 s (shown 10 s ahead on the HUD). Under it, werewolves transform, every Court enemy feeds twice as hard, and witch covens can cast. Between moons the act plays like a siege; under the moon it plays like a feeding frenzy, and a player who saves Dread Rally or a big cooldown for the moon is rewarded. One clock path, BloodMoon, like the Act II tide surges.

### Roster
| Kind | Tier | What it does | How you beat it |
|---|---|---|---|
| Thrall | Fodder | Bitten servants in mobs, pale and slow; they feed a little | Anything |
| Ghoul | Fodder pack | Packs of 4 that stop to eat corpses (fewer raises) and heal doing it | Kill them before they reach the corpses; Corpse Explosion |
| Vampire Bat | Fodder (flying) | Swarms of 10; Night Wings; they latch onto the necromancer | Gargoyles, Archers, Soul Siphon |
| Blood Knight | Soldier | Halberd and blood-red plate; feeds on every hit | Rot and Wither, fast blockers |
| Chiropteran (bat-folk) | Elite | Mutated bat-people that glide over the ring; a sonic shriek cone that stuns summons for 1.5 s | Hit them in the air; Grave Step out of the cone |
| Werewolf | Heavy | A human hunter with a silver crossbow until the Blood Moon or half HP, then a huge beast that lunges and feeds hard | Burst it before it turns; Siegecraft |
| Crimson Witch | Support (figure style) | Covens of three; together they cast a hex circle that heals the Court inside it and drains the army | Break the coven: kill one and the circle fails |
| Bloated Thrall | Heavy | Swollen with blood; bursts into a pool that heals Court units walking through it | Kill it away from the knights |
| Vampire Noble | Elite (the Countess in figure style) | A blood-drain beam at range (a ranged feed); turns to mist at low HP, 1.5 s untargetable, and reforms nearer the necromancer | Burst damage, Death Mark |
Reckoning, the Endless Feast: at 0:00 the Blood Moon rises and never sets; every coffin on the map opens, and the Court feeds three times as hard each minute.

### Stage 19: Ravensmoor
A cursed village on the moors below the Court's castle, its people long since turned to thralls.


Zones: the Moor, the Village, the Old Church, the Wolfwood.

Sleeping coffins: sealed coffins in each zone. Break one before the next Blood Moon for a Soul Ash bounty; leave it and a Vampire Noble climbs out when the moon turns.

Miniboss, Old Greymane, the pack's alpha, who howls the rest of the wolves into beast form early.

Boss, Vargr, the Moon-Eater: the werewolf king. He calls his own Blood Moon at each phase: the Hunt (he circles the ring and lunges at the weakest summon), the Turning (his pack transforms around him and he leaps over the ring at the necromancer), the Moon-Eater (he swallows the moon: the arena goes dark except a red circle around him, and every hit he lands feeds him).

### Stage 20: The Witchwood
A black fen and a wood of hanging charms where the Court's witches keep their sabbath.


Zones: the Fen (water slows everyone), the Hanging Wood, the Standing Stones, the Cauldron.

Hex stones: standing stones that power the covens' circles; destroy one and its zone's covens cannot cast.

Miniboss, the Bog Mother, a vast drowned witch who drags summons into the fen.

Boss, Isolde Vane, the Witch of the Red Moon (figure style): phase 1, hex circles on the ring and cauldron bombs that leave healing pools for her thralls; phase 2, she splits into three sisters, and all three must fall within 10 s of each other or the fallen ones rise again; phase 3, she calls the Blood Moon and keeps it up until she falls.

### Stage 21: Castle Sanguis (the finale)
The Court itself: a castle above the clouds of the moor, its banquet set for a thousand years.


Zones: the Courtyard, the Banquet Hall, the Crypt Gallery, the Throne of Blood.

The Banquet: blood fountains in the hall heal any Court enemy that stands in them; Bone Wall segments or a Golem parked on a fountain deny it.

Miniboss, the Chiropteran King, a giant bat-man who carries summons off over the ring and drops them outside it.

Boss, Queen Carmilla and the Elder (Carmilla in figure style, the style at its limit as in Act VI):


The Court: the Queen dances through the ring in mist form, her blood-drain beam sweeps the army, and her nobles feed around her.

The Waking: she kneels at the Elder's coffin and feeds him. Every heal she lands on him fills his health bar, so the more she feeds, the stronger the last phase. Interrupt her (stuns, Soul Chains, killing the thralls that bring her blood) to keep it short.

The Elder: the first vampire, an ancient bat-winged horror, with as much HP as she gave him. He commands every bat on the map and feeds on everything he touches.

Beaten, the Elder turns to ash, and the Court's veil over the world tears.

### Rewards
| Boss | Spell (paired passive) | Its character |
|---|---|---|
| Vargr | Moonfang: spectral wolf jaws snap at the nearest group and leave bleeds → Wolf of the Red Moon (+ Pack Blood) | The Moon-Cursed Huntress, a werewolf hunter who turned (figure style) |
| Isolde Vane | Hex Circle: a crimson circle under the necromancer that drains every enemy inside → Witches' Sabbath (+ Moonlit Rite) | The Hedge Witch (figure style) |
| Carmilla and the Elder | Night Swarm: a cloud of spectral bats circles the necromancer and darts at enemies → Nocturne (+ Old Blood) | The Dhampir, half-vampire, half-dead |


Finale summon class: Blood Spawn, fast vampire brawlers that heal themselves on every hit (a class special, so it works on every stage; evolution Nosferatu).

Counter-passives (Act VII only): Embalmed (enemies heal half as much from hitting summons), Silver Bones (summon hits on werewolves and vampire nobles deal more, and mist form lasts half as long).

Achievements: Coffin Nails (break every coffin on Ravensmoor before it opens), The Coven Breaks (kill Isolde's three sisters within 1 s), Last Supper (beat the Elder; opens the Act VII epilogue).

## Concept art
In `art_source/concepts/act7_*.png`, with the prompts beside each image (awaiting the owner's approval before any sprite).
- `act7_lineup.png`: thrall, ghoul, vampire bat, Blood Knight, the Vampire Noble (a woman, figure style), the Chiropteran,
  the Werewolf (the largest), the Crimson Witch (a woman, figure style) and the Bloated Thrall.
- `act7_boss.png`: Queen Carmilla (figure style at its limit, blood-drain beam), the Elder rising from his coffin, and
  Vargr the Moon-Eater howling, in a candlelit throne hall under the moon, with the necromancer's army at the bottom.
- `act7_stage.png`: Ravensmoor in play under the red moon, with Bloodfeast (red threads from bitten skeletons to glowing
  vampire knights), Night Wings (bats and bat-folk with landing shadows), sleeping coffins, a noble's drain beam and a werewolf.
