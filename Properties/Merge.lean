import Client.Op

-- So that `getChunkRef` results can be compared by `decide`.
deriving instance DecidableEq for Except

/-- Two change sets on top of `s` are indistinguishable to a reader: every path has the same
node (`Session::get_node`) and every chunk reads the same (`Session::get_chunk_ref`). This is
the model's counterpart of the invariant of `SerialParallelStateMachine`
(icechunk-python/tests/test_stateful_parallel_sessions.py), which compares array contents. -/
def ViewEq (s : Snapshot) (c c' : EditChanges) : Prop :=
  ∀ p, getNode s c p = getNode s c' p ∧
    ∀ coord, getChunkRef s c p coord = getChunkRef s c' p coord

/-- Merging fork `a` then `b` looks like running `progA` then `progB` in one session. -/
def MergeIsSerial (s : Snapshot) (progA progB : Prog Op Unit) : Prop :=
  ∀ a b c, run s {} progA = .ok a → run s {} progB = .ok b → a.merge b = .ok c →
    ∃ c', run s {} (do progA; progB) = .ok c' ∧ ViewEq s c c'
