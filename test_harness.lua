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
function openUserWindow(name) OPENED = OPENED + 1; WINDOWS[name] = WINDOWS[name] or "" end
function setUserWindowTitle() end
function clearWindow(name) WINDOWS[name] = "" end
function hideWindow() HIDDEN = HIDDEN + 1 end
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
  "B 1   a Silver Dragon's claw            2     Dragon     silverdragonclaw",
  "[Type MORE if you wish to continue reading. (30% shown)]",
  PROMPT,
  PROMPT .. "more",
  "[File continued via MORE]",
  "B 2   a Silver Dragon's claw            3     Dragon     silverdragonclaw",
  "B 1   a Silver Dragon's claw            1     Dragon     silverdragonclaw",
  "B 1   a Silver Dragon's scale           4     Dragon     silverdragonscale",
  "B 1   a Silver Dragon bone              2     Dragon     silverdragonbone",
  "      greendragonpieces",
  "B 1   a Green Dragon's tooth            1     Dragon     greendragontooth",
  "      reddragonpieces",
  "B 1   a Red Dragon's claw               1     Dragon     reddragonclaw",
  "B 1   a Red Dragon's claw               2     Dragon     reddragonclaw",
  "B 1   a Red Dragon's claw               4     Dragon     reddragonclaw",
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
  "  B (1) a Silver Dragon's claw           2     dragon    silverdragonclaw",
  "  B (2) a Silver Dragon's claw           3     dragon    silverdragonclaw",
  "  B (1) a Silver Dragon's claw           1     dragon    silverdragonclaw",
  "  B (1) a Silver Dragon's scale          4     dragon    silverdragonscale",
  "  B (1) a Silver Dragon bone             2     dragon    silverdragonbone",
  "----------------------------------------------------------------------------------",
  PROMPT,
}, "\n")

local SETS_ROWS = {
  "Dragon                                        0/6       dragon",
  "Azatlan                                       0/7       azatlan",
  "Wonders                                       0/6       wonders",
  "Miscellaneous                                 0/4       misc",
  "Historical                                    1/12      historical",
  "Conclave                                      0/12      conclave",
  "Marks                                         0/19      marks",
  "Seafaring                                     0/15      seafaring",
  "death                                         0/8       death",
  "blackwave                                     0/13      blackwave",
  "races                                         0/16      races",
  "forays                                        0/6       forays",
  "cities                                        0/6       cities",
  "monks                                         0/8       monks",
  "elemental                                     0/12      elemental",
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
  "a Votive of Rememberance                      Historica votive",
  RULE79,
  "",
  "Name                                          Set       Keyword             ",
  RULE79,
  "a Votive of Rememberance                      Historica votive",
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
check(M.heldUnits("silverdragonclaw") == 2 + 8 + 1, "every level of a keyword counts")
check(M.heldUnits("reddragonclaw") == 1 + 2 + 8, "1, 2 and 4 are 11 level-1 pieces")
check(#M.heldTalismans() == 9, "nine talismans held, got " .. #M.heldTalismans())

-- Before INFO, a talisman shows only what is held.
check(M.progress("reddragon") == nil, "no progress without INFO")
check(WINDOWS[M.WINDOW]:find("needs not read", 1, true), "the window says what is missing")

-- ------------------------------------------------------------------ INFO

game(INFO_RED)
local red = M.data.talismans.reddragon
check(red and red.name == "a Red Dragon Talisman" and red.set == "Dragon", "INFO read")
check(#red.pieces == 8 and red.pieces[8].kw == "reddragonbelly" and red.pieces[8].level == 3,
      "eight pieces, the belly at level 3")
check(red.brief == "The power to change into a Red Dragon", "the brief")
local p = M.progress("reddragon")
check(p.need == 7 * 64 + 4 and p.have == 11 and p.ready == 0, "11 of 452")
check(p.slots[1].label == "claw" and p.slots[1].have == 11 and p.slots[1].need == 64, "the claw slot")
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
check(M.data.sets.historical.done == 1 and M.data.sets.historical.total == 12, "Historical 1/12")
check(M.data.sets.misc.name == "Miscellaneous", "a name unlike its keyword")
check(M.setKey("Miscellaneous") == "misc" and M.setKey("Dragon") == "dragon", "a set by its name")

game(SET_DRAGON)
local dragon = M.data.sets.dragon
check(#dragon.talismans == 6 and dragon.talismans[6].kw == "reddragon", "six talismans")
check(dragon.total == 6, "SET keeps what SETS said")
check(dragon.description:find("mastery over Dragonform%.$"), "an unwrapped description")
check(M.data.setOrder[1] == "dragon" and #M.data.setOrder == 29, "a known set is not added twice")

-- ------------------------------------------------------------------- LIST

M.data.sets.historical.done = 0
game(LIST)
check(M.data.completed.votive and M.data.completed.votive.name == "a Votive of Rememberance", "the votive is done")
check(count(M.data.completed) == 1, "and nothing else")
check(M.data.sets.historical.done == 1, "the sets table inside LIST is read too")
check(M.status("votive") == "done", "done")

-- -------------------------------------------------- PIECES for one talisman

-- Pretend the silver claws were combined since: fewer rows, read in place.
local before = #M.data.held
game(TPIECES_SILVER:gsub("  B %(2%) a Silver Dragon's claw           3     dragon    silverdragonclaw\n", ""))
check(#M.data.held == before - 1, "one talisman's rows replace only its own")
check(M.heldUnits("silverdragonclaw") == 3, "the claws now sum to 3")
check(M.data.held[5].kw == "silverdragonclaw" and M.data.held[5].group == "silverdragon",
      "the new rows sit where the old ones were, with their talisman")
check(M.heldUnits("reddragonclaw") == 11, "other talismans untouched")
game(TPIECES_SILVER)
check(#M.data.held == before and M.heldUnits("silverdragonclaw") == 11, "and back")

-- --------------------------------------------------------------- the window

M.setFocus("")
local w = WINDOWS[M.WINDOW]
check(w:find("a Red Dragon Talisman", 1, true) and w:find("0/8 ready, 2%", 1, true), "the red dragon's line")
check(w:find("11/64", 1, true), "the claw's count")
check(w:find("Miscellaneous", 1, true), "the sets are listed")
check(not w:find("stratospheric", 1, true), "a talisman with nothing held is not in the all view")
M.setFocus("Dragon")
w = WINDOWS[M.WINDOW]
check(M.data.focus == "dragon" and w:find("0/6 done", 1, true), "one set")
check(w:find("(golddragon)", 1, true) and w:find("needs not read", 1, true), "its talismans, read or not")
local foundLink = false
for _, l in ipairs(LINKS) do
  if l.win == M.WINDOW and l.code == "AchaeaTalismans.setFocus('misc')" then foundLink = true end
end
check(foundLink, "a set's name is a link to it")
M.setFocus("")

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
check(SENT[1] == "talisman sets" and #SENT == 1, "a scan starts with SETS")
game(SETS)
check(SENT[2] == "more", "a scan answers the pager for its own listing")
check(SENT[3] == "talisman pieces", "then PIECES, once SETS is read")
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
check(called == 8, "eight aliases call into the package, got " .. called)
check(src:find("11/64", 1, true) and src:find("0/8 ready, 2%", 1, true),
      "the description's example is what the window draws for the capture")

print(("ok: %d checks"):format(passed))
