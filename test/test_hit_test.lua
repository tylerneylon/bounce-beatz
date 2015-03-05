--[[ pong-love/test/test_hit_test.lua

This is a basic unit test for hit_test.lua.

Run this like so, from this test directory:

  $ lua test_hit_test.lua

--]]

-- Enable requiring modules in our parent directory.
package.path = '../?.lua;' .. package.path

local hit_test = require 'hit_test'

--------------------------------------------------------------------------------
-- Test non-parallel lines.
--------------------------------------------------------------------------------

--[[ Test case: (yes hit)

    |
  --+--
    |

--]]
line1 = {x1 = 0, y1 =  0, x2 = 2, y2 = 0}
line2 = {x1 = 1, y1 = -1, x2 = 1, y2 = 1}
assert(hit_test.line_segments(line1, line2))

--[[ Test case: (no hit)

    |

  -----

--]]
line1 = {x1 = 0, y1 =  0, x2 = 2, y2 = 0}
line2 = {x1 = 1, y1 =  1, x2 = 1, y2 = 2}
assert(not hit_test.line_segments(line1, line2))

--[[ Test case: (no hit)

         |
  -----  |
         |

--]]
line1 = {x1 = 0, y1 =  0, x2 = 2, y2 = 0}
line2 = {x1 = 3, y1 = -1, x2 = 3, y2 = 1}
assert(not hit_test.line_segments(line1, line2))

-- Same test cases as above, but switch line1, line2.

--[[ Test case: (yes hit)

    |
  --+--
    |

--]]
line1 = {x1 = 1, y1 = -1, x2 = 1, y2 = 1}
line2 = {x1 = 0, y1 =  0, x2 = 2, y2 = 0}
assert(hit_test.line_segments(line1, line2))

--[[ Test case: (no hit)

    |

  -----

--]]
line1 = {x1 = 1, y1 =  1, x2 = 1, y2 = 2}
line2 = {x1 = 0, y1 =  0, x2 = 2, y2 = 0}
assert(not hit_test.line_segments(line1, line2))

--[[ Test case: (no hit)

         |
  -----  |
         |

--]]
line1 = {x1 = 3, y1 = -1, x2 = 3, y2 = 1}
line2 = {x1 = 0, y1 =  0, x2 = 2, y2 = 0}
assert(not hit_test.line_segments(line1, line2))

-- Oblique non-parallel lines.

line1 = {x1 = -1, y1 = -1, x2 = 1, y2 =  1}
line2 = {x1 = -1, y1 =  1, x2 = 1, y2 = -1}
assert(hit_test.line_segments(line1, line2))

line1 = {x1 = -1, y1 = -1, x2 = 1, y2 =  1}
line2 = {x1 =  2, y1 =  1, x2 = 3, y2 = -1}
assert(not hit_test.line_segments(line1, line2))

--------------------------------------------------------------------------------
-- Test points and parallel lines.
--------------------------------------------------------------------------------

-- Same line segment.
line1 = {x1 = -1, y1 = 1, x2 = 1, y2 = 1}
assert(hit_test.line_segments(line1, line1))

-- Single-point intersection.
line1 = {x1 = -1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 =  1, y1 = 1, x2 = 2, y2 = 1}
assert(hit_test.line_segments(line1, line2))

-- line2 is a point
line1 = {x1 = -1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 =  1, y1 = 1, x2 = 1, y2 = 1}
assert(hit_test.line_segments(line1, line2))

-- Parallel, same line, but non-intersecting.
line1 = {x1 = -1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 =  2, y1 = 1, x2 = 3, y2 = 1}
assert(not hit_test.line_segments(line1, line2))

-- Parallel but not in the same line.
line1 = {x1 = -1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 = -1, y1 = 2, x2 = 1, y2 = 2}
assert(not hit_test.line_segments(line1, line2))

-- Two intersecting points.
line1 = {x1 = 1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 = 1, y1 = 1, x2 = 1, y2 = 1}
assert(hit_test.line_segments(line1, line2))

-- Two non-intersecting points.
line1 = {x1 = 1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 = 1, y1 = 2, x2 = 1, y2 = 3}
assert(not hit_test.line_segments(line1, line2))

-- Intersecting point / line.
line1 = {x1 = 1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 = 0, y1 = 0, x2 = 2, y2 = 2}
assert(hit_test.line_segments(line1, line2))

-- Non-intersection point / line.
line1 = {x1 =  1, y1 = 1, x2 = 1, y2 = 1}
line2 = {x1 = -1, y1 = 0, x2 = 0, y2 = 1}
assert(not hit_test.line_segments(line1, line2))

-- Intersecting vertical lines.
line1 = {x1 = 0, y1 = 1, x2 = 0, y2 = 3}
line2 = {x1 = 0, y1 = 0, x2 = 0, y2 = 2}
assert(hit_test.line_segments(line1, line2))

-- Non-intersecting vertical lines.
line1 = {x1 = 0, y1 = 1, x2 = 0, y2 = 3}
line2 = {x1 = 0, y1 = 5, x2 = 0, y2 = 8}
assert(not hit_test.line_segments(line1, line2))

-- Intersecting oblique lines.
line1 = {x1 = 0, y1 = 0, x2 = 2, y2 = 2}
line2 = {x1 = 1, y1 = 1, x2 = 2, y2 = 2}
assert(hit_test.line_segments(line1, line2))

-- Non-intersecting oblique lines, same line.
line1 = {x1 = 0, y1 = 0, x2 = 1, y2 = 1}
line2 = {x1 = 2, y1 = 2, x2 = 3, y2 = 3}
assert(not hit_test.line_segments(line1, line2))

-- Non-intersecting oblique lines, not in the same line.
line1 = {x1 = 0, y1 = 0, x2 = 1, y2 = 1}
line2 = {x1 = 2, y1 = 3, x2 = 3, y2 = 4}
assert(not hit_test.line_segments(line1, line2))


-- If we get this far, then everything has passed! w00t
print('Woohoo!\npassed')
