import Properties.Merge
import Properties.Runs

/-!
# Counterexamples to serializable merge

Each counterexample is a pair of forks of the same base snapshot that only *write*, whose
merge succeeds, but which no serial execution reproduces: they refute
`MergeIsSerializable`. All checks are by kernel evaluation (`decide`/`rfl`).

The serializability property is the one `SerialParallelStateMachine`
(icechunk-python/tests/test_stateful_parallel_sessions.py) tests, but that test only
generates forks touching disjoint nodes, so it cannot find these.
-/

/-- Base snapshot: `/` and `/g` are groups, `/g/a` and `/b` are arrays. -/
def base : Snapshot where
  nodes := ⟨[([], ⟨0, [], 0, .group⟩),
    (["g"], ⟨1, ["g"], 0, .group⟩),
    (["g", "a"], ⟨2, ["g", "a"], 0, .array [] none⟩),
    (["b"], ⟨3, ["b"], 0, .array [] none⟩)]⟩

def arrayData : ArrayData := { shape := [], dimensionNames := [], userData := 0 }

/-! ## Counterexample 1: a group and an array created at the same path

`EditChanges::merge` (icechunk/src/change_set.rs, `fn merge` on `EditChanges`) runs
`check_for_conflicts` on `new_groups` against `new_groups` and `new_arrays` against
`new_arrays`, but never `new_groups` against `new_arrays`. Both forks see `/x` as free, the
merge succeeds, and the merged change set holds a group *and* an array at `/x`. Neither
serial order succeeds: the second add fails with `alreadyExists`. -/

def ce1A : Prog Op Unit := Prog.op (.addGroup ["x"] 10 0)
def ce1B : Prog Op Unit := Prog.op (.addArray ["x"] 20 arrayData)

theorem ce1_merge_ok :
    (runOn base ce1A).merge (runOn base ce1B) = .ok (mergeOn base ce1A ce1B) := rfl

theorem ce1_merged_has_both : (mergeOn base ce1A ce1B).newGroups.contains ["x"] = true ∧
    (mergeOn base ce1A ce1B).newArrays.contains ["x"] = true := by decide

theorem ce1_not_serializable : ¬ MergeIsSerializable base ce1A ce1B := by
  intro h
  obtain ⟨c', hrun, -⟩ := h _ _ _ rfl rfl ce1_merge_ok
  rcases hrun with hrun | hrun
  · exact run_ne_ok (by decide) hrun
  · exact run_ne_ok (by decide) hrun

/-! ## Counterexample 2: a new child under a concurrently deleted group

Fork A creates `/g/n`; fork B deletes `/g`. `Session::delete_group` (icechunk/src/session.rs)
deletes every node under the group *that B can list*, and B cannot see `/g/n`. The merge
check for deleted groups compares only the deleted group's own path and id, not its
descendants, so the merge succeeds and leaves `/g/n` without its parent. Running A then B
instead deletes `/g/n`. This is the merge counterpart of the `FIXME` on `Conflict` in
icechunk/src/conflicts/mod.rs.

On its own this is not a counterexample to serializability: the merge matches B then A.
Counterexample 3 adds a chunk write that rules out that order too. -/

def ce2A : Prog Op Unit := Prog.op (.addArray ["g", "n"] 10 arrayData)
def ce2B : Prog Op Unit := Prog.op (.deleteGroup ["g"])

theorem ce2_merge_ok :
    (runOn base ce2A).merge (runOn base ce2B) = .ok (mergeOn base ce2A ce2B) := rfl

/-- The merge keeps `/g/n` but not its parent `/g`. -/
theorem ce2_orphan : (getNode base (mergeOn base ce2A ce2B) ["g", "n"]).isSome = true ∧
    getNode base (mergeOn base ce2A ce2B) ["g"] = none := by decide

/-- Running A then B deletes `/g/n`. -/
theorem ce2_serial_deletes_child : getNode base (runOn base (do ce2A; ce2B)) ["g", "n"] = none := by
  decide

/-! ## Counterexample 3: no serial order at all

Both forks also write the same chunk. Chunks are last-writer-wins with the *second*
argument of `merge` winning (`set_chunks` is extended with `other`'s), so they follow A then
B, while the deletion behaves like B then A. -/

def ce3A : Prog Op Unit := do
  Prog.op (.addArray ["g", "n"] 10 arrayData)
  Prog.op (.setChunk ["b"] 0 (some ⟨1⟩))

def ce3B : Prog Op Unit := do
  Prog.op (.deleteGroup ["g"])
  Prog.op (.setChunk ["b"] 0 (some ⟨2⟩))

theorem ce3_merge_ok :
    (runOn base ce3A).merge (runOn base ce3B) = .ok (mergeOn base ce3A ce3B) := rfl

theorem ce3_not_serializable : ¬ MergeIsSerializable base ce3A ce3B := by
  intro h
  obtain ⟨c', hrun, hv⟩ := h _ _ _ rfl rfl ce3_merge_ok
  rcases hrun with hrun | hrun
  · -- A then B deletes `/g/n`; the merge keeps it.
    have := (hv ["g", "n"]).1
    rw [eq_runOn hrun] at this
    revert this
    decide
  · -- B then A ends with A's chunk `⟨1⟩` at `/b`; the merge has B's `⟨2⟩`.
    have := (hv ["b"]).2 0
    rw [eq_runOn hrun] at this
    revert this
    decide
