# AchaeaTalismans

A [Mudlet](https://www.mudlet.org/) package for [Achaea](https://www.achaea.com/)
that shows how far your talisman pieces get you, in a window beside the game.

It reads what the game prints for `TALISMAN PIECES`, `TALISMAN INFO`,
`TALISMAN SET`, `TALISMAN SETS` and `TALISMAN LIST` whenever you type them,
and draws each talisman's pieces as bars:

```
◐ a Red Dragon Talisman (reddragon)  0/8 ready, 4%
  claw             L7    █████░░░░░░░░░░░ 22/64
  heart            L7    ░░░░░░░░░░░░░░░░ 0/64
```

Below the talismans, the window lists every set with a mark for each of its
talismans: done, started or not started. A set's name is a link to that set.
A talisman is marked done once `TALISMAN LIST` has been read, which `tals
scan` sends; a set's talismans are marked once `TALISMAN SET <set>` has been
read, which `tals scan <set>` sends.

## How pieces are counted

Two pieces of one level combine into one piece a level up, and one piece
splits into two a level down (`HELP TALISMANS`). So the window counts
everything in level-1 pieces: a level-7 slot needs 64, and every piece of that
keyword you hold counts toward it, whatever its level. In the example above,
claws at levels 2, 3 and 5 are 2 + 4 + 16 = 22 of the 64. A slot is **ready**
once what you hold adds up to what it asks for, because you can then combine
or split your way to the piece it needs.

A talisman shows only the pieces you hold until its `TALISMAN INFO` has been
read. Until then, the window says `needs not read` where the bars would be.

## Install

Build the package (see [Building](#building)), then drag
`AchaeaTalismans.mpackage` into Mudlet, or install it from **Package
Manager**. It is written for Mudlet 4.22 and later.

The window opens docked on the right whenever the profile loads, unless you
closed it with `tals hide`. Closing it with its own close button keeps it
closed until you ask for it again (`tals`, `tals show`, `tals set`).

## Commands

| command | what it does |
| --- | --- |
| `tals` | show the window, what has been read so far, and this list |
| `tals show` / `tals hide` | open or close the window |
| `tals all` | list every talisman you hold pieces of |
| `tals set <set>` | list one set's talismans instead |
| `tals scan` | send `TALISMAN LIST` and `TALISMAN PIECES`, then `TALISMAN INFO` for each talisman you hold pieces of and have not read yet |
| `tals scan <set>` | send `TALISMAN SET <set>`, then `TALISMAN INFO` for each of its talismans |
| `tals stop` | stop a scan |
| `tals diag` | the build stamp, what is stored, and where it is saved |

The commands are lower case, as written here; the set name after `tals set`
or `tals scan` may be any case. Anything else after `tals`, `tals SCAN`
included, is caught and named as not a command, rather than going to the
game.

The quickest start is `tals scan`, then `tals set <set>` for the set you are
working on.

## What it sends

**Nothing unless you run `tals scan`.** Otherwise it only reads listings you
typed yourself, and it does not answer the pager for them.

A scan sends one command at a time and waits for its answer before sending
the next. While it waits, it answers `MORE` for a talisman listing of the
kind it is waiting for, including a page break between two of that
listing's tables, and for nothing else: a help scroll or any other output
paged meanwhile is left to you. A listing of that kind you type
yourself mid-scan cannot be told apart from the scan's own, so it may be
paged on too. A step with no answer in 8 seconds is skipped. `tals stop`
ends a scan, and nothing more is sent after that.

## What it keeps

What it has read is saved to `achaea-talismans.lua` in your Mudlet profile's
folder, and comes back the next time the profile loads. The window shows when
your pieces were last read. A listing only changes what it covers: `TALISMAN
PIECES <talisman>` replaces that talisman's rows and leaves the rest alone.

A listing is read only to its end. One left unfinished at a page break is
dropped, not saved, if anything else is paged before you read on, or if you
read on more than five minutes later. A row is only taken if its keyword
ends the line and starts in the listing's `Keyword` column or after it, so a
tell that arrives in the middle of a table is not read as a row.

Removing the package stops its trigger and closes its window.

## What is a reading, not a fact

The package is written against what the game printed on the days its
listings were captured. A few of its rules are inferences from those, and
are worth knowing:

- **A heading in `TALISMAN PIECES` names the talisman.** The listing groups
  pieces under a line like `blackdragonpieces`, and the package takes the
  talisman's keyword to be that without `pieces`. That was confirmed for the
  six dragons only. For another talisman, a wrong guess shows as its
  `TALISMAN INFO` going unanswered in a scan.
- **`TALISMAN LIST`'s talisman tables are the done ones.** They have no
  titles. `HELP TALISMANS` says the listing shows completed talismans and the
  completed ones you carry, and both tables came straight before the sets
  table. So a talisman table counts as done only when the sets table follows
  it, and never on its own.
- **Pieces of every source count together.** A piece's source (B, Q or F in
  the listings seen) is kept but not used, so pieces of one keyword from two
  sources add up as if they combine. Whether they do is untested.
- **Ready is arithmetic, not a plan.** A slot is ready when the level-1 sum
  reaches what it asks for. The `TALISMAN COMBINE` and `SPLIT` steps to get
  there are yours to work out, and the package does not check that they
  exist in that order.
- **`TALISMAN PIECES <talisman>` does not say whose pieces it lists.** The
  package takes that from what you already read, or from the command just
  typed, where a keyword cut short (`silver`) counts if it starts only one
  talisman keyword already known. Failing both, the pieces are shown under
  "Pieces of no known talisman".

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
