// The counting that the fight and the prep both read.
//
// Run against a LOGGED-OUT KoLmafia: with no character every count is zero and
// nothing is held, which is the state these functions are asked about on a
// fresh day and the one the off-by-one lived in.
//
// Two kinds of check here, and they are not the same:
//
//   THE SHIPPED FUNCTIONS, called directly. What they must say when nothing has
//   been spent is the whole point -- 3 locket fights available, not 2.
//
//   THE CINCH ARITHMETIC, transcribed. It reads _cinchUsed and total_free_rests(),
//   neither of which can be set without a character, so the sum is written out
//   again here and checked against the game's own casts-per-rests table. If the
//   formula in NCForceEstimate() changes, change it here too; nothing enforces
//   that, which is why this part says so.
//
//   call tests/counts.test.ash

import UnderTheSeaGlobals.ash;

int fails;
void ck(int got, int want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

// NCForceEstimate()'s cinch term, with its two reads lifted out.
int cinchCasts(int used, int restsLeft) {
    return min(3, (100 - used + 30 * max(0, restsLeft)) / 60);
}

void main() {
    // --- the shipped functions, with nothing held or spent ---------------
    //
    // split_string("") is ONE empty field, not none, which is why counting the
    // fields of an unwritten _locketMonstersFought read a reminisce as spent.
    // KoLmafia's own DailyDeedsPanel special-cases the blank string before
    // split(",") for the same reason.
    ck(count(split_string("", ",")), 1, "split_string(\"\") is one field");
    ck(locketFightsUsed(), 0, "no locket fight spent on a fresh day");
    ck(3 - locketFightsUsed(), 3, "so all three are available");
    ck(mimicExtractsLeft(), 0, "no chest mimic, no extractions");
    ck(delevelers(), 0, "nothing held, no delevelers");

    // --- the cinch term, transcribed -------------------------------------
    //
    // The game's own table gives the free rests needed for N casts as
    // 0, 1, 3, 5, 8, 17. Inside the cap of 3 this reproduces it exactly.
    ck(cinchCasts(0, 0), 1, "full cinch, no rests -> 1 cast");
    ck(cinchCasts(0, 1), 2, "1 rest  -> 2");
    ck(cinchCasts(0, 2), 2, "2 rests -> 2");
    ck(cinchCasts(0, 3), 3, "3 rests -> 3");
    ck(cinchCasts(0, 4), 3, "4 rests -> 3");
    ck(cinchCasts(0, 8), 3, "8 rests -> capped at 3");
    // And what the old 1 + rests/2 could not see at all: cinch already spent.
    ck(cinchCasts(60, 0), 0, "one exit spent, no rests -> none left");
    ck(cinchCasts(60, 1), 1, "one exit spent, 1 rest -> 1");
    ck(cinchCasts(100, 0), 0, "all spent -> none");
    ck(cinchCasts(100, 2), 1, "all spent, 2 rests -> 1");

    if (fails > 0) abort(fails + " check(s) failed");
    print("counts: all checks passed", "green");
}
