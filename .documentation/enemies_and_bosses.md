# Enemies and Bosses Documentation

## Regular Enemies

### Base Properties
- Health: 100
- Speed: 50
- Turn Speed: 1
- Collision Radius: 8
- Damage: 20
- Damage Radius: 50
- Experience Value: 25
- Drop Chance: 75%

### Elite Variants
- Multiplier: 2.5x stats
- Scale: 1.5x size
- Color: Orange (1, 0.5, 0, 1)

### Enemy Types

1. **Grunt**
   - Default enemy type
   - Basic chase and attack behavior
   - Standard stats

2. **Shooter**
   - Health: 75
   - Speed: 35
   - Attacks: Ranged projectiles
   - Maintains distance from player
   - Experience Value: 35

3. **Charger**
   - Health: 150
   - Speed: 75
   - Damage: 30
   - Charges in straight lines
   - Briefly stunned after charging
   - Experience Value: 40

4. **Splitter**
   - Health: 200
   - Speed: 40
   - Splits into two smaller enemies on death
   - Small variants have 50% stats
   - Experience Value: 45

5. **Shielder**
   - Health: 250
   - Speed: 30
   - Frontal shield blocks damage
   - Must be attacked from behind
   - Experience Value: 50

6. **Summoner**
   - Health: 125
   - Speed: 25
   - Spawns 2-3 weak minions
   - Stays away from player
   - Experience Value: 60

7. **Bomber**
   - Health: 50
   - Speed: 60
   - Explodes on death
   - Damage: 40 (explosion)
   - Experience Value: 30

8. **Cycler**
   - Health: 85
   - Speed: 90
   - Trail length: 200 units
   - Experience Value: 45
   
   Mechanics:
   - Creates deadly trail behind it
   - Trail deals 15 damage per second
   - Attempts to encircle player
   - Trail has limited length (disappears from start as new trail forms)
   - Explodes (40 damage) when trail depletes
   - Elite version:
     - Longer trail
     - Trail persists longer
     - Creates secondary trails
     - Larger final explosion

## Bosses

### Base Properties
- Health: 500
- Speed: 25
- Turn Speed: 0.5
- Collision Radius: 75
- Damage: 40
- Damage Radius: 100
- Experience Value: 500
- Drop Chance: 100%

### Boss Types

1. **The Pursuer** (Original Boss)
   - Standard boss stats
   - Enrage Timer: 10 seconds
   - Charge Speed: 400
   - Charge Duration: 2 seconds
   
   Phases:
   1. Normal Phase
      - Standard movement and attacks
   2. Enraged Phase
      - Increased speed
      - Charging attacks
      - Enhanced damage

2. **The Summoner Queen**
   - Health: 800
   - Summons waves of minions
   
   Phases:
   1. Summoning Phase
      - Spawns elite enemies
      - Creates protective barrier
   2. Vulnerable Phase
      - Direct combat
      - Rapid projectile attacks

3. **The Storm Titan**
   - Health: 1000
   - Lightning attacks
   
   Phases:
   1. Thunder Phase
      - Area denial lightning strikes
      - Electric field damage
   2. Storm Phase
      - Lightning projectiles
      - Pull/push mechanics
      - Thunder clap stun

4. **The Void Weaver**
   - Health: 750
   - Creates damaging zones
   
   Phases:
   1. Weaving Phase
      - Creates void zones
      - Teleports between zones
   2. Chaos Phase
      - Merges void zones
      - Rapid teleportation
      - Mirror images

5. **The Time Keeper**
   - Health: 600
   - Manipulates time
   
   Phases:
   1. Past Phase
      - Creates echoes of past attacks
      - Slows player movement
   2. Future Phase
      - Predicts and counters player movement
      - Accelerated attacks

6. **The Rune Master**
   - Health: 900
   - Uses player's rune effects
   
   Phases:
   1. Absorption Phase
      - Copies player rune effects
      - Enhanced versions of rune abilities
   2. Overload Phase
      - Combines multiple rune effects
      - Area-wide rune explosions

### Elite Enemy Variants

Each enemy type can spawn as an elite version with:
- 2.5x base stats
- 1.5x size
- Orange coloring
- Special abilities based on type:
  - Grunt: Knockback attacks
  - Shooter: Multiple projectiles
  - Charger: Chain charges
  - Splitter: Splits into elites
  - Shielder: Rotating shield
  - Summoner: Elite minions
  - Bomber: Larger explosion

### Spawn Rules
- Regular enemies: Continuous spawning, increasing frequency
- Elite enemies: 10% chance per spawn
- Bosses: Every 5 minutes or at specific progression points

