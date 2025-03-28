# Contributing Guidelines

## Development Setup

1. Install LÖVE from https://love2d.org/
2. Install Luacheck: `luarocks install luacheck`

## Code Style

- Use 2 spaces for indentation
- Follow Lua style guide
- Run luacheck before submitting PRs

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
└── main.lua         # Entry point
```

## Pull Request Process

1. Create a feature branch
2. Update documentation as needed
3. Run luacheck
4. Submit PR with clear description