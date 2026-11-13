# tests

Run against a **logged-out** KoLmafia, from the mafia root:

```
call tests/idlist.test.ash
call tests/banisher.test.ash
call tests/counts.test.ash
call tests/yog_delevel.test.ash
```

Each prints a line and passes, or prints what failed and aborts. None of them
adventures, buys, equips or spends anything — they only read game data and call
functions. Nothing here needs a character, and logged out is the state most of
them are about: on a fresh day nothing has been spent, which is where an
off-by-one lives.

These sit beside, not instead of, KoLmafia's own `verify`, which compiles the
scripts and resolves every symbol and `$item[…]`/`$monster[…]` literal, and
`.github/check.py`, which looks for the ASH that compiles clean and quietly
computes the wrong number.

## Two kinds of check, and the difference matters

Most assertions call the **shipped function** directly, which is the point:
`idInList`, `locketFightsUsed`, `mimicExtractsLeft`, `delevelers` and
`banishUsedAtYourLocation`'s replacement all take their inputs as arguments or
read game data, so they can be asked real questions with no character.

A few **transcribe arithmetic** that cannot otherwise be driven — the cinch term
reads `_cinchUsed` and `total_free_rests()`, and the deleveling model reads
`item_amount()`, and neither can be set without a character. Those sums are
written out again in the test and checked against the game's own figures. If the
formula changes in the script, it has to change here too; nothing enforces that,
so each of those blocks says so where it is.
