// idInList(), against the collisions it exists for.
//
// This one tests the shipped function directly: idInList takes its list and its
// id as arguments, so it needs no character and no inventory.
//
// 745 inside 1745 is the collision that matters -- the remaindered skeleton is a
// monster this script fights in the skeleton store, so once one is on the
// baseball team or held in a mimic egg a contains_text would read it as the
// unholy diver.
//
//   call tests/idlist.test.ash

import UnderTheSeaGlobals.ash;

int fails;
void ck(boolean got, boolean want, string what) {
    if (got == want) return;
    fails = fails + 1;
    print("FAIL " + what + ": got " + got + " want " + want, "red");
}

void main() {
    ck(idInList("1745,100,200", 745), false, "1745 is not 745");
    ck(idInList("745,100,200", 745), true, "745 first");
    ck(idInList("100,745,200", 745), true, "745 in the middle");
    ck(idInList("100,200,745", 745), true, "745 last");

    // mimicEggMonsters is id:count, and to_int("1745:3") is 17453 rather than
    // 1745 -- ASH drops the colon and keeps reading -- so the id is taken off
    // the front. Without that this function would be a fresh bug of the same
    // shape as the one it replaced.
    ck(idInList("1745:3", 745), false, "1745:3 is not 745");
    ck(idInList("745:2", 745), true, "745:2 is 745");
    ck(idInList("100:1,745:2", 745), true, "745:2 after another");

    // The other three ids this script tests, each inside a longer one.
    ck(idInList("1773", 773), false, "1773 is not 773");
    ck(idInList("1775", 775), false, "1775 is not 775");
    ck(idInList("1776", 776), false, "1776 is not 776");
    ck(idInList("838", 838), true, "838 found");

    // An unwritten preference is empty, and a leprecondo row is zeroes.
    ck(idInList("", 745), false, "an empty list holds nothing");
    ck(idInList("0,0,0,0", 11), false, "zeroes hold no 11");

    if (fails > 0) abort(fails + " check(s) failed");
    print("idlist: all checks passed", "green");
}
