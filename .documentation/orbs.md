# Orbs Documentation

## System Overview
- Maximum 10 active orbs per run
- Passive abilities that trigger automatically
- Collecting duplicate orbs increases rank
- Ranks range from 1 to 10
- Each rank increases the orb's power

## Orb Types

### Offensive Orbs

1. **Orb of Lightning**
   - Effect: Attack {rank} random enemies for {player damage} every 2 seconds
   - Visual: Blue electric arcs
   - Sound: Thunder crack

2. **Orb of Pulsing**
   - Effect: Fire {4 + rank} projectiles in a ring every 2 seconds
   - Visual: White energy waves
   - Sound: Energy pulse

3. **Orb of Flames**
   - Effect: Create a {2 + (0.3 * rank)} meter fire trail that deals 50% player damage per second
   - Visual: Orange flame trail
   - Sound: Fire crackling

4. **Orb of Frost**
   - Effect: Every 3 seconds, freeze nearest {rank} enemies for 1 second
   - Visual: Ice crystals
   - Sound: Ice formation

5. **Orb of Seeking**
   - Effect: Launch {rank} homing projectiles every 4 seconds, dealing 75% player damage
   - Visual: Purple energy balls
   - Sound: Whoosh

6. **Orb of Explosion**
   - Effect: {10 + (5 * rank)}% chance on hit to cause an explosion dealing 150% damage
   - Visual: Orange explosion
   - Sound: Boom

7. **Orb of Chains**
   - Effect: Attacks have {rank * 10}% chance to chain to {2 + rank} additional enemies
   - Visual: Lightning chains
   - Sound: Electric zap

### Defensive Orbs

8. **Orb of Healing**
   - Effect: Heal {1% + (0.1% * rank)} max health every 2 seconds
   - Visual: Green sparkles
   - Sound: Healing chime

9. **Orb of Defense**
   - Effect: Damage immunity for {rank} seconds when hit, 20s cooldown
   - Visual: Blue shield
   - Sound: Shield activation

10. **Orb of Barrier**
    - Effect: Generate a shield absorbing {rank * 50} damage every 10 seconds
    - Visual: Energy barrier
    - Sound: Shield hum

11. **Orb of Reflection**
    - Effect: {rank * 10}% chance to reflect projectiles back at enemies
    - Visual: Mirror effect
    - Sound: Ping

### Utility Orbs

12. **Orb of Magnetism**
    - Effect: Increase pickup radius by {10 + (rank * 5)} meters
    - Visual: Pulling effect
    - Sound: Magnetic hum

13. **Orb of Time**
    - Effect: Slow enemies within {3 + rank} meters by {rank * 5}%
    - Visual: Time distortion
    - Sound: Time warp

14. **Orb of Fortune**
    - Effect: {rank * 5}% increased drop rates and {rank * 3}% bonus experience
    - Visual: Golden sparkles
    - Sound: Lucky chime

15. **Orb of Splitting**
    - Effect: {rank * 8}% chance for experience orbs to duplicate
    - Visual: Orb division
    - Sound: Pop

### Special Orbs

16. **Orb of Chaos**
    - Effect: Every 5 seconds, trigger {rank} random orb effects at 50% power
    - Visual: Rainbow energy
    - Sound: Chaos burst

17. **Orb of Vampirism**
    - Effect: {5 + rank}% of damage dealt is converted to health
    - Visual: Red essence
    - Sound: Draining sound

18. **Orb of Momentum**
    - Effect: Gain {1 + (0.2 * rank)}% damage every second while moving, reset when hit
    - Visual: Speed trails
    - Sound: Wind rush

19. **Orb of Vengeance**
    - Effect: Store {rank * 10}% of damage taken, release as explosion on next attack
    - Visual: Red aura
    - Sound: Revenge blast

## Orb Combinations
Special effects when specific orb combinations reach rank 5:

1. **Lightning + Chain**
   - Effect: Lightning strikes chain to additional targets

2. **Frost + Pulsing**
   - Effect: Pulse rings freeze enemies

3. **Healing + Defense**
   - Effect: Healing doubled during immunity

4. **Fortune + Splitting**
   - Effect: Chance to triple experience orbs

5. **Chaos + Any Orb**
   - Effect: Chosen orb triggers twice when selected by chaos