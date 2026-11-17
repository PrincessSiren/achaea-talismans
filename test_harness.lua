-- Copyright (C) 2026 PrincessSiren
--
-- This program is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
-- more details. You should have received a copy of the GNU General Public
-- License along with this program. If not, see <https://www.gnu.org/licenses/>.

-- Drives AchaeaTalismans.lua under plain luajit against a stubbed Mudlet.
--
--   luajit test_harness.lua
--
-- The listings below are the game's own output, as captured, fed through the
-- package one line at a time the way its trigger would. The pager lines are
-- left in where the game paged, because surviving them is part of the job.

local HERE = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."

local ECHOED, SENT, TRIGGERS, TIMERS, HANDLERS = {}, {}, {}, {}, {}
local WINDOWS, LINKS = {}, {}
local STORED, SAVED = nil, nil
local SAVE_FAILS, RAISE_ON_LOAD = false, false
local CLOCK = 1000

function cecho(a, b)
  if b == nil then ECHOED[#ECHOED + 1] = a else WINDOWS[a] = (WINDOWS[a] or "") .. b end
end
function echo(text) ECHOED[#ECHOED + 1] = text end
function cechoLink(...)
  local args = { ... }
  local win, text, code
  if type(args[4]) == "string" then win, text, code = args[1], args[2], args[3]
  else text, code = args[1], args[2] end
  LINKS[#LINKS + 1] = { win = win, text = text, code = code }
  if win then WINDOWS[win] = (WINDOWS[win] or "") .. text
  else ECHOED[#ECHOED + 1] = text end
end
function send(cmd) SENT[#SENT + 1] = cmd end
local OPENED, HIDDEN = 0, 0
local DOCKED_TO = nil
function openUserWindow(name, _, _, area)
  OPENED = OPENED + 1; WINDOWS[name] = WINDOWS[name] or ""
  if area ~= nil then DOCKED_TO = area end
end
function setUserWindowTitle() end
function clearWindow(name) WINDOWS[name] = "" end
function hideWindow() HIDDEN = HIDDEN + 1 end
local COLUMNS, WRAP = nil, nil
function getColumnCount(name)
  if COLUMNS == nil then error("getColumnCount: bad argument #1 type (window name \"" .. tostring(name) .. "\" not found)") end
  return COLUMNS
end
function setWindowWrap(name, n) if name == AchaeaTalismans.WINDOW then WRAP = n end end
function getMudletHomeDir() return "/profile" end
function getEpoch() return CLOCK end
io.exists = function() return STORED ~= nil or RAISE_ON_LOAD end
table.load = function(_, into)
  if RAISE_ON_LOAD then error("unexpected symbol") end
  for key, value in pairs(STORED) do into[key] = value end
end
-- Mudlet's table.save returns nil and a message when it cannot open the
-- file; it does not raise. The stub does the same.
table.save = function(_, t)
  if SAVE_FAILS then return nil, "Permission denied" end
  SAVED = {}
  for key, value in pairs(t) do SAVED[key] = value end
end
os.rename = function() return true end
local seq = 0
function tempRegexTrigger(re, fn) seq = seq + 1; TRIGGERS[seq] = { re = re, fn = fn }; return seq end
function killTrigger(id) TRIGGERS[id] = nil end
function tempTimer(delay, fn)
  assert(type(delay) == "number" and delay >= 0 and delay < 86400)
  seq = seq + 1; TIMERS[seq] = fn; return seq
end
function killTimer(id) TIMERS[id] = nil end
function registerAnonymousEventHandler(event, fn) seq = seq + 1; HANDLERS[seq] = { event = event, fn = fn }; return seq end
function killAnonymousEventHandler(id) HANDLERS[id] = nil end

local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local function raise(event, ...)
  for _, h in pairs(HANDLERS) do if h.event == event then h.fn(event, ...) end end
end
local function fireTimers()
  local due = TIMERS
  TIMERS = {}
  for _, fn in pairs(due) do fn() end
end

-- What the live trigger does with a line: its pattern is "^", so every line.
local function game(text)
  for l in (text .. "\n"):gmatch("(.-)\n") do
    for _, t in pairs(TRIGGERS) do
      assert(t.re == "^", "the one trigger matches every line")
      line = l
      t.fn()
    end
  end
end

local passed = 0
local function check(cond, what)
  if not cond then error("FAIL: " .. what, 2) end
  passed = passed + 1
end

local function load() assert(loadfile(HERE .. "/AchaeaTalismans.lua"))() end

-- ------------------------------------------------------------- the listings

-- A prompt in the game's shape, with made-up vitals: the package never reads it.
local PROMPT = "H:1000|100% M:1000|100% E:4000|100% W:4000|100% "

-- TALISMAN PIECES in the game's layout, column for column, with the pager in
-- each of the three places it was seen to break (prompt then `more`; `more`
-- typed twice; straight after a heading). The rows are a made-up collection,
-- not anyone's: the layout is what is under test, and every case the parser
-- meets is kept: all three sources, a count above 1, a name cut by its
-- column, a keyword unlike its talisman's, a level-4 piece for a level-3 slot.
local PIECES = table.concat({
  PROMPT .. "talisman pieces",
  "Num   Name                              Level Set        Keyword                  ",
  "----------------------------------------------------------------------------------",
  "      blackdragonpieces",
  "B 1   a Black Dragon's heart            1     Dragon     blackdragonheart",
  "B 2   a Black Dragon's scale            2     Dragon     blackdragonscale",
  "B 1   Black Dragon leather              1     Dragon     blackdragonleather",
  "      golddragonpieces",
  "B 3   a Gold Dragon's eye               1     Dragon     golddragoneye",
  "      silverdragonpieces",
  "B 2   a Silver Dragon's claw            1     Dragon     silverdragonclaw",
  "[Type MORE if you wish to continue reading. (30% shown)]",
  PROMPT,
  PROMPT .. "more",
  "[File continued via MORE]",
  "B 1   a Silver Dragon's claw            2     Dragon     silverdragonclaw",
  "B 1   a Silver Dragon's claw            3     Dragon     silverdragonclaw",
  "B 1   a Silver Dragon's scale           4     Dragon     silverdragonscale",
  "B 1   a Silver Dragon bone              3     Dragon     silverdragonbone",
  "      greendragonpieces",
  "B 1   a Green Dragon's tooth            1     Dragon     greendragontooth",
  "      reddragonpieces",
  "B 1   a Red Dragon's claw               2     Dragon     reddragonclaw",
  "B 1   a Red Dragon's claw               3     Dragon     reddragonclaw",
  "B 1   a Red Dragon's claw               5     Dragon     reddragonclaw",
  "[Type MORE if you wish to continue reading. (60% shown)]",
  PROMPT .. "more",
  "more",
  "[File continued via MORE]",
  "      cloverboxpieces",
  "Q 1   the sides from a cargo crate of c 1     Seafaring  cloverboxsides",
  "      icossemirrorpieces",
  "F 1   A golden mirror frame             2     forays     goldmirrorframe",
  "F 1   A cursed piece of glass           1     forays     mirrorcurse",
  "      ogrebrothpieces",
  "[Type MORE if you wish to continue reading. (85% shown)]",
  PROMPT,
  "[File continued via MORE]",
  "F 2   Some special ogre spices          1     forays     brothspice",
  "      sanityskeinpieces",
  "B 1   The thread for a skein of sanity  1     underworld sanityskeinthread",
  "----------------------------------------------------------------------------------",
  PROMPT,
}, "\n")

-- PIECES <talisman>'s own layout, for the same made-up silver rows.
local TPIECES_SILVER = table.concat({
  PROMPT .. "talisman pieces silverdragon",
  "    Num Name                             Level Set       Keyword                  ",
  "----------------------------------------------------------------------------------",
  "  B (2) a Silver Dragon's claw           1     dragon    silverdragonclaw",
  "  B (1) a Silver Dragon's claw           2     dragon    silverdragonclaw",
  "  B (1) a Silver Dragon's claw           3     dragon    silverdragonclaw",
  "  B (1) a Silver Dragon's scale          4     dragon    silverdragonscale",
  "  B (1) a Silver Dragon bone             3     dragon    silverdragonbone",
  "----------------------------------------------------------------------------------",
  PROMPT,
}, "\n")

local SETS_ROWS = {
  "Dragon                                        0/6       dragon",
  "Azatlan                                       0/7       azatlan",
  "Wonders                                       0/6       wonders",
  "Miscellaneous                                 0/4       misc",
  "Historical                                    0/12      historical",
  "Conclave                                      0/12      conclave",
  "Marks                                         0/19      marks",
  "Seafaring                                     0/15      seafaring",
  "death                                         0/8       death",
  "blackwave                                     0/13      blackwave",
  "races                                         0/16      races",
  "forays                                        0/6       forays",
  "cities                                        0/6       cities",
  "monks                                         0/8       monks",
  "elemental                                     1/12      elemental",
  "yggdrasil                                     0/11      yggdrasil",
  "contenders                                    0/8       contenders",
  "underworld                                    0/8       underworld",
  "renegades                                     0/8       renegades",
  "invasion                                      0/8       invasion",
  "war                                           0/6       war",
  "planes                                        0/10      planes",
  "eldergods                                     0/9       eldergods",
  "moderngods                                    0/9       moderngods",
  "logosmas                                      0/8       logosmas",
  "memory                                        0/7       memory",
  "wanderer                                      0/9       wanderer",
  "scholars                                      0/9       scholars",
  "empires                                       0/12      empires",
}
local SETS_HEAD = "Name                                          Status    Keyword             "
local RULE79 = "-------------------------------------------------------------------------------"

local function setsTable(breakAfter, percent)
  local out = { SETS_HEAD, RULE79 }
  for i, row in ipairs(SETS_ROWS) do
    out[#out + 1] = row
    if i == breakAfter then
      out[#out + 1] = "[Type MORE if you wish to continue reading. (" .. percent .. "% shown)]"
      out[#out + 1] = PROMPT .. "more"
      out[#out + 1] = "[File continued via MORE]"
    end
  end
  out[#out + 1] = RULE79
  return table.concat(out, "\n")
end

local SETS = PROMPT .. "talisman sets\n" .. setsTable(18, 63) .. "\n" .. PROMPT

local LIST = table.concat({
  PROMPT .. "talisman list",
  "Name                                          Set       Keyword             ",
  RULE79,
  "a miniature Air Elemental                     elemental airelemental",
  RULE79,
  "",
  "Name                                          Set       Keyword             ",
  RULE79,
  "a miniature Air Elemental                     elemental airelemental",
  RULE79,
  "",
  setsTable(8, 48),
  "",
  "You have no incomplete talismans to show.",
  PROMPT,
}, "\n")

local SET_DRAGON = table.concat({
  PROMPT .. "talisman set dragon",
  "Name: Dragon",
  "Partial name: dragon",
  "Description: A set of Talismans that, when collected, grant the owner increased mastery over Dragonform.",
  "Talismans:",
  "a Black Dragon Talisman (blackdragon)",
  "a Gold Dragon Talisman (golddragon)",
  "a Blue Dragon Talisman (bluedragon)",
  "a Silver Dragon Talisman (silverdragon)",
  "a Green Dragon Talisman (greendragon)",
  "a Red Dragon Talisman (reddragon)",
  PROMPT,
}, "\n")

local INFO_RED = table.concat({
  PROMPT .. "talisman info reddragon",
  "Name: a Red Dragon Talisman",
  "Keyword: reddragon",
  "Brief: The power to change into a Red Dragon",
  "Pieces:",
  "(1) a Red Dragon's claw (reddragonclaw), level 7",
  "(1) a Red Dragon's heart (reddragonheart), level 7",
  "(1) a Red Dragon's tooth (reddragontooth), level 7",
  "(1) a Red Dragon's scale (reddragonscale), level 7",
  "(1) Red Dragon leather (reddragonleather), level 7",
  "(1) a Red Dragon bone (reddragonbone), level 7",
  "(1) a Red Dragon's eye (reddragoneye), level 7",
  "(1) a Red Dragon's belly (reddragonbelly), level 3",
  "Set: Dragon",
  PROMPT,
}, "\n")

-- 2026-10-15: a Brief and a piece that both wrap at 80 columns.
local INFO_HARNESS = table.concat({
  PROMPT .. "talisman info harness",
  "Name: a stratospheric harness",
  "Keyword: harness",
  "Brief: SHAKE <harness> when in an associated region and of sound body in order",
  "  to capture the far flung windstreams, these immense forces will allow you to",
  "  travel to nearby isles. Western windstream encompasses Tuar, Tapoa, and",
  "  Ageiro. Eastern windstream encompasses Zanzibaar, Clockwork, Colchis, and",
  "  Umbrin. Northern windstream encompasses Karbaz, Suliel, and Ilyrean. Note",
  "  that you must be on one of these islands to reach the windstreams.",
  "Pieces:",
  "(1) The straps for a stratospheric harness (airharnessstraps), level 1",
  "(1) The glyphs for a stratospheric harness (airharnessglyphs), level 1",
  "(1) The enchantment for a stratospheric harness (airharnessenchantment), level",
  "  1",
  "(1) The buckles for a stratospheric harness (airharnessbuckles), level 1",
  "Set: elemental",
  PROMPT,
}, "\n")

-- ------------------------------------------------------------ a fresh start

load()
local M = AchaeaTalismans
check(count(TRIGGERS) == 1, "one trigger")
check(OPENED >= 1 and WINDOWS[M.WINDOW] ~= nil, "a fresh install opens its window")
check(WINDOWS[M.WINDOW]:find("No pieces read yet", 1, true), "an empty window says what to do")
check(#SENT == 0, "installing sends nothing")

-- A recompile replaces the trigger rather than adding a second.
load()
M = AchaeaTalismans
check(count(TRIGGERS) == 1, "still one trigger after a recompile")

-- ---------------------------------------------------------------- PIECES

game(PIECES)
local held = M.data.held
check(#held == 18, "18 rows read across three page breaks, got " .. #held)
check(#SENT == 0, "reading pieces the player typed sends nothing, MORE included")
check(held[1].kw == "blackdragonheart" and held[1].group == "blackdragon" and held[1].source == "B",
      "the first row, under its heading")
check(held[4].kw == "golddragoneye" and held[4].count == 3, "the count is the second field")
local bySide
for _, r in ipairs(held) do if r.kw == "cloverboxsides" then bySide = r end end
check(bySide.name == "the sides from a cargo crate of c" and bySide.source == "Q",
      "a name cut by the column is kept as printed")
local mirror
for _, r in ipairs(held) do if r.kw == "mirrorcurse" then mirror = r end end
check(mirror.group == "icossemirror", "a piece keyword unlike its talisman's keeps its heading")
check(held[#held].set == "underworld" and held[#held].group == "sanityskein", "the last row")
check(M.data.heldAt > 0, "when it was read")
check(SAVED and #SAVED.held == 18, "what was read is saved")

check(M.units(1) == 1 and M.units(3) == 4 and M.units(7) == 64, "a level is a doubling")
check(M.heldUnits("silverdragonclaw") == 2 + 2 + 4, "every level of a keyword counts")
check(M.heldUnits("reddragonclaw") == 2 + 4 + 16, "2, 3 and 5 are 22 level-1 pieces")
check(#M.heldTalismans() == 9, "nine talismans held, got " .. #M.heldTalismans())

-- Before INFO, a talisman shows only what is held.
check(M.progress("reddragon") == nil, "no progress without INFO")
-- The pieces held are folded to one line until asked for.
check(M.data.piecesOpen == false and not WINDOWS[M.WINDOW]:find("needs not read", 1, true),
      "the pieces held are folded by default")
check(WINDOWS[M.WINDOW]:find("▸ <white>Pieces you hold", 1, true) and WINDOWS[M.WINDOW]:find(" of 9 talismans", 1, true),
      "to a line that says how many")
local fold = false
for _, l in ipairs(LINKS) do
  if l.win == M.WINDOW and l.code == "AchaeaTalismans.togglePieces()" then fold = true end
end
check(fold, "which is a link")
check(M.togglePieces() == true and SAVED.piecesOpen == true, "a click lists them, and it is kept")
check(WINDOWS[M.WINDOW]:find("▾ <white>Pieces you hold", 1, true), "the arrow turns")
check(WINDOWS[M.WINDOW]:find("needs not read", 1, true), "the window says what is missing")

-- ------------------------------------------------------------------ INFO

game(INFO_RED)
local red = M.data.talismans.reddragon
check(red and red.name == "a Red Dragon Talisman" and red.set == "Dragon", "INFO read")
check(#red.pieces == 8 and red.pieces[8].kw == "reddragonbelly" and red.pieces[8].level == 3,
      "eight pieces, the belly at level 3")
check(red.brief == "The power to change into a Red Dragon", "the brief")
local p = M.progress("reddragon")
check(p.need == 7 * 64 + 4 and p.have == 22 and p.ready == 0, "22 of 452")
check(p.slots[1].label == "claw" and p.slots[1].have == 22 and p.slots[1].need == 64, "the claw slot")
check(M.status("reddragon") == "started", "started")

game(INFO_HARNESS)
local harness = M.data.talismans.harness
check(harness and #harness.pieces == 4, "a wrapped piece is joined to its line")
check(harness.pieces[3].kw == "airharnessenchantment" and harness.pieces[3].level == 1, "the wrapped one")
check(harness.brief:find("^SHAKE <harness>") and harness.brief:find("reach the windstreams%.$"),
      "a wrapped brief is joined")
check(harness.set == "elemental", "its set")
check(M.status("harness") == "none", "no harness piece held")

-- A piece held above the level asked for fills the slot: split it down.
M.data.talismans.test = { name = "t", pieces = { { kw = "silverdragonscale", level = 3, count = 1 } } }
check(M.progress("test").ready == 1 and M.progress("test").have == 4, "a level-4 piece covers a level-3 slot, counted at 4")
M.data.talismans.test = nil

-- ------------------------------------------------------------------- SETS

game(SETS)
check(#M.data.setOrder == 29, "29 sets, got " .. #M.data.setOrder)
check(M.data.sets.elemental.done == 1 and M.data.sets.elemental.total == 12, "elemental 1/12")
check(M.data.sets.misc.name == "Miscellaneous", "a name unlike its keyword")
check(M.setKey("Miscellaneous") == "misc" and M.setKey("Dragon") == "dragon", "a set by its name")

game(SET_DRAGON)
local dragon = M.data.sets.dragon
check(#dragon.talismans == 6 and dragon.talismans[6].kw == "reddragon", "six talismans")
check(dragon.total == 6, "SET keeps what SETS said")
check(dragon.description:find("mastery over Dragonform%.$"), "an unwrapped description")
check(M.data.setOrder[1] == "dragon" and #M.data.setOrder == 29, "a known set is not added twice")

-- ------------------------------------------------------------------- LIST

M.data.sets.elemental.done = 0
-- A tell arriving mid-table is three words and more, and is not a row.
game((LIST:gsub("(elemental airelemental\n)", '%1Somebody tells you, "hello there friend"\n', 1)))
check(M.data.completed.airelemental and M.data.completed.airelemental.name == "a miniature Air Elemental",
      "the air elemental is done")
check(count(M.data.completed) == 1, "and nothing else, the tell included")
check(M.data.sets.elemental.done == 1, "the sets table inside LIST is read too")
check(M.status("airelemental") == "done", "done")
-- A talisman table after the sets table, where the incomplete ones go, or
-- one on its own, is not taken as done: nothing says what it lists.
game(LIST:gsub("\nYou have no incomplete talismans to show%.",
  "\nName                                          Set       Keyword             \n" .. RULE79 ..
  "\nthe tears of the Sea                          elemental seatears\n" .. RULE79))
check(not M.data.completed.seatears, "a talisman table after the sets is not done")
game(SETS)
check(not M.data.completed.seatears, "nor once a later SETS arrives")

-- -------------------------------------------------- PIECES for one talisman

-- Pretend the silver claws were combined since: fewer rows, read in place.
local before = #M.data.held
game((TPIECES_SILVER:gsub("  B %(1%) a Silver Dragon's claw           3     dragon    silverdragonclaw\n", "")))
check(#M.data.held == before - 1, "one talisman's rows replace only its own")
check(M.heldUnits("silverdragonclaw") == 4, "the claws now sum to 4")
check(M.data.held[5].kw == "silverdragonclaw" and M.data.held[5].group == "silverdragon",
      "the new rows sit where the old ones were, with their talisman")
check(M.heldUnits("reddragonclaw") == 22, "other talismans untouched")
game(TPIECES_SILVER)
check(#M.data.held == before and M.heldUnits("silverdragonclaw") == 8, "and back")

-- --------------------------------------------------------------- the window

M.setFocus("")
local w = WINDOWS[M.WINDOW]
check(w:find("a Red Dragon Talisman", 1, true) and w:find("0/8 ready, 4%", 1, true), "the red dragon's line")
check(w:find("22/64", 1, true), "the claw's count")
check(w:find("Miscellaneous", 1, true), "the sets are listed")
check(not w:find("stratospheric", 1, true), "a talisman with nothing held is not in the all view")
M.setFocus("Dragon")
w = WINDOWS[M.WINDOW]
check(M.data.focus == "dragon" and w:find("0/6 done", 1, true), "one set")
check(w:find("(golddragon)", 1, true) and w:find("needs not read", 1, true), "its talismans, read or not")
check(not w:find("Sets", 1, true) and not w:find("Miscellaneous", 1, true), "and nothing else: no sets list under them")
local back = false
for _, l in ipairs(LINKS) do
  if l.win == M.WINDOW and l.text:find("[back to sets]", 1, true) and l.code == "AchaeaTalismans.setFocus('')" then back = true end
end
check(back, "a link goes back to the sets")
local foundLink = false
for _, l in ipairs(LINKS) do
  if l.win == M.WINDOW and l.code == 'AchaeaTalismans.setFocus("misc")' then foundLink = true end
end
check(foundLink, "a set's name is a link to it")
M.setFocus("")
check(WINDOWS[M.WINDOW]:find("Miscellaneous", 1, true) and not WINDOWS[M.WINDOW]:find("[back to sets]", 1, true),
      "back, the sets are listed again")
-- Given an area, openUserWindow re-docks a window that exists, so a click on
-- a set name would pull a floated window back into the right dock.
check(DOCKED_TO == nil, "the window is never told where to dock")

-- The layout: as many columns as fit the window, none of them past its edge.
local function shown(width)
  local t = {}
  for _, p in ipairs(M.render(width)) do t[#t + 1] = type(p) == "table" and p[1] or p end
  return table.concat(t)
end
local function lines(text)
  local out = {}
  for l in (text .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l end
  return out
end
local function sideBySide(text, a, b)
  for _, l in ipairs(lines(text)) do
    if l:find(a, 1, true) and l:find(b, 1, true) then return true end
  end
  return false
end
check(M.textWidth("<green>██<dim_grey>░░ <reset>2/4") == 8, "a bar's width is its columns, not its bytes")
for _, width in ipairs({ 60, 120, 200 }) do
  local widest = 0
  for _, l in ipairs(lines(shown(width))) do widest = math.max(widest, M.textWidth(l)) end
  check(widest <= width, "nothing drawn at " .. width .. " columns is wider, got " .. widest)
end
check(not sideBySide(shown(60), "(blackdragon)", "(silverdragon)"), "a narrow window has one column of talismans")
check(sideBySide(shown(60), "Dragon ", "yggdrasil"), "and two of sets")
check(sideBySide(shown(200), "(blackdragon)", "(silverdragon)"), "a wide one has several of talismans")
check(#lines(shown(200)) < #lines(shown(60)) / 2, "and is less than half as tall")
check(not shown(80):find(" \n"), "no line ends in padding")
check(shown(1):find("22/64", 1, true), "a window narrower than anything is one column")
check(#M.layout({}, 80, 1) == 0, "nothing to lay out is no columns")

-- Exact layouts, so a gap, a padding or a fit off by one shows. A at two
-- lines, B and C at one; with sep 1 they stack A | B | C at height 2 (4 + 6
-- + 2 wide, plus two gaps of 3: 18), or A | B, C at height 3 (4 + 6 + 3: 13).
local function L(s) return { s, w = M.textWidth(s) } end
local ABC = { { L("aaaa"), L("aa") }, { L("bbbbbb") }, { L("cc") } }
local function laid(width, sep)
  local out = {}
  M.emit(out, M.layout(ABC, width, sep))
  return (table.concat(out):gsub("<[%w_,:]+>", ""))
end
check(laid(18, 1) == "aaaa   bbbbbb   cc\naa\n", "a layout exactly as wide as the window fits: " .. laid(18, 1))
check(laid(17, 1) == "aaaa   bbbbbb\naa\n       cc\n", "one column less, and C goes under B: " .. laid(17, 1))
check(laid(17, 0) == "aaaa   bbbbbb\naa     cc\n", "with no sep, C sits right under B: " .. laid(17, 0))
check(laid(9, 1) == "aaaa\naa\n\nbbbbbb\n\ncc\n", "a window narrower than two columns is one: " .. laid(9, 1))
check(#M.layout({ { L(string.rep("x", 50)) }, { L("y") } }, 20, 0) == 1, "a block wider than the window is one column")

-- The README's example rows, as drawn: labels padded to the longest in the
-- talisman (leather, of the eight), a 10-cell bar, 22 of 64 filling three.
local plain = shown(80):gsub("<[%w_,:]+>", "")
check(plain:find("\n  claw    L7 ███░░░░░░░ 22/64", 1, true) and plain:find("\n  heart   L7 ░░░░░░░░░░ 0/64", 1, true),
      "the README's rows are what is drawn")
local readme = assert(io.open(HERE .. "/README.md")):read("*a")
check(readme:find("  claw    L7 ███░░░░░░░ 22/64", 1, true), "and the README shows them")

-- The window is measured, given a wrap to match, and laid out again when it
-- is resized to a different width, once the drag has settled.
COLUMNS = 61
M.redraw()
check(WRAP == 60 and not sideBySide(WINDOWS[M.WINDOW], "(blackdragon)", "(silverdragon)"),
      "the window is drawn to its measured width, one column off")
COLUMNS = 201
raise("sysUserWindowResizeEvent", 1600, 400, "SomeOtherWindow")
fireTimers()
check(WRAP == 60, "another window's resize is not ours")
raise("sysUserWindowResizeEvent", 1500, 400, M.WINDOW)
raise("sysUserWindowResizeEvent", 1600, 400, M.WINDOW)
check(count(TIMERS) == 1, "a drag is waited out with one timer")
fireTimers()
check(WRAP == 200 and sideBySide(WINDOWS[M.WINDOW], "(blackdragon)", "(silverdragon)"), "and laid out again")
local drawn = #LINKS
raise("sysUserWindowResizeEvent", 1600, 401, M.WINDOW)
fireTimers()
check(#LINKS == drawn, "a resize to the same width is not redrawn")
COLUMNS = nil
M.redraw()
check(WRAP == M.DEFAULT_WIDTH, "a window that cannot be measured gets the default")

-- Every link's code must compile, since Mudlet runs it as a string.
for _, l in ipairs(LINKS) do
  check(loadstring(l.code), "link code compiles: " .. l.code)
end

M.show(false)
check(HIDDEN >= 1 and M.data.shown == false, "hide")
local n = #LINKS
game(INFO_RED)
check(#LINKS == n, "a hidden window is not drawn")
M.show(true)

-- ------------------------------------------------------- what is left alone

-- A help scroll's underlined heading is not a table's rule.
game(PROMPT .. "help talismans\nPieces\n------\nEach Talisman is composed of two or more Pieces")
check(M.state.cap == nil, "nothing is being read")
-- A MORE outside any listing sends nothing, scan or not.
SENT = {}
game("[Type MORE if you wish to continue reading. (19% shown)]")
check(#SENT == 0, "a stranger's MORE is not answered")
-- A paged table abandoned for another listing is dropped, not committed.
local heldNow = #M.data.held
game("Num   Name                              Level Set        Keyword\n" ..
     "----------------------------------------------------------------------------------\n" ..
     "      reddragonpieces\n" ..
     "B 1   a Red Dragon's claw               1     Dragon     reddragonclaw\n" ..
     "[Type MORE if you wish to continue reading. (28% shown)]\n" .. PROMPT)
check(M.state.cap and M.state.cap.paused, "paged")
game(INFO_RED)
check(#M.data.held == heldNow, "the unfinished table did not replace what was held")
check(M.state.cap == nil, "and the INFO was read in its place")
-- A paged table left too long is let go at the next MORE it hears.
game("Num   Name                              Level Set        Keyword\n" ..
     "----------------------------------------------------------------------------------\n" ..
     "[Type MORE if you wish to continue reading. (28% shown)]")
CLOCK = CLOCK + M.PAUSE_MAX + 1
game("[File continued via MORE]\n----------------------------------------------------------------------------------")
check(M.state.cap == nil and #M.data.held == heldNow, "a stale page is not finished by someone else's")

-- --------------------------------------------------------------------- scan

SENT = {}
M.data.talismans = { reddragon = M.data.talismans.reddragon }
M.scan()
check(SENT[1] == "talisman list" and #SENT == 1, "a scan starts with LIST")
game(LIST)
check(SENT[2] == "more", "a scan answers the pager for its own listing")
check(SENT[3] == "talisman pieces", "then PIECES, once LIST's sets table is read")
game(PIECES)
check(SENT[4] == "more" and SENT[5] == "more" and SENT[6] == "more", "three pages")
check(SENT[7] == "talisman info blackdragon", "then INFO for the first talisman held and not read")
game(INFO_RED)   -- not the one asked for: the scan keeps waiting
check(#SENT == 7, "an answer to something else does not move the scan on")
fireTimers()
check(SENT[8] == "talisman info golddragon", "a step not answered in time is skipped")
local infos = 0
for _, c in ipairs(SENT) do if c:find("^talisman info ") then infos = infos + 1 end end
check(M.stopScan(true) and M.state.scan == nil, "stop")
fireTimers()
check(#SENT == 8, "a stopped scan sends nothing more")

SENT = {}
M.scan("dragon")
check(SENT[1] == "talisman set dragon", "a set scan starts with SET")
game(SET_DRAGON)
check(SENT[2] == "talisman info blackdragon", "then INFO for each of its talismans")
check(M.data.focus == "dragon", "and the window turns to it")
M.stopScan(true)

-- ------------------------------------------- what review found, held down

local PAGED_HEAD = "Num   Name                              Level Set        Keyword\n" ..
  "----------------------------------------------------------------------------------\n" ..
  "      reddragonpieces\n" ..
  "B 1   a Red Dragon's claw               1     Dragon     reddragonclaw\n" ..
  "[Type MORE if you wish to continue reading. (28% shown)]\n" .. PROMPT

-- A paged table left unread, then a help scroll that pages and is read on:
-- the scroll's MORE is a second page break, and its lines are not the table's.
heldNow = #M.data.held
game(PAGED_HEAD)
check(M.state.cap and M.state.cap.paused, "a table waits on its page")
game(PROMPT .. "help talismans\n19.24 Talismans\n[Type MORE if you wish to continue reading. (19% shown)]")
check(M.state.cap == nil, "another page break lets the waiting table go")
game(PROMPT .. "more\n[File continued via MORE]\n" ..
     "----------------------------------------------------------------------------------\n" .. PROMPT)
check(#M.data.held == heldNow, "the scroll did not finish the table, nor replace what was held")

-- A run of dashes of another length does not close a table.
game("Num   Name                              Level Set        Keyword\n" ..
     "----------------------------------------------------------------------------------\n" ..
     "      reddragonpieces\n" ..
     "B 1   a Red Dragon's claw               1     Dragon     reddragonclaw\n" ..
     "-------------------------------------------------------------------------------")
check(M.state.cap and M.state.cap.kind == "pieces", "a 79-dash line inside an 82-dash table is not its end")
-- A tell in the middle of a table is not a row.
-- The second is shaped like a row, so only the column check stops it.
game('Somebody tells you, "1 2 3 four five 6 seven"\n' ..
     'B 1   Somebody says, "count 3 dragon pieces"\n' ..
     "----------------------------------------------------------------------------------")
check(#M.data.held == 1 and M.data.held[1].kw == "reddragonclaw", "only the real row was read")
game(PIECES)
check(#M.data.held == 18, "and the full listing puts it back")

-- A scan answers only the pager of a listing it is waiting for.
game(PAGED_HEAD)
M.scan()
check(M.state.cap == nil, "a scan lets go of a half-read listing")
SENT = {}
game(PROMPT .. "help talismans\n19.24 Talismans\n[Type MORE if you wish to continue reading. (19% shown)]")
check(#SENT == 0, "a help scroll paged mid-scan is not answered")
game(PROMPT .. "more\n[File continued via MORE]\n" .. PROMPT)
M.stopScan(true)

-- One talisman's pieces read before anything else: the command says whose.
AchaeaTalismans, TRIGGERS, HANDLERS = nil, {}, {}
load()
M = AchaeaTalismans
raise("sysDataSendRequest", "TALISMAN PIECES silverdragon")
game(TPIECES_SILVER)
check(#M.heldTalismans() == 1 and M.heldTalismans()[1] == "silverdragon", "the typed command names them")
check(M.data.heldAt > 0, "and the time they were read is kept")
CLOCK = CLOCK + M.ASKED_FOR + 1
M.data.held = {}
game(TPIECES_SILVER)
check(#M.heldTalismans() == 0 and #M.data.held == 5, "too late to tell whose, kept anyway")
check(WINDOWS[M.WINDOW]:find("Pieces you hold  <dim_grey>6 pieces\n", 1, true) and
      not WINDOWS[M.WINDOW]:find("Pieces of no known talisman", 1, true),
      "folded, with no talisman to count, got: " .. WINDOWS[M.WINDOW]:sub(1, 300))
M.togglePieces()
check(WINDOWS[M.WINDOW]:find("Pieces of no known talisman", 1, true), "and shown")

-- TALISMAN SET before SETS: stored under the keyword SET printed, then taken
-- over by SETS's own keyword for the same set.
game(PROMPT .. "talisman set misc\nName: Miscellaneous\nPartial name: miscellaneous\n" ..
     "Description: Talismans that fit nowhere else.\nTalismans:\na ball of yarn (yarn)\n" .. PROMPT)
check(M.data.sets.miscellaneous and #M.data.sets.miscellaneous.talismans == 1, "kept under what SET said")
check(WINDOWS[M.WINDOW]:find("Miscellaneous%s+<dim_grey>%?"), "no counts shown before SETS gives them")
game(SETS)
check(M.data.sets.misc.talismans and M.data.sets.miscellaneous == nil, "SETS takes it over as misc")

-- The window opens once; a redraw after it was closed does not reopen it.
local opened = OPENED
game(INFO_RED)
check(OPENED == opened, "reading something does not reopen the window")
M.show(true)
check(OPENED == opened + 1, "asking for it does")

-- A keyword with a quote in it cannot break, or run, a link's code.
M.data.sets["o'brien"] = { name = "O'Brien", done = 0, total = 1 }
M.data.setOrder[#M.data.setOrder + 1] = "o'brien"
M.setFocus("o'brien")
for _, l in ipairs(LINKS) do
  check(loadstring(l.code), "link code compiles: " .. l.code)
end
M.data.sets["o'brien"] = nil
table.remove(M.data.setOrder)
M.setFocus("")

-- `tals` with words no alias answers to says so; the real ones stay quiet.
ECHOED = {}
check(M.unknown("scan dragon") and M.unknown("diag") and M.unknown("set dragon"), "real commands pass")
check(#ECHOED == 0, "quietly")
check(M.unknown("foo") == false and M.unknown("set") == false and M.unknown("diag now") == false,
      "anything else is caught")
check(#ECHOED == 3, "and said")

-- ------------------------------------------- the second review, held down

-- A scan answers a page break between two tables of the output it waits on.
SENT = {}
M.scan()
check(SENT[1] == "talisman list", "the scan starts")
-- A plain find: the rule is all dashes, which a Lua pattern would misread.
local at = select(2, LIST:find("elemental airelemental\n" .. RULE79 .. "\n", 1, true))
check(at, "the first table's end is found")
local broken = LIST:sub(1, at) ..
  "[Type MORE if you wish to continue reading. (12% shown)]\n" .. PROMPT .. "more\n[File continued via MORE]\n" ..
  LIST:sub(at + 1)
check(broken:find("(12% shown)", 1, true), "the break is in")
game(broken)
check(table.concat(SENT, ",") == "talisman list,more,more,talisman pieces",
      "both breaks answered, the one between LIST's tables and the one in its sets table, then the scan goes on")
M.stopScan(true)

-- A set name wider than its column pushes the keyword right; the row is kept.
game(table.concat({
  "Num   Name                              Level Set        Keyword                  ",
  "----------------------------------------------------------------------------------",
  "      yarnballpieces",
  "B 1   a strand of yarn                  1     Miscellaneous yarnstrand",
  "----------------------------------------------------------------------------------",
}, "\n"))
check(#M.data.held == 1 and M.data.held[1].kw == "yarnstrand" and M.data.held[1].set == "Miscellaneous",
      "a keyword pushed past its column is still read")
game(PIECES)

-- `TALISMAN PIECES <t>` with the talisman cut short, or typed in short.
M.data.held = {}
M.data.talismans.silverdragon = { name = "a Silver Dragon Talisman", pieces = {} }
raise("sysDataSendRequest", "tal pieces silver")
game(TPIECES_SILVER)
check(M.data.held[1].group == "silverdragon", "a short keyword resolves to the one it starts")
M.data.held = {}
M.data.talismans.silverbell = { name = "a silver bell", pieces = {} }
raise("sysDataSendRequest", "talisman pieces silver")
game(TPIECES_SILVER)
check(M.data.held[1].group == nil, "one that could be two is not guessed")
M.data.talismans.silverbell, M.data.talismans.silverdragon = nil, nil
game(PIECES)

-- `tals` commands are case-sensitive, and only the real forms pass.
ECHOED = {}
for _, rest in ipairs({ "SCAN", "Show", "scan a b", "set a b", "scan ", "diag now", "set" }) do
  check(M.unknown(rest) == false, "not a command: tals " .. rest)
end
check(#ECHOED == 7, "and each one said so")
ECHOED = {}
for _, rest in ipairs({ "show", "hide", "all", "set dragon", "set Dragon", "scan", "scan dragon", "stop", "diag" }) do
  check(M.unknown(rest) == true, "a command: tals " .. rest)
end
check(#ECHOED == 0, "quietly")

-- M.FORMS is build.py's aliases, translated.
do
  local src = assert(io.open(HERE .. "/build.py")):read("*a")
  local forms = {}
  for re in src:gmatch('r"%^tals\\s%+([^"]+)"') do
    if re ~= "(.*)$" then
      local alts = re:match("^%(([%w|]+)%)%$$")
      local list = {}
      if alts then for a in alts:gmatch("[^|]+") do list[#list + 1] = a .. "$" end else list[1] = re end
      for _, f in ipairs(list) do
        f = f:gsub("%(\\S%+%)", "%%S+"):gsub("\\s%+", "%%s+"):gsub("\\S%+", "%%S+")
        forms["^" .. f] = true
      end
    end
  end
  local have = {}
  for _, f in ipairs(M.FORMS) do have[f] = true end
  for f in pairs(forms) do check(have[f], "M.FORMS has build.py's " .. f) end
  for f in pairs(have) do check(forms[f], "build.py has M.FORMS's " .. f) end
end

-- An uninstall and reinstall in one session opens the window again.
M.show(true)
raise("sysUninstall", M.PACKAGE)
local beforeOpen = OPENED
TRIGGERS = {}
load()
M = AchaeaTalismans
check(OPENED == beforeOpen + 1, "the reinstalled copy opens its window")
check(M.state.paging == false and M.state.listed == nil, "and starts with nothing half read")
M.data.completed = {}
game(LIST)
check(M.data.completed.airelemental, "and reads a listing")

-- A recompile keeps the window as the player left it: closed stays closed.
beforeOpen = OPENED
load()
M = AchaeaTalismans
check(OPENED == beforeOpen, "a recompile does not reopen the window")

-- ------------------------------------------- the third review, held down

-- Long lines mid-table are not rows, wherever their last word falls: a
-- quote, a timing tag, or a lower-case word too far past the column.
local NOISE = {
  'Somebody tells you, "I will meet you at the north gate of Antioch tomorrow, ok?"',
  'You say, "I think we should all go to the pub afterwards"',
  '(Market): Somebody says, "Selling a whole pile of these for cheap, tell me"',
  "A mighty griffin soars high above the plains of Meropis. [0.43s]",
  "A mighty griffin soars high above the windswept plains of Meropis and lands nearby",
}
M.data.completed = {}
local at2 = select(2, LIST:find("elemental airelemental\n", 1, true))
game(LIST:sub(1, at2) .. table.concat(NOISE, "\n") .. "\n" .. LIST:sub(at2 + 1))
check(count(M.data.completed) == 1 and M.data.completed.airelemental, "no noise line was taken as a done talisman")
local at3 = select(2, PIECES:find("silverdragonbone\n", 1, true))
game(PIECES:sub(1, at3) .. table.concat(NOISE, "\n") .. "\n" .. PIECES:sub(at3 + 1))
check(#M.data.held == 18, "nor as a held piece")

-- The scan's between-tables MORE is for its own listing only.
SENT = {}
M.scan()
local firstTable = LIST:sub(1, select(2, LIST:find("elemental airelemental\n" .. RULE79 .. "\n", 1, true)))
game(firstTable .. PROMPT .. "help talismans\n19.24 Talismans\n[Type MORE if you wish to continue reading. (19% shown)]")
check(table.concat(SENT, ",") == "talisman list", "a help scroll paged after the scan's table is not answered")
M.stopScan(true)
SENT = {}
M.scan()
game((LIST:gsub("\nYou have no incomplete talismans to show%.", "")) .. "\n[Type MORE if you wish to continue reading. (95% shown)]")
check(SENT[#SENT] == "talisman pieces", "a break after the scan moved on is not answered")
M.stopScan(true)
game(PROMPT .. "more\n[File continued via MORE]\n" .. PROMPT)

-- Only real beginnings of TALISMAN and PIECES name a talisman.
M.state.asked = nil
for _, cmd in ipairs({ "talk pie bob", "tall pies sam", "tale pieces x", "ta pi x" }) do
  raise("sysDataSendRequest", cmd)
  check(M.state.asked == nil, "not a TALISMAN PIECES: " .. cmd)
end
raise("sysDataSendRequest", "tali pie silver")
check(M.state.asked and M.state.asked.kw == "silver", "a real short form is")
M.state.asked = nil

-- --------------------------------------------------------- saving, loading

local saved = SAVED
STORED = {}
for k, v in pairs(saved) do STORED[k] = v end
STORED.focus = 42          -- the wrong type does not come back
STORED.stray = "x"         -- nor a key nobody saves
AchaeaTalismans = nil
TRIGGERS = {}
load()
M = AchaeaTalismans
check(#M.data.held == #saved.held and M.data.sets.dragon, "what was saved comes back")
check(M.data.focus == "" and M.data.stray == nil, "filtered by key and type")

SAVE_FAILS = true
ECHOED = {}
check(M.save() == false, "a failed save says so")
check(table.concat(ECHOED):find("could not write", 1, true), "out loud")
SAVE_FAILS = false

RAISE_ON_LOAD, STORED = true, nil
AchaeaTalismans = nil
TRIGGERS = {}
load()
M = AchaeaTalismans
check(M.state.loaded == "unreadable" and #M.data.held == 0, "an unreadable file starts empty")
RAISE_ON_LOAD, STORED = false, nil

-- -------------------------------------------------------------- uninstall

-- This uninstalls the package, so nothing after it reads a line: a test
-- added below needs load() first.

raise("sysUninstall", "SomethingElse")
check(count(TRIGGERS) == 1, "another package's uninstall is not ours")
raise("sysUninstall", M.PACKAGE)
check(count(TRIGGERS) == 0, "ours stops the trigger")

-- ---------------------------------------------------- build.py agrees

local src = assert(io.open(HERE .. "/build.py")):read("*a")
check(src:match('PACKAGE_NAME = "([^"]+)"') == M.PACKAGE, "build.py names the same package")
local called = 0
for fn in src:gmatch("AchaeaTalismans%.(%w+)%(") do
  check(type(M[fn]) == "function", "an alias calls AchaeaTalismans." .. fn .. ", which exists")
  called = called + 1
end
check(called == 9, "nine aliases call into the package, got " .. called)
check(src:find("22/64", 1, true) and src:find("0/8 ready, 4%", 1, true),
      "the description's example is what the window draws for the capture")

print(("ok: %d checks"):format(passed))
