// cannotTakeThreeRounds(), the gate that decides whether the run dresses to
// kill or to farm.
//
// The numbers below are from a real logged run that lost 13 fights: a character
// the Mer-kin raider hit for 394 a round with 800 maximum HP. Three rounds of
// that is 1182, which is why it kept being beaten up with a +50% spell damage
// accessory sitting unworn in its inventory.
//
// Pure arithmetic on purpose, so this needs no character and no inventory --
// fragileForTheSea() reads expected_damage() and my_maxhp() and cannot be
// checked logged out, but the policy it applies can.
//
//   call tests/killgear.test.ash

import UnderTheSeaGlobals.ash;

int fails;
void ck(boolean got, boolean want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

void main() {
    // The run this was written for.
    ck(cannotTakeThreeRounds(394, 800), true, "394 a round into 800 HP is fragile");
    ck(cannotTakeThreeRounds(301, 800), true, "the sea cowboy's 301 too");
    ck(cannotTakeThreeRounds(117, 800), false, "but the giant squid's 117 is not");

    // A character with the absorption to shrug the zone off must come back
    // false, or it pays an accessory slot it does not need.
    ck(cannotTakeThreeRounds(70, 8780), false, "70 a round into 8780 HP is not fragile");

    // Exactly three rounds is survivable, so the boundary is > and not >=.
    ck(cannotTakeThreeRounds(100, 300), false, "three rounds exactly is not fragile");
    ck(cannotTakeThreeRounds(101, 300), true, "a point more than three rounds is");

    // Degenerate inputs a caller could hand it before a fight is in view.
    ck(cannotTakeThreeRounds(0, 800), false, "nothing hitting you is not fragile");

    if (fails == 0)
        print("killgear: all checks passed", "green");
    else
        print(fails + " check(s) failed", "red");
}
