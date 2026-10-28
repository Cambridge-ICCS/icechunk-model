/-- Partial model of `icechunk-format/src/snapshort.rs` -/

structure DimensionShape : Type where
  dimLength : Nat
  numChunks : Nat
  deriving Repr, DecidableEq

abbrev ArrayShape := List DimensionShape
