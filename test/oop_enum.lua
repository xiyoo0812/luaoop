--oop_enum.lua

local TEST1 = enum("TEST1", 0, "ONE", "THREE", "TWO")
print(TEST1.TWO)
local TEST2 = enum("TEST2", 1, "ONE", "THREE", "TWO")
TEST2.FOUR = TEST2()
print(TEST2.TWO, TEST2.FOUR)
local TEST3 = enum("TEST3", 0)
TEST3("ONE")
TEST3("TWO")
TEST3("FOUR", 4)
local five = TEST3("FIVE")
print(TEST3.TWO, TEST3.FOUR, TEST3.FIVE, five)
