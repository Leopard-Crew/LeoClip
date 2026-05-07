LeoClip modules are split by responsibility, not by arbitrary line count.

A class should usually have one clear reason to change.

Small model and helper classes should stay compact and independently testable.
Controller classes may be larger, but should primarily orchestrate other objects instead of owning their internal logic.

When a controller starts managing persistent state, data rules, parsing, polling, or formatting rules directly, that responsibility should be considered for extraction.

