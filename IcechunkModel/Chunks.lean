/-! Model of chunks and array data -/

-- Currently chunks just contain a chunk_id and otherwise
-- are abstract.
structure Chunk : Type where
  ChunkId : Nat

open Chunk
