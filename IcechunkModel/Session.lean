import IcechunkModel.ChangeSet

/-- Partial model of `icechunk/src/session.rs` -/

inductive SessionMode
  | Readonly
  | Writable
  | Rearrange
  deriving DecidableEq, Repr
