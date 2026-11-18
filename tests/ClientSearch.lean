import Client.Search

open ClientSearch

private def emptySnapshot : Snapshot := ⟨∅⟩

private def choices (depth : Nat) : List (Op Unit) :=
  [.addGroup ["g"] (100 + depth) 5, .deleteGroup ["g"]]

-- Bounds include the empty program; each nonempty word occurs once.
#guard (programs choices 0).length == 1
#guard (programs choices 1).length == 3
#guard (programs choices 2).length == 7
#guard (programs (fun _ => []) 3).length == 1

private def operationIds : Prog Op Unit → List NodeId
  | .pure () => []
  | .bind op k =>
    match op with
    | .addGroup _ id _ | .addArray _ id _ => id :: operationIds (k ())
    | .updateGroup .. | .updateArray .. | .deleteGroup .. | .deleteArray .. |
        .setChunk .. => operationIds (k ())

#guard (programs (fun depth =>
    [.addGroup ["g"] (100 + depth) 5, .addGroup ["h"] (200 + depth) 5]) 2).map
    operationIds ==
  [[], [100], [100, 101], [100, 201], [200], [200, 101], [200, 201]]

private def arrayData : ArrayData := { shape := [], dimensionNames := [], userData := 5 }
#guard (opsAt ["a"] 100 arrayData).length == 9

-- The first operation uses depth zero, and subsequent operations use increasing depths.
private def createChoices (depth : Nat) : List (Op Unit) :=
  [.addGroup [toString depth] (100 + depth) 5]

#guard ((programs createChoices 2).map fun p =>
  (run emptySnapshot {} p).map fun cs =>
    (getNode emptySnapshot cs ["0"], getNode emptySnapshot cs ["1"])).all fun
    | .ok (none, none) => true
    | .ok (some a, none) => a.id == 100
    | .ok (some a, some b) => a.id == 100 && b.id == 101
    | _ => false

-- Enumeration does not discard programs that fail in the initial state.
#guard ((programs choices 2).map (run emptySnapshot {})).any fun
  | .error .alreadyExists => true
  | _ => false

private def add : Prog Op Unit := Prog.op (.addGroup ["g"] 100 5)
private def update : Prog Op Unit := Prog.op (.updateGroup ["g"] 6)

-- Forks share a starting state; serial composition sees earlier edits.
#guard match runForks emptySnapshot {} add update with
  | (.ok _, .error .nodeNotFound) => true
  | _ => false

#guard match run emptySnapshot {} (do add; update) with
  | .ok cs => (getNode emptySnapshot cs ["g"]).map (·.userData) == some 6
  | _ => false

-- Successful independent forks can be merged with the existing merge operation.
private def addOther : Prog Op Unit := Prog.op (.addGroup ["h"] 200 5)

#guard match runForks emptySnapshot {} add addOther with
  | (.ok a, .ok b) =>
    match a.merge b with
    | .ok cs => (getNode emptySnapshot cs ["g"]).isSome &&
        (getNode emptySnapshot cs ["h"]).isSome
    | .error _ => false
  | _ => false
