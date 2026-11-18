import Client.Op

/-! Tests of client programs (`Client/Op.lean`), in particular reads. -/

/-- Base snapshot with one array `/a` (id 1) and one group `/g` (id 2). -/
private def base : Snapshot :=
  ⟨⟨[(["a"], ⟨1, ["a"], 0, .array [] none⟩), (["g"], ⟨2, ["g"], 0, .group⟩)]⟩⟩

private def read (p : Path) : Prog Op (Option Payload) := Prog.op (.getChunkRef p 0)
private def write (p : Path) (n : Nat) : Prog Op Unit := Prog.op (.setChunk p 0 (some ⟨n⟩))

/-- Read-modify-write: the write depends on what was read. -/
private def increment (p : Path) : Prog Op Unit := do
  let v ← read p
  Prog.op (.setChunk p 0 (some ⟨(v.map (·.ChunkId)).getD 0 + 1⟩))

-- A read sees the session's own earlier writes.
#guard match runResult base {} (do write ["a"] 7; read ["a"]) with
  | .ok (some ⟨7⟩, _) => true | _ => false

-- Reads do not change the change set.
#guard match run base {} (do write ["a"] 7; let _ ← read ["a"]),
             run base {} (write ["a"] 7) with
  | .ok c, .ok d => c.getChunkRef 1 0 == d.getChunkRef 1 0 && c.numChunks == d.numChunks
  | _, _ => false

-- A failed read aborts the program, as `?` does in the Rust.
#guard match runResult base {} (read ["g"]) with
  | .error .notAnArray => true | _ => false
#guard match run base {} (do let _ ← read ["x"]; write ["a"] 7) with
  | .error .nodeNotFound => true | _ => false

-- Later operations can depend on a read.
#guard match runResult base {} (do increment ["a"]; increment ["a"]; read ["a"]) with
  | .ok (some ⟨2⟩, _) => true | _ => false

/-! Lost update: two forks that each increment `/a` read the same starting value, so merging
them gives 1, whereas running them one after the other gives 2.

Serializability needs a restriction on reads: `merge` checks only what forks wrote, so forks
that read data the other fork writes (here, a lost update) can break it. This is expected,
not a bug; the bugs are counterexamples where the forks only *write*. -/

#guard match run base {} (increment ["a"]), run base {} (increment ["a"]) with
  | .ok a, .ok b =>
    match a.merge b with
    | .ok c => (getChunkRef base c ["a"] 0 matches .ok (some ⟨1⟩))
    | .error _ => false
  | _, _ => false

#guard match runResult base {} (do increment ["a"]; increment ["a"]; read ["a"]) with
  | .ok (some ⟨2⟩, _) => true | _ => false
