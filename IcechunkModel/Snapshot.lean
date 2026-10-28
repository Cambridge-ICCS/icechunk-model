/-- Model of `icechunk-format/src/snapshort.rs` -/

structure DimensionShape : Type where
  dimLength : Nat
  numChunks : Nat

abbrev ArrayShape := List DimensionShape
