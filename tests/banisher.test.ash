// banishUsedAtYourLocation(), against the walk it replaced.
//
// The question is whether a banisher's target appears where you are. It used to
// be answered through monster_found_in(), which walks every location in
// $locations[] -- and was called again inside its own loop body -- and is now
// one lookup on the location itself. Both forms are pure data, so this compares
// them for real rather than transcribing either.
//
// The pairings are the zones this script banishes in against the monsters it
// banishes, plus $monster[none] for a banisher that has not been used.
//
//   call tests/banisher.test.ash

import UnderTheSeaGlobals.ash;

int fails;
int checked;

// The old form, kept here only to be compared against.
boolean oldWay(monster used, location where) {
    foreach num in monster_found_in(used)
        if (monster_found_in(used)[num] == where)
            return true;
    return false;
}

boolean newWay(monster used, location where) {
    return used != $monster[none] && where.get_location_monsters() contains used;
}

void main() {
    foreach w in $locations[The Skeleton Store, An Octopus's Garden,
            The Marinara Trench, Anemone Mine, The Dive Bar, The Coral Corral,
            Mer-kin Elementary School, Mer-kin Library, The Mer-Kin Outpost,
            The Caliginous Abyss, Madness Bakery, The Haunted Pantry,
            The Sleazy Back Alley, Noob Cave] {
        foreach m in $monsters[remaindered skeleton, Neptune flytrap, diving belle,
                giant squid, sea cow, sea cowboy, Mer-kin rustler, Mer-kin healer,
                Mer-kin teacher, Mer-kin monitor, unholy diver, mine crab,
                novelty tropical skeleton, time cop, none] {
            checked = checked + 1;
            if (oldWay(m, w) != newWay(m, w)) {
                fails = fails + 1;
                print("DIFFER: " + m + " @ " + w + " old=" + oldWay(m, w)
                    + " new=" + newWay(m, w), "red");
            }
        }
    }
    print(checked + " pairings compared");
    if (fails > 0) abort(fails + " disagreement(s)");
    print("banisher: the two forms agree everywhere", "green");
}
