"""What CI can check here, and what you can run yourself:

    python3 .github/check.py [--mafia <kolmafia checkout>]

KoLmafia's own `verify` already compiles these scripts and resolves every
symbol, type and $item[...]/$monster[...] literal, so it is the first thing to
run and this does not duplicate it:

    verify UnderTheSeaGlobals.ash   (and the other three)

What is left is the class `verify` cannot see: ASH that compiles cleanly, runs
without an error, and quietly produces the wrong number. Each check below is
here because that shape has actually shipped.

Lives in .github/ on purpose: KoLmafia installs scripts/, relay/, data/,
images/, ccs/ and planting/, so a checker in any of those is copied into
whoever's mafia folder.
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "scripts")
problems = []


def fail(where, msg):
    problems.append((where, msg))


def ash_files():
    return sorted(f for f in os.listdir(SCRIPTS) if f.endswith(".ash"))


def read(f):
    with open(os.path.join(SCRIPTS, f), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def strip_comments(t):
    t = re.sub(r"/\*.*?\*/", "", t, flags=re.S)
    return re.sub(r"//[^\n]*", "", t)


def lines_of(f):
    """(lineno, text) with comments kept -- callers that need them say so."""
    return list(enumerate(read(f).splitlines(), 1))


# ---------------------------------------------------------------- traps
#
# Each of these compiles. Each returns a wrong value rather than an error.
def check_traps():
    for f in ash_files():
        for n, line in lines_of(f):
            bare = re.sub(r"//.*", "", line)

            # to_int() chained onto replace_string() is 0, always: replace_string
            # returns a buffer and the int coercion of a buffer is not its text.
            if re.search(r"replace_string\s*\(.*?\)\s*\.\s*to_int\s*\(", bare):
                fail(f"{f}:{n}", "to_int() chained onto replace_string() is always 0 -- split it into two statements")

            # $strings[..] / $items[..] / $monsters[..] are SETS. A two-variable
            # foreach over one binds the member to the first and `true` to the
            # second, so the body compares against "true".
            m = re.search(r"foreach\s+\w+\s*,\s*(\w+)\s+in\s+\$(strings|items|monsters|skills|effects|locations|stats|phyla)\[", bare)
            if m:
                fail(f"{f}:{n}", f"foreach over a $%s[..] SET with two variables binds `true` to `{m.group(1)}`" % m.group(2))

            # `for i from a to b` counts DOWN when b < a. Fine when meant;
            # flagged so a reader confirms it was.
            m = re.search(r"for\s+\w+\s+from\s+(\d+)\s+to\s+(\d+)", bare)
            if m and int(m.group(2)) < int(m.group(1)):
                fail(f"{f}:{n}", f"for ... from {m.group(1)} to {m.group(2)} counts DOWN -- confirm that is meant")

            # split_string's separator is a REGEX, so a metacharacter splits on
            # the wrong thing (or on everything).
            for sep in re.findall(r'split_string\s*\([^,]+,\s*"([^"]*)"', bare):
                if re.search(r"[.^$*+?()\[\]{}|]", sep) and "\\" not in sep:
                    fail(f"{f}:{n}", f'split_string separator "{sep}" is a regex -- escape the metacharacter')

            # ASH reserved words used as identifiers do not compile, but these
            # read as fine to a human writing them.
            m = re.search(r"\b(?:int|string|boolean|float|item|monster|location|skill|effect|familiar|slot|stat|buffer)\s+(from|to|in|by|until|stat)\b\s*[;=,)]", bare)
            if m:
                fail(f"{f}:{n}", f"`{m.group(1)}` is an ASH reserved word -- rename the variable")


# ------------------------------------------------- preference vs its default
#
# A guard that tests a preference against a value it never holds is dead, and a
# dead guard reads exactly like a live one.
def check_pref_defaults(data):
    defaults = {}
    path = os.path.join(data, "defaults.txt")
    if not os.path.exists(path):
        fail("defaults.txt", f"not found in {data}")
        return
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 2:
                defaults.setdefault(parts[1], parts[2] if len(parts) > 2 else "")

    # What the scripts themselves write, so a preference the script sets to
    # "false" is not reported as never holding it.
    written = {}
    for f in ash_files():
        # Every string literal anywhere in the call, so a ternary counts:
        # set_property("_utsScreechFired", hit ? "true" : "false") writes both.
        for m in re.finditer(r'set_property\s*\(\s*"([^"]+)"\s*,([^;]*)', strip_comments(read(f))):
            written.setdefault(m.group(1), set()).update(re.findall(r'"([^"]*)"', m.group(2)))

    # ONLY THE "NOT YET" SIDE IS INTERESTING. Testing a preference against
    # "true" when it defaults to "false" is the ordinary idiom -- mafia writes
    # the true, not the script -- so flagging that is noise. A guard is dead
    # when it tests for the value an UNSET preference would read as while the
    # real default is something else: `== "false"` on a preference mafia never
    # defines reads "" and can never fire.
    #
    # uts_-prefixed names are the player's own switches, set by hand and
    # deliberately absent by default, so an opt-in that reads as never-set and
    # an opt-out that reads as always-on are both correct.
    UNSET_ISH = {"", "false", "0"}
    cmp_re = re.compile(r'get_property\s*\(\s*"([^"]+)"\s*\)\s*(==|!=)\s*("(?:false|0|)"|false)')
    for f in ash_files():
        for n, line in lines_of(f):
            for m in cmp_re.finditer(re.sub(r"//.*", "", line)):
                pref, op, lit = m.group(1), m.group(2), m.group(3).strip('"')
                if pref.startswith("uts_"):
                    continue
                real = defaults.get(pref, "")
                if lit == real or lit in written.get(pref, ()):
                    continue
                if real.isdigit() and lit.isdigit():
                    continue
                verdict = "always FALSE" if op == "==" else "always TRUE"
                where = '(undefined, so "")' if pref not in defaults else f'default "{real}"'
                fail(f"{f}:{n}", f'{pref} {op} "{lit}" is {verdict} -- {where}, and nothing writes "{lit}"')


# -------------------------------------------- a hardcoded id vs its comment
#
# `745,   // unholy diver` is the whole reason: an id and a name that disagree
# look right to every reader and send the script after the wrong monster.
def check_id_comments(data):
    def load(rel, idcol, namecol):
        out = {}
        p = os.path.join(data, rel)
        if not os.path.exists(p):
            return out
        with open(p, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if line.startswith("#") or not line.strip():
                    continue
                c = line.rstrip("\n").split("\t")
                if len(c) > max(idcol, namecol) and c[idcol].strip().isdigit():
                    out[int(c[idcol])] = c[namecol].strip()
        return out

    mons = load("monsters.txt", 1, 0)
    items = load("items.txt", 0, 1)
    if not mons:
        fail("monsters.txt", f"not found in {data}")
        return

    for f in ash_files():
        for n, line in lines_of(f):
            m = re.search(r'(?<![\w.])(\d{3,5})\s*[,;)\]]*\s*//\s*([A-Za-z][A-Za-z\'\- ]{2,40})', line)
            if not m:
                continue
            num, said = int(m.group(1)), m.group(2).strip().rstrip(".").lower()
            mon, item = mons.get(num, "").lower(), items.get(num, "").lower()
            if not mon and not item:
                continue
            if said in (mon, item) or (mon and mon in said) or (item and item in said):
                continue
            # Only speak when the comment looks like it is naming the id.
            if mon and said.split()[0] not in mon and len(said.split()) <= 5:
                fail(f"{f}:{n}", f'id {num} is "{mons[num]}" but the comment says "{m.group(2).strip()}"')


# ------------------------------------- a choice case that can answer nothing
#
# A choice with no default in mafia that the handler leaves unanswered drops to
# manual control and stops the run, in the middle of automation.
def check_choice_fallthrough():
    f = "UnderTheSea_Choice.ash"
    if f not in ash_files():
        return
    text = strip_comments(read(f))
    # Each case block up to the next case/default at the same level.
    cases = list(re.finditer(r"^\s*case\s+(\d+)\s*:", text, re.M))
    for i, c in enumerate(cases):
        start = c.end()
        end = cases[i + 1].start() if i + 1 < len(cases) else len(text)
        body = text[start:end]
        if not body.strip() or re.match(r"\s*case\s", body):
            continue          # falls through to the next case on purpose
        if "run_choice" not in body and "stashboxCheck" not in body and "pickChoice" not in body:
            continue          # not a case that answers at all
        # Safe two ways: an answer at the case's own brace level always runs,
        # and so does an if/else chain that ends in a bare `else`. Without
        # either, some path reaches `break` having answered nothing -- which is
        # manual control, mid-automation, for a choice with no default.
        #
        # A heuristic on purpose: it says where to look, it does not prove the
        # case is wrong. An `else if` chain with no final bare `else` is
        # reported, which is the right way round to be wrong.
        depth, unconditional, bare_else = 0, False, False
        for tok in re.finditer(r"[{}]|\belse\s+if\b|\belse\b|run_choice|stashboxCheck|pickChoice", body):
            t = tok.group(0)
            if t == "{":
                depth += 1
            elif t == "}":
                depth -= 1
            elif depth <= 0:
                if t == "else":
                    bare_else = True
                elif not t.startswith("else"):
                    unconditional = True
                    break
        if not unconditional and not bare_else:
            n = text[:c.start()].count("\n") + 1
            fail(f"{f}:~{n}", f"choice {c.group(1)}: every answer is inside a branch -- confirm some path always answers")


# ------------------------------------------- a cap against mafia's own limit
#
# Every daily cap in here is a number somebody read off the game once. mafia
# keeps the same numbers in dailylimits.txt and updates them when KoL changes
# one, so a cap that has drifted is worth hearing about before a run spends a
# charge that is not there or stops short of one that is.
#
# ONLY THE freeSources TABLE, which declares its cap in a field called cap. The
# caps written as a bare comparison were tried and the check thrown away:
# almost every number compared against a _counter preference is a phase in the
# route rather than a claim about the limit. The script casts Monster Habitats
# while _monsterHabitatsRecalled < 2 and switches to the golem chain at >= 2,
# keeping the third of mafia's three for elsewhere -- correct, and
# indistinguishable by shape from an out-of-date cap. That version reported
# eight of those and nothing else, so it earned its removal. A declaration says
# what it means; a comparison does not.
def check_daily_limits(data):
    path = os.path.join(data, "dailylimits.txt")
    if not os.path.exists(path):
        fail("dailylimits.txt", f"not found in {data}")
        return
    limits = {}
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            c = line.rstrip("\n").split("\t")
            if len(c) >= 3 and c[2].strip():
                n = c[3].strip() if len(c) > 3 and c[3].strip() else "1"
                if n.isdigit():
                    limits.setdefault(c[2].strip(), set()).add(int(n))

    for f in ash_files():
        for n, line in lines_of(f):
            m = re.search(r'new freeSrc\([^)]*?"(_\w+)"\s*,\s*(\d+)', line)
            if not m:
                continue
            pref, cap = m.group(1), int(m.group(2))
            # 0 is the table's own "no fixed daily cap", and a preference mafia
            # does not list has nothing to be compared against.
            if not cap or pref not in limits:
                continue
            if cap not in limits[pref]:
                fail(f"{f}:{n}", f"freeSources caps {pref} at {cap}; mafia says "
                                 + "/".join(str(x) for x in sorted(limits[pref])))


# WHERE MAFIA'S DATA FILES ARE.
#
# Four checks read them, and they are not in this repository: defaults.txt
# says what an unset preference reads as, monsters.txt and items.txt say what an
# id is, and dailylimits.txt says what a daily cap is. Taking them from mafia
# rather than copying them here is the point --
# a copy would be another number to keep in step.
#
# --data <dir> is a flat directory of the .txt files, which is what CI builds.
# --mafia <dir> is a KoLmafia checkout. Without either, a checkout in the usual
# place is tried, and failing that the three checks say so and stand down
# rather than passing silently.
def data_dir(argv):
    if "--data" in argv:
        d = os.path.expanduser(argv[argv.index("--data") + 1])
        return d if os.path.isdir(d) else None
    roots = []
    if "--mafia" in argv:
        roots.append(os.path.expanduser(argv[argv.index("--mafia") + 1]))
    if os.environ.get("KOLMAFIA"):
        roots.append(os.path.expanduser(os.environ["KOLMAFIA"]))
    roots.append(os.path.expanduser("~/source/kolmafia"))
    for r in roots:
        d = os.path.join(r, "src", "main", "resources", "data")
        if os.path.isdir(d):
            return d
    return None


# WHAT IS ALREADY KNOWN, so that red means new.
#
# Adopting a checker into code that predates it has one failure mode: it reports
# things nobody is fixing today, the build is red forever, and then nobody reads
# it. The baseline is the findings that were open when the check landed. A
# finding in it is printed and ignored; anything else fails.
#
# KEYED ON FILE AND MESSAGE, NOT THE LINE. A line number moves whenever anything
# above it is edited, and a baseline that goes stale on an unrelated change is a
# baseline people delete. The message already names the preference, the id or the
# choice, so it is specific enough on its own.
#
# Fixing something in the baseline: delete its line. The check will not miss it
# coming back, because coming back is a finding that is no longer listed.
def baseline():
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "check-baseline.txt")
    if not os.path.exists(p):
        return set()
    with open(p, encoding="utf-8") as fh:
        return {l.strip() for l in fh if l.strip() and not l.startswith("#")}


def main():
    data = data_dir(sys.argv)
    check_traps()
    check_choice_fallthrough()
    if data is None:
        print("note: no KoLmafia data found, so the preference-default, id/comment")
        print("      and daily-cap checks did not run. Pass --mafia <checkout> or")
        print("      --data <dir>.")
    else:
        check_pref_defaults(data)
        check_id_comments(data)
        check_daily_limits(data)
    known = baseline()
    fresh, old = [], []
    for where, msg in problems:
        (old if f"{where.split(':')[0]}: {msg}" in known else fresh).append((where, msg))

    if "--baseline" in sys.argv:
        for where, msg in problems:
            print(f"{where.split(':')[0]}: {msg}")
        return 0

    for where, msg in old:
        print(f"known   {where}: {msg}")
    for where, msg in fresh:
        print(f"NEW     {where}: {msg}")
    if not fresh:
        print(f"\ncheck.py: nothing new ({len(old)} known)")
        return 0
    print(f"\n{len(fresh)} new thing(s) to look at, {len(old)} already known")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
