import IcechunkModel.Chunks
import IcechunkModel.Map

/-!
# Snapshots

Partial model of `icechunk-format/src/snapshot.rs`, together with the basic
types from `icechunk-format/src/lib.rs`.
-/

/-- Path components as a list of strings
  `[]` is the root `/`
  `["g", "a"]` means `/g/a`
   -/
abbrev Path := List String

-- Some of these are abstractions for now
abbrev NodeId := Nat
abbrev Coord := Nat -- `ChunkIndices` is N-dimensional in the impl.
abbrev Payload := Chunk
abbrev Bytes := Nat -- placeholder
abbrev DimensionName := Nat -- placeholder

structure DimensionShape : Type where
  dimLength : Nat
  numChunks : Nat
  deriving Repr, DecidableEq

abbrev ArrayShape := List DimensionShape

/-- Manifests are omitted from arrays. -/
inductive NodeData
  | array (shape : ArrayShape) (dimensionNames : Option (List DimensionName))
  | group
  deriving Repr, DecidableEq

inductive NodeType
  | group
  | array
  deriving Repr, DecidableEq

structure NodeSnapshot where
  id       : NodeId
  path     : Path
  userData : Bytes
  nodeData : NodeData
  deriving Repr, DecidableEq

def NodeSnapshot.nodeType (n : NodeSnapshot) : NodeType :=
  match n.nodeData with
  | .group => .group
  | .array .. => .array

/-- The committed snapshot a session starts from. -/
structure Snapshot where
  nodes : Map Path NodeSnapshot
  -- chunks : Map (NodeId × Coord) Payload
  deriving Repr
