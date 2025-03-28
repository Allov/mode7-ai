-- Global objects defined by LÖVE
globals = {
    "love",
}

-- Exclude some common directories
exclude_files = {
    "vendor/*",
    ".luarocks/*"
}

-- Allow self as implicit global in methods
self = false

-- Maximum line length
max_line_length = 120

-- Maximum cyclomatic complexity of functions
max_cyclomatic_complexity = 10