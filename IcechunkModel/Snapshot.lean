/-- Partial model of `icechunk-format/src/snapshort.rs` -/
import IcechunkModel.Map

structure DimensionShape : Type where
  dimLength : Nat
  numChunks : Nat
  deriving Repr, DecidableEq

/-- The committed snapshot a session starts from. -/
structure NodeSnapshot where
  id       : NodeId
  path     : Path
  userData : Bytes
  nodeData : NodeData

  -- nodes : Map Path Node
  -- chunks : Map (NodeId × Coord) Payload

abbrev ArrayShape := List DimensionShape
