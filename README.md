# AchaeaTalismans

A [Mudlet](https://www.mudlet.org/) package for [Achaea](https://www.achaea.com/)
that shows how far your talisman pieces get you, in a window beside the game.

It reads what the game prints for `TALISMAN PIECES`, `TALISMAN INFO`,
`TALISMAN SET`, `TALISMAN SETS` and `TALISMAN LIST` whenever you type them,
and draws each talisman's pieces as bars:

```
◐ a Red Dragon Talisman (reddragon)  0/8 ready, 2%
  claw             L7    ██░░░░░░░░░░░░░░ 11/64
  heart            L7    ░░░░░░░░░░░░░░░░ 0/64
```

Below the talismans, the window lists every set with a mark for each of its
talismans: done, started or not started. A set's name is a link to that set.

## How pieces are counted

Two pieces of one level combine into one piece a level up, and one piece
splits into two a level down (`HELP TALISMANS`). So the window counts
everything in level-1 pieces: a level-7 slot needs 64, and every piece of that
keyword you hold counts toward it, whatever its level. In the example above,
claws at levels 1, 2 and 4 are 1 + 2 + 8 = 11 of the 64. A slot is **ready**
once what you hold adds up to what it asks for, because you can then combine
or split your way to the piece it needs.

A talisman shows only the pieces you hold until its `TALISMAN INFO` has been
read. Until then, the window says `needs not read` where the bars would be.

## Install

Build the package (see [Building](#building)), then drag
`AchaeaTalismans.mpackage` into Mudlet, or install it from **Package
Manager**. It is written for Mudlet 4.22 and later.

The window opens docked on the right the first time it loads.

## Commands

| command | what it does |
| --- | --- |
| `tals` | show the window, what has been read so far, and this list |
| `tals show` / `tals hide` | open or close the window |
| `tals all` | list every talisman you hold pieces of |
| `tals set <set>` | list one set's talismans instead |
| `tals scan` | send `TALISMAN SETS` and `TALISMAN PIECES`, then `TALISMAN INFO` for each talisman you hold pieces of |
| `tals scan <set>` | send `TALISMAN SET <set>`, then `TALISMAN INFO` for each of its talismans |
| `tals stop` | stop a scan |
| `tals diag` | the build stamp, what is stored, and where it is saved |

The quickest start is `tals scan`, then `tals set <set>` for the set you are
working on.

## What it sends

**Nothing unless you run `tals scan`.** Otherwise it only reads listings you
typed yourself, and it does not answer the pager for them.

A scan sends one command at a time and waits for its answer before sending
the next. It answers `MORE` only for a listing it asked for. A step with no
answer in 8 seconds is skipped. `tals stop` ends a scan, and nothing more is
sent after that.

## What it keeps

What it has read is saved to `achaea-talismans.lua` in your Mudlet profile's
folder, and comes back the next time the profile loads. The window shows when
your pieces were last read. A listing only changes what it covers: `TALISMAN
PIECES <talisman>` replaces that talisman's rows and leaves the rest alone.

Removing the package stops its trigger and closes its window.

## Building

Both the build and the tests use only the standard library: Python 3 for the
build, and LuaJIT, the Lua 5.1 that Mudlet runs, for the tests.

```bash
python3 build.py          # writes AchaeaTalismans.xml and AchaeaTalismans.mpackage
luajit test_harness.lua   # the tests, against a stand-in for Mudlet
```

`build.py` prints a build stamp, a hash of the source. `tals diag` in Mudlet
should print the same one; anything else is a stale install. The build is
byte-reproducible, so rebuilding the same source gives the same file.
`AchaeaTalismans.xml` is generated and committed, and CI checks that it
matches a rebuild. Edit `AchaeaTalismans.lua` and `build.py`, never the XML.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
