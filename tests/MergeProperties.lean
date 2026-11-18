import Properties.Merge

/-! Tests of the specifications in `Properties/Merge.lean`. -/

/-- Base snapshot with one array `/a` (id 1). -/
private def base : Snapshot := ⟨⟨[(["a"], ⟨1, ["a"], 0, .array [] none⟩)]⟩⟩

private def runOn (prog : Prog Op Unit) : EditChanges :=
  match run base {} prog with
  | .ok c => c
  | .error _ => {}

private def writes1 : EditChanges := runOn (Prog.op (.setChunk ["a"] 0 (some ⟨1⟩)))
private def writes2 : EditChanges := runOn (Prog.op (.setChunk ["a"] 0 (some ⟨2⟩)))

/-! `ViewEq` compares chunk contents, not only nodes: these two change sets have the same
node at `/a` but different chunks there. -/

example : getNode base writes1 ["a"] = getNode base writes2 ["a"] := by decide

example : ¬ ViewEq base writes1 writes2 := fun h => by
  have := (h ["a"]).2 0
  revert this
  decide

example : ViewEq base writes1 writes1 := fun _ => ⟨rfl, fun _ => rfl⟩
