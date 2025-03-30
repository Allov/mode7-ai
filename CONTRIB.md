# Contributing Guidelines

## Development Setup

1. Install LÖVE 11.4+ from https://love2d.org/
2. Install Luacheck: `luarocks install luacheck`
3. Configure your IDE (VSCode recommended)
   - Use provided `.vscode/launch.json` for debugging
   - Enable Lua language server

## Code Style

- Use 2 spaces for indentation
- Follow Lua style guide
- Run luacheck before submitting PRs
- Keep functions focused and small
- Document complex algorithms
- Use meaningful variable names

## Project Structure

```
.
├── .instructions/    # Development instructions and documentation
├── .todos/          # TODO items and future features
├── assets/          # Game assets (images, sounds, etc.)
│   ├── images/
│   ├── sounds/
│   └── fonts/
├── src/             # Source code
│   ├── console.lua  # Debug console
│   ├── constants.lua# Game constants
│   ├── main.lua    # Entry point
│   ├── mode7.lua   # Mode 7 renderer
│   ├── player.lua  # Player logic
│   ├── projectile.lua # Projectile system
│   └── rune.lua    # Power-up system
├── test/           # Test files
└── vendor/         # Third-party dependencies
```

## Development Workflow

1. Create a feature branch
2. Write code and tests
3. Run checks:
   ```bash
   check.bat  # Run Luacheck
   test.bat   # Run tests
   ```
4. Update documentation if needed
5. Commit using `cm.bat`
6. Submit PR with clear description

## Testing

- Add tests for new features
- Run full test suite before PR
- Use `test.bat` to run tests
- Debug with VSCode launch configurations

## Building

Use `build.bat` to create distributions:
- Creates `.love` file
- Packages Windows executable
- Handles dependencies

## Debug Console

The game includes a debug console (toggle with `) with commands:
- `help`: Show available commands
- `reset`: Reset game state
- `boss`: Spawn boss
- `chest`: Spawn chest
- `mobs`: Spawn enemies
- `rune`: Spawn power-up rune
