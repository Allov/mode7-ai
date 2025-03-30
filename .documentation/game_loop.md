# Game Loop Documentation

## Overview
The game runs on LÖVE's main loop system with the following phases:

1. **Load** (`love.load()`)
   - Initialize game systems
   - Load assets
   - Create initial game state

2. **Update** (`love.update(dt)`)
   - Process input
   - Update physics and collisions
   - Update game objects:
     - Player movement and actions
     - Enemy AI and movement
     - Projectile trajectories
     - Power-up and rune effects
     - Experience orb collection
   - Update camera position
   - Update Mode 7 rendering calculations

3. **Draw** (`love.draw()`)
   - Render skybox
   - Render Mode 7 ground plane
   - Render game objects (depth-sorted):
     - Enemies
     - Bosses
     - Projectiles
     - Power-ups
     - Runes
     - Experience orbs
   - Render UI elements
   - Render debug console (when active)

## Critical Timings
- Update cycle: 60 FPS (16.67ms per frame)
- Physics updates: Every frame
- AI thinking: Every 2 seconds
- Power-up updates: Every frame
- Rune rotation: Continuous