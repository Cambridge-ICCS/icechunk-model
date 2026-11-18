import Client.Op

/-- Two change sets on top of `s` give the same view of every node. -/
def ViewEq (s : Snapshot) (c c' : EditChanges) : Prop :=
  ∀ p, getNode s c p = getNode s c' p

/-- Merging fork `a` then `b` looks like running `progA` then `progB` in one session. -/
def MergeIsSerial (s : Snapshot) (progA progB : Prog Op Unit) : Prop :=
  ∀ a b c, run s {} progA = .ok a → run s {} progB = .ok b → a.merge b = .ok c →
    ∃ c', run s {} (do progA; progB) = .ok c' ∧ ViewEq s c c'
