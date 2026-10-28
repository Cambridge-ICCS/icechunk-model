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
  deriving Repr

structure EditChanges where
  newGroups     : Map Path (NodeId × Bytes) := ∅
  newArrays     : Map Path (NodeId × ArrayData) := ∅
  updatedArrays : Map NodeId Meta := ∅
  updatedGroups : Map NodeId Meta := ∅
  setChunks     : Map NodeId ChunkTable := ∅ -- BTreeMap in the impl.
  numChunks     : Nat
  -- deleteChunksOutsideBounds omitted for now
  deletedGroups : List (Path × NodeId) := []
  deletedArrays : List (Path × NodeId) := []
  deriving Repr

namespace EditChanges
