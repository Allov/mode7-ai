# Mode 7 Game Engine

A modern interpretation of Mode 7-style graphics built with LÖVE (Love2D).

## Features

- Mode 7 perspective rendering
  - Dynamic lighting system
  - Fog effects
  - Skybox integration
- Dual input support (Keyboard/Mouse + Controller)
- Advanced targeting and combat system
  - Auto-targeting
  - Target lock-on
  - Orbital combat
- Power-up systems
  - Experience-based leveling
  - Collectible runes with unique effects
  - Combinable power-ups
- Boss encounters
  - Special attack patterns
  - Enrage mechanics
  - Guaranteed rare drops
- Debug console with commands
- Comprehensive test suite

## Requirements

- LÖVE 11.4 or newer
- Lua 5.1+
- Luacheck (for development)

## Quick Start

1. Clone this repository
2. Install LÖVE from https://love2d.org/
3. Run the game:
   ```bash
   # Windows
   st.bat
   
   # Other platforms
   love .
   ```

## Controls

### Keyboard & Mouse
- WASD: Movement
- Mouse: Camera rotation
- Space/Left Mouse: Shoot
- Right Mouse: Dash
- `: Debug console
- Escape: Toggle mouse capture
- F11/Alt+Enter: Toggle fullscreen

### Controller
- Left Stick: Movement
- Right Stick (X-axis): Camera rotation
- RB/RT: Shoot
- B: Dash

## Development

This project uses:
- Luacheck for code linting
- Standard Love2D project structure
- Automated testing
- Build scripts for distribution

See [CONTRIB.md](CONTRIB.md) for development setup and guidelines.

## License

[MIT License](LICENSE)


