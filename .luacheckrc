-- Only check for syntax errors, ignore all warnings
std = "max"        -- Use maximum standard library
allow_defined = true
allow_defined_top = true
max_line_length = false
codes = false      -- Disable all warning codes
only = {          -- Only check for syntax/parse errors
    "011",        -- A syntax error
    "012",        -- A syntax error
    "013"         -- A syntax error
}

