import IcechunkModel.Session

/-- Writes a Zarr client can issue against a session. New nodes carry explicit ids. -/
inductive Op
  | addGroup (p : Path) (id : NodeId) (m : Meta)
  | addArray (p : Path) (id : NodeId) (m : Meta)
  | updateGroup (p : Path) (m : Meta)
  | updateArray (p : Path) (m : Meta)
  | deleteGroup (p : Path)
  | deleteArray (p : Path)
  | setChunk (p : Path) (c : Coord) (v : Option Payload)
  deriving DecidableEq, Repr

inductive OpError
  | alreadyExists
  | nodeNotFound
  | notAnArray
  | notAGroup
  deriving DecidableEq, Repr

/-- One session operation. Deleting a missing node succeeds; adding over an existing node fails;
adding does not check that the parent group exists. -/
def step (s : Snapshot) (cs : EditChanges) : Op → Except OpError EditChanges
  | .addGroup p id m    => addGroup s cs p id m
  | .addArray p id m    => addArray s cs p id m
  | .updateGroup p id m => updateGroup s cs p id m
  | .updateArray p id m => updateArray s cs p id m
  | .deleteArray p id => deleteArray s cs p id
  | .deleteGroup p id => deleteGroup s cs p id
