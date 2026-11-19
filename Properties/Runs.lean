import Client.Op

/-!
# Runs of concrete programs

Helpers for stating and checking properties of concrete client programs. They start from an
empty change set on `s` and replace errors by the empty change set, so that results can be
named in theorems and compared by `decide`. -/

/-- Result of running `prog` in a fresh session on `s` (empty on error). -/
def runOn (s : Snapshot) (prog : Prog Op α) : EditChanges :=
  match run s {} prog with
  | .ok c => c
  | .error _ => {}

/-- Result of merging two forks of a fresh session on `s` (empty on error). -/
def mergeOn (s : Snapshot) (progA progB : Prog Op α) : EditChanges :=
  match (runOn s progA).merge (runOn s progB) with
  | .ok c => c
  | .error _ => {}

/-- Running `prog` in a fresh session on `s` fails. -/
def runFails (s : Snapshot) (prog : Prog Op α) : Bool := (run s {} prog).toOption.isNone

theorem run_ne_ok {s : Snapshot} {prog : Prog Op α} {c : EditChanges}
    (h : runFails s prog = true) : run s {} prog ≠ .ok c := by
  intro h'
  simp [runFails, h', Except.toOption] at h

theorem eq_runOn {s : Snapshot} {prog : Prog Op α} {c : EditChanges}
    (h : run s {} prog = .ok c) : c = runOn s prog := by
  simp [runOn, h]
