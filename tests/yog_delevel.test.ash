// What the delevelers on hand would leave Yog-Urt at.
//
// Run against a LOGGED-OUT KoLmafia.
//
// The shipped yogAfterDelevelers() reads item_amount(), so with nothing held it
// can only be asked the one question -- that it reports her undeleveled, which
// is the base the rest is measured from. The amounts themselves are transcribed
// below so the arithmetic can be driven: if the figures in
// yogAfterDelevelers() change, change them here too.
//
// Why this is worth pinning at all: "two delevelers" is not one quantity. A bar
// of Mer-kin mouthsoap is a flat 250 to 300 off both numbers and takes her from
// 400 to about 150 on its own; a handful of crayon shavings takes about 30% of
// whatever is left, so two of those land near 196. Each item type is good for
// one throw a fight, so there is no throwing a second handful.
//
//   call tests/yog_delevel.test.ash

import UnderTheSeaGlobals.ash;

int fails;
void ck(int got, int want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}
void ckb(boolean got, boolean want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

// yogAfterDelevelers()'s arithmetic, with "what is held" passed in. Same list
// order yogDeleveler() throws in, which is not the order that removes the most.
record held { boolean soap; boolean crayon; boolean ball; boolean lasso; boolean bell; };

yogDelevel afterHolding(held h) {
    monster yog = $monster[Yog-Urt, Elder Goddess of Hatred];
    yogDelevel l = new yogDelevel(monster_attack(yog), monster_defense(yog));
    if (h.soap)   { l.atk -= 250; l.def -= 250; }
    if (h.crayon) { l.atk -= l.atk * 30 / 100; l.def -= l.def * 30 / 100; }
    // the ball and the lasso delevel by unspaded amounts, so they count for nothing
    if (h.bell)   { l.atk -= 164; l.def -= 154; }
    l.atk = max(0, l.atk);
    l.def = max(0, l.def);
    return l;
}
boolean enough(int moxie, int muscle, yogDelevel l) {
    return moxie + 10 > l.atk && muscle - 30 > l.def;
}

void main() {
    // --- the shipped function, with nothing held -------------------------
    ck(yogAfterDelevelers().atk, 400, "nothing held leaves her attack at 400");
    ck(yogAfterDelevelers().def, 400, "and her defence at 400");

    // --- the arithmetic, transcribed -------------------------------------
    ck(afterHolding(new held(true, false, false, false, false)).atk, 150, "mouthsoap alone");
    ck(afterHolding(new held(false, true, false, false, false)).atk, 280, "crayon alone");
    ck(afterHolding(new held(false, false, false, false, true)).atk, 236, "cowbell alone");
    ck(afterHolding(new held(false, false, false, false, true)).def, 246, "cowbell alone, defence");
    // List order matters: the crayon's 30% comes off before the cowbell's flat cut.
    ck(afterHolding(new held(false, true, false, false, true)).atk, 116, "crayon then cowbell");
    ck(afterHolding(new held(true, false, false, false, true)).atk, 0, "mouthsoap + cowbell floors at 0");
    ck(afterHolding(new held(false, false, true, true, false)).atk, 400, "ball + lasso count for nothing");

    // --- what a count of two cannot tell apart ---------------------------
    //
    // A Seal Clubber: muscle clears her 400 defence unaided, so moxie binds,
    // and most of a Seal Clubber's moxie is on its gear.
    ckb(enough(180, 500, afterHolding(new held(false, true, true, false, false))), false,
        "base moxie 180, two weak types: short");
    ckb(enough(450, 500, afterHolding(new held(false, true, true, false, false))), true,
        "the same two, buffed moxie 450: enough, throw nothing");
    ckb(enough(180, 500, afterHolding(new held(true, false, false, false, false))), true,
        "moxie 180 but a mouthsoap: enough");
    ckb(enough(200, 500, afterHolding(new held(false, true, true, false, false))), false,
        "two types, no cowbell, moxie 200: still short");
    ckb(enough(200, 500, afterHolding(new held(false, true, false, false, true))), true,
        "two types including the cowbell: enough");

    if (fails > 0) abort(fails + " check(s) failed");
    print("yog delevel: all checks passed", "green");
}
