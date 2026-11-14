// fightingFloor(), the HP a fight needs before it starts.
//
// The numbers are from a real logged run that lost 13 fights: 800 maximum HP
// against a Mer-kin raider hitting for 394 a round, under a flat 570 target
// whose 0.75 trigger meant fights could start at 427.
//
// Pure arithmetic on purpose -- zoneWorstHit() reads expected_damage() and
// cannot be checked logged out, but the policy built on it can.
//
//   call tests/hpfloor.test.ash

import UnderTheSeaGlobals.ash;

int fails;
void ck(int got, int want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

void main() {
    // THE POINT OF THE CHANGE: the target is four rounds so that mafia's
    // trigger, three quarters of it, is three. If this ever stops holding the
    // floor is not what the comment says it is.
    foreach hit in $ints[394, 301, 198, 117, 1000] {
        ck(fightingFloor(hit, 0) * 3 / 4, 3 * hit,
           "four rounds of " + hit + " leaves three after the 0.75 trigger");
    }

    // The run this was written for: 394 a round needs 1576, not 570.
    ck(fightingFloor(394, 570), 1576, "the Mer-kin raider's 394");
    ck(fightingFloor(301, 570), 1204, "the sea cowboy's 301");

    // Where 570 was already enough it is left exactly alone, so a character the
    // Sea barely scratches pays nothing for this.
    ck(fightingFloor(117, 570), 570, "the giant squid's 117 keeps 570");
    ck(fightingFloor(70, 570),  570, "and so does 70");
    ck(fightingFloor(0, 570),   570, "nothing hitting you keeps 570");

    // The boundary where it starts to bite.
    ck(fightingFloor(142, 570), 570, "142 a round still fits inside 570");
    ck(fightingFloor(143, 570), 572, "143 does not");

    // The gymnasium asks for 800 and keeps it the same way.
    ck(fightingFloor(150, 800), 800,  "the gymnasium's 800 held");
    ck(fightingFloor(250, 800), 1000, "the gymnasium's 800 raised");

    if (fails == 0)
        print("hpfloor: all checks passed", "green");
    else
        print(fails + " check(s) failed", "red");
}
