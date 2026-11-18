# A formal, mechanised model of IceChunk

The following repo provides a model of the core IceChunk 
concepts, written in Lean 4, providing a formal framework
for reasoning about IceChunk concepts, and then applying
these to the practical implementation via tests.

## Overview

- `icechunk/` is a submodule pointing to a fork of IceChunk
- `IcechunkModel/` contains the formal Lean 4 model of the implementation: one file per
  modelled Rust module (`Snapshot`, `ChangeSet`, `Session`, ...).
- `Client/` models client programs run against the model, as a free monad over session
  operations (`Prog`, `Op`, `run`), and enumerates them for small-scope search (`Search`).
- `Properties/` contains specifications of the model, stated in terms of client programs.
- `tests/` contains tests that apply the formal model to the practical implementation.

Each directory is a separate Lean library. Dependencies go one way only:
`IcechunkModel` ← `Client` ← `Properties`, so the model never depends on the client harness.

## Running the tests

The tests are `#guard` checks, which Lean evaluates when the file is compiled.
They form the `Tests` library, which is the package's test driver:

```sh
lake test
```

A zero exit code means all tests passed. A failing `#guard` reports an error with its
line number and a non-zero exit code. In VS Code, opening the test file also evaluates the
checks and highlights any failures.

## Enumerating client programs

[Client/Search.lean](Client/Search.lean) enumerates free-monad programs up to an operation
count bound. Supply a finite alphabet at each depth; `opsAt` provides a small
default alphabet over a path:

```lean
import Client.Search

open ClientSearch

def paths : List Path := [["g"], ["g", "a"]]
def arrayData : ArrayData := { shape := [], dimensionNames := [], userData := 5 }
def choices (idBase : NodeId) (depth : Nat) : List (Op Unit) :=
  paths.flatMap fun p => opsAt p (idBase + depth) arrayData

-- Includes the empty program and all one- and two-operation programs.
def forkA := programs (choices 100) 2
def forkB := programs (choices 200) 2

def search (s : Snapshot) (cs : EditChanges) :=
  forkA.flatMap fun a => forkB.map fun b =>
    (runForks s cs a b, run s cs (do a; b), run s cs (do b; a))
```

`runForks` starts both programs from the same state and retains both success and
error results. Successful fork change sets can be combined with `a.merge b`;
sequential execution instead uses ordinary monadic composition, as above.
Choose fresh, disjoint id ranges large enough for the depth bound and avoid ids
in the initial state. Enumeration is exponential in the bound.

The free monad adds little complexity here because every `Op` returns `Unit`.
Operations returning other types would need finite result domains to enumerate
result-dependent continuations exhaustively.