import IcechunkModel

/-! Tests of the session read operations in `IcechunkModel/Session.lean`. -/

private def emptySnapshot : Snapshot := ⟨∅⟩
private def arrayData : ArrayData := { shape := [], dimensionNames := [], userData := 0 }

/-- Array `/a` (id 1) with chunk 0 written and chunk 1 deleted; group `/g` (id 2). -/
private def edits : EditChanges :=
  let result : Except OpError EditChanges := do
    let cs ← addArray emptySnapshot {} ["a"] 1 arrayData
    let cs ← addGroup emptySnapshot cs ["g"] 2 0
    let cs ← setChunkRef emptySnapshot cs ["a"] 0 (some ⟨7⟩)
    setChunkRef emptySnapshot cs ["a"] 1 none
  match result with
  | .ok cs => cs
  | .error _ => {}

/-! `EditChanges.getChunkRef` (change_set.rs `get_chunk_ref`) -/

#guard edits.getChunkRef 1 0 == some (some ⟨7⟩)  -- written
#guard edits.getChunkRef 1 1 == some none        -- deleted in this session
#guard edits.getChunkRef 1 2 == none             -- not touched
#guard edits.getChunkRef 2 0 == none             -- no chunks for this node

/-! `getChunkRef` (session.rs `Session::get_chunk_ref`) -/

#guard match getChunkRef emptySnapshot edits ["a"] 0 with
  | .ok (some ⟨7⟩) => true | _ => false
#guard match getChunkRef emptySnapshot edits ["a"] 1 with
  | .ok none => true | _ => false
-- Not touched in this session: falls back to the (unmodelled) manifests, so no chunk.
#guard match getChunkRef emptySnapshot edits ["a"] 2 with
  | .ok none => true | _ => false
#guard match getChunkRef emptySnapshot edits ["g"] 0 with
  | .error .notAnArray => true | _ => false
#guard match getChunkRef emptySnapshot edits ["x"] 0 with
  | .error .nodeNotFound => true | _ => false
