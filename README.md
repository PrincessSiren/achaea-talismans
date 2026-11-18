# AchaeaTalismans

A [Mudlet](https://www.mudlet.org/) package for [Achaea](https://www.achaea.com/)
that shows how far your talisman pieces get you, in a window beside the game.

It reads what the game prints for `TALISMAN PIECES`, `TALISMAN INFO`,
`TALISMAN SET`, `TALISMAN SETS` and `TALISMAN LIST` whenever you type them,
and draws each talisman's pieces as bars:

```
▾ ◐ a Red Dragon Talisman (reddragon)  0/8 ready, 4%
    claw    L7 ███░░░░░░░ 22/64
    heart   L7 ░░░░░░░░░░ 0/64
```

The pieces you hold are folded to one line, `▸ Pieces you hold`, with a
count; clicking it lists them, and clicking again folds them. Listed, each
talisman is folded in turn to its name and how far along it is, and
clicking a name shows its pieces, as above. `[open all]` and `[fold all]`
do every talisman at once. The window remembers what is open.

Under the pieces, the window lists every set with a mark for each of its
talismans: done, started or not started. A set's name is a link that shows
that set's talismans on their own, without the sets list; `[back to sets]`
returns to everything. A talisman is marked done once `TALISMAN LIST` has
been read, and a set's talismans are marked once `TALISMAN SET <set>` has
been read: `tals scan` sends both, SET for every set, and `tals scan <set>`
sends SET for the one.

The window lays itself out in as many columns of talismans as fit its
width, and again when it is resized, so a wide window shows several side by
side. The sets are always two columns, each half the window, and a set
with more marks than fit on its line wraps them onto the next, under its
first marks. Docked under Mudlet's mapper, the window is as wide as the
mapper. A window too narrow to show four marks a line in half of it lists
the sets in one column. When the window is too short for all of it, it shows
a scroll bar, which Mudlet otherwise leaves off a user window, so there is a
sign of more above; when everything fits, the bar goes. Like the columns,
Mudlet's count of a window's lines can be a little high, so the package
works out the lines that fit for certain. Mudlet's own column count for a window can be a few too many, since
it divides by the font's average character width as a fraction while each
character is drawn a whole number of pixels wide. So the package works out
from it how many columns fit for certain, and may leave a column or two
spare at the right rather than run past the edge. `tals diag` shows both
numbers.

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
Manager**. It is written for Mudlet 5.0 and later.

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
| `tals scan` | send `TALISMAN LIST`, `TALISMAN PIECES` and `TALISMAN SET` for every set, then `TALISMAN INFO` for each talisman you hold pieces of and have not read yet |
| `tals scan <set>` | send `TALISMAN SET <set>` and `TALISMAN PIECES`, then `TALISMAN INFO` for each of its talismans |
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
kind it is waiting for, and for a page break straight after one of that
listing's tables, with nothing but blank lines since, as between `TALISMAN
LIST`'s tables. It answers nothing else: a help scroll or any other output
paged meanwhile is left to you. A listing of that kind you type
yourself mid-scan cannot be told apart from the scan's own, so it may be
paged on too. A step with no answer in 8 seconds is skipped. `tals stop`
ends a scan, and nothing more is sent after that. One scan runs at a time:
`tals scan` while one is running sends nothing and says so.

**A scan is silent.** What the game answers it with is read and taken off
the screen: the listings, the page breaks it answers, and the prompt after
each. The window is where they show. A scan prints two lines of its own:

```
[tals] Scan started
[tals] Scan completed (42 pieces found)
```

The count is the pieces the scan's `TALISMAN PIECES` listed, one per piece
whatever its level; after `tals scan <set>`, only those toward that set. A
step the game did not answer in time is named on the second line (`Not
answered: talisman info golddragon`). What it cannot place in one of its
listings is left alone, so a tell or an attack that arrives mid-scan is
shown, and so is an answer it does not read, such as an error for a keyword
the game does not know.

A listing you type yourself mid-scan is shown, with two exceptions:

- **The same listing the scan is waiting for** is taken for the scan's, and
  hidden, as above.
- **`TALISMAN INFO` or `TALISMAN SET` loses its first line** while the scan
  waits on an INFO or a SET. Both open with a `Name:` line, and only the line
  after it says which listing it is and, for INFO, which talisman. So the
  `Name:` line is hidden before the package can tell it is not the scan's.
  Everything after it is shown. Any other output that has a line starting
  `Name:` loses that line in the same way.

**The prompt is how it knows a listing has ended.** Mudlet marks a prompt
from the game's GA. With GA turned off, no prompt is ever hidden. Each
listing's tail, the blank lines after it, is then let go one second after
the listing ends instead of at its prompt, and a talisman listing that
arrives in that second is hidden as if it were the scan's.

## What it keeps

What it has read is saved to `achaea-talismans.lua` in your Mudlet profile's
folder, and comes back the next time the profile loads. The window shows when
your pieces were last read. A listing only changes what it covers: `TALISMAN
PIECES <talisman>` replaces that talisman's rows and leaves the rest alone.

A listing is read only to its end. One left unfinished at a page break is
dropped, not saved, if anything else is paged before you read on, or if you
read on more than five minutes later. A row is only taken if it ends in a
keyword (lower-case letters and digits) that starts in the listing's
`Keyword` column or up to four columns after it, so a tell, a channel line or
a timing tag that arrives in the middle of a table is not read as a row.

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
