-- Simple test framework for LÖVE
local lovetest = {
  current_suite = "Default",
  suites = {},
  tests = {},
  failures = {},
  success_count = 0,
  failure_count = 0
}

-- Create a new test suite
function lovetest.suite(name)
  lovetest.current_suite = name
  lovetest.suites[name] = lovetest.suites[name] or {}
end

-- Add a test
function lovetest.test(name, fn)
  table.insert(lovetest.tests, {
    name = name,
    suite = lovetest.current_suite,
    fn = fn
  })
end

-- Assertions
function lovetest.assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nGot: %s", message or "", tostring(expected), tostring(actual)))
  end
end

function lovetest.assert_near(actual, expected, tolerance, message)
  if math.abs(actual - expected) > tolerance then
    error(string.format("%s\nExpected: %s (±%s)\nGot: %s", message or "", tostring(expected), tostring(tolerance), tostring(actual)))
  end
end

-- Run all tests
function lovetest.run()
  print("\nRunning tests...")
  print("==============")
  
  for _, test in ipairs(lovetest.tests) do
    io.write(string.format("%s: %s ... ", test.suite, test.name))
    local success, error = pcall(test.fn)
    
    if success then
      print("OK")
      lovetest.success_count = lovetest.success_count + 1
    else
      print("FAILED")
      lovetest.failure_count = lovetest.failure_count + 1
      table.insert(lovetest.failures, {
        suite = test.suite,
        name = test.name,
        error = error
      })
    end
  end
  
  print("\nTest Results")
  print("============")
  print(string.format("Passed: %d", lovetest.success_count))
  print(string.format("Failed: %d", lovetest.failure_count))
  
  if #lovetest.failures > 0 then
    print("\nFailures:")
    print("=========")
    for _, failure in ipairs(lovetest.failures) do
      print(string.format("\n%s: %s\n%s", failure.suite, failure.name, failure.error))
    end
    love.event.quit(1)
  else
    love.event.quit(0)
  end
end

return lovetest