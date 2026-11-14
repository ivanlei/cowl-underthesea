// What the run says about itself, and what it says when it stops.
//
// Run against a LOGGED-OUT KoLmafia; nothing here adventures, buys or equips.
//
//   call tests/trace.test.ash
//
// WHAT IS WORTH TESTING HERE and what is not. The printing is not: a test that
// asserts on the colour of a line is a test that fails when somebody improves
// the wording, and it would not have caught anything that has gone wrong.
//
// What IS worth it is the part with arithmetic in it:
//
//   uts_need's phrasing, because a farming loop's trace line and the abort
//   that follows when the farming fails are supposed to read identically. Two
//   spellings of the same shortfall is how you end up unsure whether they are
//   the same shortfall.
//
//   the trail keeping the last ten and dropping the eleventh, which is a ring
//   written by hand in a language with no ring, and is the one piece here that
//   can be off by one.
//
//   the levels gating the right lines, because "quiet" silently swallowing the
//   decisions would make the whole thing useless exactly when it is needed.
//
// uts_stop is NOT called: it aborts, which would end the test. What can be
// checked is that the trail it would print is the trail that was recorded, so
// that is what the last section does.

import UnderTheSeaGlobals.ash;

int fails;

void ck(string got, string want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got \"" + got + "\" want \"" + want + "\"", "red");
}

void ck(int got, int want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

void ck(boolean got, boolean want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

void main() {
    // ── a preference that is a yes or a no ──────────────────────────────────
    //
    // The point of the helpers is that the four spellings they replace do not
    // all agree, and the disagreement is exactly at the unset value: 120 call
    // sites now lean on prefOff being TRUE there, where the `== "false"` many
    // of them were written as is FALSE.
    string keepBool = get_property("uts_traceSelfTest");
    set_property("uts_traceSelfTest", "");
    ck(prefOn("uts_traceSelfTest"), false, "unset is not on");
    ck(prefOff("uts_traceSelfTest"), true, "unset IS off -- the whole point");
    set_property("uts_traceSelfTest", "true");
    ck(prefOn("uts_traceSelfTest"), true, "true is on");
    ck(prefOff("uts_traceSelfTest"), false, "true is not off");
    set_property("uts_traceSelfTest", "false");
    ck(prefOn("uts_traceSelfTest"), false, "false is not on");
    ck(prefOff("uts_traceSelfTest"), true, "false is off");
    // Anything that is not "true" is not a yes, which is what keeps a
    // preference holding a third value from reading as one.
    set_property("uts_traceSelfTest", "unready");
    ck(prefOn("uts_traceSelfTest"), false, "some other value is not on");
    ck(prefOff("uts_traceSelfTest"), true, "some other value is off");
    set_property("uts_traceSelfTest", keepBool);

    string keepLevel = get_property("uts_trace");
    string keepPhase = get_property("_uts_phase");

    // ── the phrasing ────────────────────────────────────────────────────────
    ck(uts_need("sea leather", 1, 0), "sea leather: need 1, have 0", "a plain shortfall");
    ck(uts_need("mer-kin prayerbeads", 2, 2), "mer-kin prayerbeads: need 2, have 2",
        "met, which a caller may still want to say");
    // Having MORE than you need is a sentence this must not get wrong, since a
    // loop that has over-collected still asks.
    ck(uts_need("rusty rivet", 8, 11), "rusty rivet: need 8, have 11", "more than needed");

    // ── the levels ──────────────────────────────────────────────────────────
    set_property("uts_trace", "");
    ck(utsTraceLevel(), "normal", "unset reads as normal");
    ck(utsTraceQuiet(), false, "unset is not quiet");
    ck(utsTraceVerbose(), false, "unset is not verbose");

    set_property("uts_trace", "quiet");
    ck(utsTraceQuiet(), true, "quiet is quiet");
    ck(utsTraceVerbose(), false, "quiet is not verbose");

    set_property("uts_trace", "verbose");
    ck(utsTraceVerbose(), true, "verbose is verbose");
    ck(utsTraceQuiet(), false, "verbose is not quiet");

    // A level nobody meant is normal, not silence: a typo in a preference must
    // not be the reason a run says nothing about itself.
    set_property("uts_trace", "noisy");
    ck(utsTraceQuiet(), false, "an unknown level is not quiet");
    ck(utsTraceVerbose(), false, "an unknown level is not verbose");

    set_property("uts_trace", "quiet");   // keep the rest of this quiet

    // ── the trail ───────────────────────────────────────────────────────────
    utsTrail.clear();
    ck(count(utsTrail), 0, "starts empty");

    for i from 1 to 10
        utsRemember("line " + i);
    ck(count(utsTrail), 10, "ten fit");
    ck(utsTrail[0], "line 1", "the first is still first at ten");
    ck(utsTrail[9], "line 10", "the tenth is last");

    utsRemember("line 11");
    ck(count(utsTrail), 10, "the eleventh does not make eleven");
    ck(utsTrail[0], "line 2", "the oldest went");
    ck(utsTrail[9], "line 11", "the newest is last");

    // Twenty more, to catch a ring that only drops one too few.
    for i from 12 to 31
        utsRemember("line " + i);
    ck(count(utsTrail), 10, "still ten after twenty more");
    ck(utsTrail[0], "line 22", "and the window moved by twenty");
    ck(utsTrail[9], "line 31", "ending where it should");

    // ── what a phase records ────────────────────────────────────────────────
    utsTrail.clear();
    uts_phase("corral");
    ck(get_property("_uts_phase"), "corral", "the phase is left where the CCS can read it");
    ck(utsTrailHead, "corral", "and where an abort can read it");
    ck(count(utsTrail), 1, "a phase is one line of the trail");

    step("sea leather: need 1, have 0");
    uts_why("route collect", "no cursed monkey's paw");
    ck(count(utsTrail), 3, "a step and a why are each one line");
    ck(utsTrail[2], "route collect — no cursed monkey's paw", "a why carries its reason");
    // A why with nothing to say should not leave a trailing dash.
    uts_why("route drop", "");
    ck(utsTrail[3], "route drop", "a why with no reason is just the choice");

    // ── what is short ───────────────────────────────────────────────────────
    //
    // uts_short is the line COwliCK asked for by name, and the half worth a
    // test is the half that says NOTHING: about twenty loops call it and most
    // of them do not run, so a version that spoke when the need was already met
    // would bury the ones that matter under the ones that do not.
    utsTrail.clear();
    uts_short("sea leather", 1, 1, "farming the corral");
    ck(count(utsTrail), 0, "nothing said when the need is met");
    uts_short("sea leather", 1, 4, "farming the corral");
    ck(count(utsTrail), 0, "nothing said when there is more than enough");
    uts_short("sea leather", 2, 1, "farming the corral");
    ck(count(utsTrail), 1, "one line when short");
    ck(utsTrail[0], "sea leather: need 2, have 1 — farming the corral",
        "and it reads as the shortfall and the remedy");

    // ── what a choice says ──────────────────────────────────────────────────
    //
    // utsPick wraps run_choice, so it cannot be called here without answering a
    // choice that is not on screen. What CAN be checked is the sentence it
    // builds, which is the part that has to name the choice it is inside --
    // utsChoiceNow is set once in main() and read by every case, so a case that
    // ran without it would report choice 0.
    utsTrail.clear();
    utsChoiceNow = 1525;
    uts_why("choice " + utsChoiceNow + " -> option 3", "a reason");
    ck(utsTrail[0], "choice 1525 -> option 3 — a reason", "a pick names its choice");
    utsChoiceNow = 0;

    set_property("uts_trace", keepLevel);
    set_property("_uts_phase", keepPhase);

    if (fails > 0) abort(fails + " check(s) failed");
    print("trace: every check passed", "green");
}
