import IcechunkModel.ZarrClient

/-!
# Enumerating client programs

Small-scope enumeration of `Prog Op Unit` programs, to be run in one session or in forks.
Every operation returns `Unit`, so there is nothing for a continuation to branch on and
straight-line programs (words over the operations) cover every program up to a length bound.
-/

namespace ClientSearch

/-- Every single operation on `p`; `id` is used for new nodes. -/
def opsAt (p : Path) (id : NodeId) (d : ArrayData) : List (Op Unit) :=
  [.addGroup p id 5, .addArray p id d, .updateGroup p 6, .updateArray p 6, .deleteGroup p,
    .deleteArray p, .setChunk p 0 (some ⟨8⟩), .setChunk p 0 (some ⟨9⟩), .setChunk p 0 none]

/-- Operations available at position `depth` of a fork's program. Each fork gets its own
`idBase` so new node ids stay fresh within and across forks (as `NodeId::random()` does). -/
def forkChoices (paths : List Path) (idBase : NodeId) (d : ArrayData) (depth : Nat) :
    List (Op Unit) :=
  paths.flatMap fun p => opsAt p (idBase + depth) d

/-- All programs of at most `n` operations, each prefix listed before its extensions.
`choices depth` gives the operations allowed at position `depth`. -/
def programs (choices : Nat → List (Op Unit)) (n : Nat) : List (Prog Op Unit) :=
  go 0 n
where
  go (depth : Nat) : Nat → List (Prog Op Unit)
    | 0 => [.pure ()]
    | n + 1 => .pure () :: (choices depth).flatMap fun op =>
        (go (depth + 1) n).map fun rest => .bind op fun _ => rest

/-- Run two programs as forks of the same session state. -/
def runForks (s : Snapshot) (cs : EditChanges) (progA progB : Prog Op Unit) :
    Except OpError EditChanges × Except OpError EditChanges :=
  (run s cs progA, run s cs progB)

end ClientSearch
