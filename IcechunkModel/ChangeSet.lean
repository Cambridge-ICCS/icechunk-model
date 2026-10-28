import IcechunkModel.Chunks
import IcechunkModel.Map
import IcechunkModel.Snapshot

/-!
# Change sets

A (partial) model of `icechunk/src/change_set.rs`.

This includes the uncommitted modifications of a writable session, and
the `merge` operation which combines the change sets of forked sessions.

Abstractions relative to actual Rust implementation:
* HashMap and BTreeMap are representing using an association list (from `Map`)
*

* Zarr metadata / user data / array shapes are an opaque `Meta`;
chunk payloads are an opaque `Payload`. Chunk coordinates are never out of bounds, so `deleted_chunks_outside_bounds`
  is omitted.
* Moves (rearrange sessions) and the chunk-count bookkeeping are omitted.
* Node ids are explicit rather than `NodeId::random()`; callers supply fresh ones.
-/

/-- Path components as a list of strings
  `[]` is the root `/`
  `["g", "a"]` means `/g/a`
   -/
abbrev Path := List String

/-- Node ids are nat numbers. -/

-- Some of these are abstractions for now
abbrev NodeId := Nat
abbrev Meta := Nat
abbrev Coord := Nat
abbrev Payload := Chunk
abbrev Bytes := Nat -- placeholder
abbrev DimensionName := Nat -- placeholder

/-- `None` marks a deleted chunk. -/
abbrev ChunkTable := Map Coord (Option Payload)

structure ArrayData : Type where
  shape          : ArrayShape
  dimensionNames : List Nat
  userData       : Bytes
  deriving Repr, DecidableEq

structure EditChanges where
  newGroups     : Map Path (NodeId × Bytes) := ∅
  newArrays     : Map Path (NodeId × ArrayData) := ∅
  updatedArrays : Map NodeId Meta := ∅
  updatedGroups : Map NodeId Meta := ∅
  setChunks     : Map NodeId ChunkTable := ∅ -- BTreeMap in the impl.
  numChunks     : Nat := 0
  -- deleteChunksOutsideBounds omitted for now
  deletedGroups : List (Path × NodeId) := []
  deletedArrays : List (Path × NodeId) := []
  deriving Repr

namespace EditChanges

-- Model of the 'default' instances of the Rust
def default : EditChanges := { }

def is_empty (ec : EditChanges) : Bool :=
   ec.newGroups.isEmpty
   && ec.newArrays.isEmpty
   && ec.updatedArrays.isEmpty
   && ec.updatedGroups.isEmpty
   && ec.setChunks.isEmpty
   && ec.numChunks == 0
   && ec.deletedGroups.isEmpty
   && ec.deletedArrays.isEmpty

/-- `check_for_conflicts`: some key is present in both maps with different values. -/
-- Currently a large simplification to the actual implementation
def checkForConflicts {K V : Type} [DecidableEq K] [DecidableEq V] (a : Map K V) (b : Map K V) : Bool :=
  a.keys.any fun k =>
    match a.get? k, b.get? k with
    | some v, some w => v != w
    | _, _ => false

/-- ## Some helpers for the model of `merge` and its checks -/
-- An array deleted in `a` was created, updated, or had chunks written in `b`.
def deletedArrayModified (a b : EditChanges) : Bool :=
  a.deletedArrays.any fun (p, n) =>
    b.newArrays.contains p || b.updatedArrays.contains n || b.setChunks.contains n

/-- A group deleted in `a` was created or updated in `b`. -/
def deletedGroupModified (a b : EditChanges) : Bool :=
  a.deletedGroups.any fun (p, n) => b.newGroups.contains p || b.updatedGroups.contains n

inductive MergeError
  | groupsCreated
  | groupsUpdated
  | arraysCreated
  | arraysUpdated
  | arraysDeletedAndModified
  | groupsDeletedAndModified
  deriving DecidableEq, Repr

def mergeChecks (a b : EditChanges) : Option MergeError :=
  if checkForConflicts a.newGroups b.newGroups then some .groupsCreated
  else if checkForConflicts a.updatedGroups b.updatedGroups then some .groupsUpdated
  else if checkForConflicts a.newArrays b.newArrays then some .arraysCreated
  else if checkForConflicts a.updatedArrays b.updatedArrays then some .arraysUpdated
  else if deletedArrayModified a b || deletedArrayModified b a then some .arraysDeletedAndModified
  else if deletedGroupModified a b || deletedGroupModified b a then some .groupsDeletedAndModified
  else none

/-- The combination performed once the checks pass: `extend`
everywhere, and per-array `extend` of chunk tables (last writer wins). -/
def union (a b : EditChanges) : EditChanges where
  newGroups := a.newGroups.extend b.newGroups
  newArrays := a.newArrays.extend b.newArrays
  updatedGroups := a.updatedGroups.extend b.updatedGroups
  updatedArrays := a.updatedArrays.extend b.updatedArrays
  setChunks := a.setChunks.mergeWith b.setChunks Map.extend
  deletedGroups := b.deletedGroups ++ a.deletedGroups
  deletedArrays := b.deletedArrays ++ a.deletedArrays
  -- TOOD: behaviour on bounds for deleted chunks outside bounds

/-- `a.merge(b)`: changes in `b` take precedence. -/
def merge (a b : EditChanges) : Except MergeError EditChanges :=
  match mergeChecks a b with
  | some e => .error e
  -- TODO: check conflicts on nodes, see l.202 at end of merge
  | none => .ok (union a b)


-- def addGroup (cs : EditChanges) (p : Path) (id : NodeId) (defn : Bytes) : EditChanges :=
--   { cs with newGroups := cs.newGroups.insert p (id, defn) }
