# Contributing

Bug reports and ideas are welcome. So are patches, with the caveats below.

## Running it outside Mudlet

Everything here is stdlib Python and Lua 5.1. There is nothing to install.

```bash
luajit test_harness.lua                              # the harness
luajit -e "assert(loadfile('AchaeaTalismans.lua'))"  # syntax
python3 build.py                                     # rebuild the package
```

Mudlet embeds **Lua 5.1**, and `luajit` is that exact dialect. A 5.4 parser will
accept things Mudlet rejects, so check with `luajit` rather than `lua`.

## The `.xml` is generated, and it is what gets installed

`AchaeaTalismans.xml` is built from `AchaeaTalismans.lua` by `build.py`. Never
edit it by hand, and **always rebuild after touching the `.lua`**. A `.lua`
edited without a rebuild ships a package that does not match its source,
invisibly, because the diff of the change itself looks fine. CI fails on this.

`build.py` stamps a short content hash into the package, which `tals diag`
prints back. It is a hash rather than a timestamp on purpose: the `.xml` is
committed, so building twice with no source change has to produce a
byte-identical file. The `.mpackage` is byte-reproducible too, and CI checks
that.

`ALIASES` in `build.py` is the single source of truth for the commands. It
generates the XML aliases *and* the `AchaeaTalismans.COMMANDS` table the
in-game help prints, so the help cannot drift from what is installed. Adding a
command is one row there plus a function in the Lua.

## Where rules come from

**What the package claims about Achaea comes from what Achaea printed**, not
from what anyone remembers.

- Cite the scroll or the command: `HELP TALISMANS`, `TALISMAN INFO
  reddragon`. Naming the command matters more than quoting it, because the
  command still works after the quote goes stale.
- **A listing's layout is a capture.** The harness carries `TALISMAN PIECES`,
  `PIECES <talisman>`, `INFO`, `SET`, `SETS` and `LIST` column for column, with
  the pager where the game put it. If the game lays a listing out differently,
  or pages it somewhere new, bring those lines; do not adjust a pattern from
  memory. A pattern nobody has seen match is a reader that never fires and
  never says so.
- **The game's facts are kept as captured; a character's are not.** INFO, SET
  and the set totals are the game's, the same for everyone, and stay as
  printed. The pieces held, the talismans done and the prompt's vitals are one
  character's, so the harness's are made up, in the game's layout. If you
  bring a capture of your own pieces, invent the rows before they go in: the
  layout is what is under test, and nobody's collection needs to be public.
- What the package infers rather than reads is listed in the README, under
  "What is a reading, not a fact". A change that adds an inference adds a line
  there. If you cannot cite it, say so in the PR. An open question recorded
  honestly is worth more than a rule that reads well.

## Testing

`test_harness.lua` stubs Mudlet, reads the patterns off the live triggers and
fires them on the captured lines, so a typo in a pattern or a dropped
registration fails the run. It also runs scans against a stand-in game, page
breaks included, and checks what is sent and what is taken off the screen.

A green run means the reading, the scan's logic and the packaging hold. It does
**not** mean the window draws as it should, or that a scan stays silent against
the real game. Any change to the layout, to what is sent, or to what is hidden
wants watching in Mudlet again.

## Mudlet details the code depends on

Checked in Mudlet's source at `Mudlet-5.0.1` and `Mudlet-5.1.0`; the code
comments carry the detail. The package is written for 5.1, and loads and reads
on 5.0.

- **`calcFontSize(window, true)` is why it is written for 5.1.** It is new in
  5.1, and is the only way to ask the width of the cell Mudlet draws a
  character in. On 5.0, `calcFontSize(window)` is the width of a "W", so the
  layout takes one column off to be safe, and the columns may still run a
  column or two over, as the README says.
- **Mudlet's column and row counts run high, so the layout does not use
  them.** `getColumnCount` rounds the window's width over the font's average
  character width, while every cell is drawn at that width rounded to an
  integer. At an average near 7.6 drawn at 8, 72 columns were counted of about
  68 shown. The layout works from the cell size instead.
- **Output printed in a trigger is part of the line that fired.** A line feed
  in `echo` is embedded in that line, so a trigger that prints and then deletes
  its line deletes the print too. Anything the trigger has to say is deferred
  to `tempTimer(0, …)`, which runs once the trigger pass is done.
- **A user window cannot be scrolled to its top by script** without opening
  Mudlet's split-screen pane, since `scrollTo` calls `showLowerPane()` first.
  So the window shows its bottom, and its foot line repeats the top's links
  when the top is out of sight.
- **The prompt is how a listing ends**, and Mudlet marks a prompt from the
  game's GA. With GA turned off, no prompt trigger fires, so each listing's
  tail is let go by a timer instead (the README's "What it sends").

## Versions

`0.x`. Minor for a change in behaviour, patch for a fix to something already
released, and it moves **once per merged PR** rather than once per push.
Bumping mid-review mints numbers for states nobody installed.

`M.VERSION` in the Lua is the only place it lives; `build.py` reads it.

Pull requests are squash-merged, so a PR's title and description become the
commit on `main`. Write them for someone reading the log a year from now.

## Releasing

Pushing a tag `v<version>` is what ships. `release.yml` runs the harness,
refuses a tag whose number `M.VERSION` does not claim, builds the `.mpackage`
from that tag, checks the committed `.xml` matches it, and attaches it to the
release.

Publishing to the Mudlet package repository is a further step, gated on a
repository variable `PUBLISH_TO_MUDLET`, which is not set yet. It needs this
repository listed in that repository's `trusted-publishers.json` first, which
pins the owner, the repo and the workflow file by path. So **renaming
`release.yml` revokes publishing** until that entry is amended.

Each publish opens a pull request there. What follows is that repository's
behaviour as AchaeaHidden's releases met it, not something this one controls:
the pull request merged itself only when the automated review left **no
feedback on its head commit**, and replying to the feedback did not clear it;
only a new release did. So:

- **When a release changes behaviour, change `DESCRIPTION` in `build.py` with
  it.** That text becomes the package's description in the registry, and the
  review flags a description that does not match the release. It goes into
  the `.mpackage`'s `config.lua` only, so changing it moves neither the `.xml`
  nor the build stamp.
- **A stuck pull request stays open after the fix ships.** Each publish opens a
  new one, so the old one has to be closed by a maintainer there; ask in that
  repository. Merging it
  would roll the package back to its version.

Then it announces the release in Discord, if, and only if, a `DISCORD_WEBHOOK`
secret is set on the repository. The message carries the two things a player
can act on: the `.mpackage` and the build stamp `tals diag` prints back, with
the `mpkg install` line only once `PUBLISH_TO_MUDLET` is `true`. That
is a channel webhook URL from Discord's *Server Settings → Integrations →
Webhooks*, and it is a secret because it is a bearer credential: anyone holding
it can post to that channel as this package.

The announcement is the last step and the only one allowed to fail. By the time
it runs the release exists and the package is published, so a webhook that is
down is a message nobody got rather than a release that went wrong. It leaves a
warning and the run stays green. Re-running the job to get the message out
would ask the registry to publish the same version twice; post it by hand
instead. A fork has no secret, so the step skips there.
