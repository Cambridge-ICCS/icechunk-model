import IcechunkModel
import Client.Prog

/-- Operations a Zarr client can issue against a session, indexed by their result type.
New nodes carry explicit ids. -/
inductive Op : Type → Type
  | addGroup (p : Path) (id : NodeId) (m : Meta) : Op Unit
  | addArray (p : Path) (id : NodeId) (m : ArrayData) : Op Unit
  | updateGroup (p : Path) (m : Meta) : Op Unit
  | updateArray (p : Path) (m : Meta) : Op Unit
  | deleteGroup (p : Path) : Op Unit
  | deleteArray (p : Path) : Op Unit
  | setChunk (p : Path) (c : Coord) (v : Option Payload) : Op Unit

/-- The algebra for `Op` to a state monad over the change set. -/
def step (s : Snapshot) : Op b → StateT EditChanges (Except OpError) b
  | .addGroup p id m  => fun cs => ((), ·) <$> addGroup s cs p id m
  | .addArray p id m  => fun cs => ((), ·) <$> addArray s cs p id m
  | .updateGroup p m  => fun cs => ((), ·) <$> updateGroup s cs p m
  | .updateArray p m  => fun cs => ((), ·) <$> updateArray s cs p m
  | .deleteArray p    => fun cs => ((), ·) <$> deleteArray s cs p
  | .deleteGroup p    => fun cs => ((), ·) <$> deleteGroup s cs p
  | .setChunk p c v   => fun cs => ((), ·) <$> setChunkRef s cs p c v

/-- Run a program in one session, returning the resulting change set. -/
def run (s : Snapshot) (cs : EditChanges) (prog : Prog Op Unit) : Except OpError EditChanges :=
  Prod.snd <$> (prog.interp (step s)).run cs
