/-- Partial model of `icechunk-format/src/snapshort.rs` -/

structure DimensionShape : Type where
  dimLength : Nat
  numChunks : Nat
  deriving Repr

abbrev ArrayShape := List DimensionShape
