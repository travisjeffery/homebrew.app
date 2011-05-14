1. NSPredicate

    From my research on web, currently MacRuby's implementation of NSPredicate
    is buggy, or is at least in usage with CoreData, so any time you call
    `NSPredicate.predicateWithFormate`, e.g.,
    `NSPredicate.predicateWithFormat("attribute == value")` it will crash.

    **Fixes**:
    I've thought of many fixes but the above is the way it should be
    done, and all the rest are ugly are unnecessary given a functioning
    language. So I'm inclined to see what can be done to fix MacRuby's issues
    before continuing development.

2. Cache

    Parsing each formulas information each time is ridiculous, so I'll just
    implement a cache. The only difficult part is syncing the changes from
    people using both the graphical Homebrew and the command-line brew program.

3. Simple features

    Simple things like search, sorting, and some other things. I've been
    focused on #1's problem and haven't bothered to finish.
