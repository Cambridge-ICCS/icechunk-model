/-! A generic free monad, used to model client programs. -/

-- Free monad over a signature `sig`
inductive Prog (sig : Type → Type) (a : Type) : Type 1
  | pure : a → Prog sig a
  | bind {b : Type} : sig b → (b → Prog sig a) → Prog sig a

namespace Prog

/-- Generic effect operation (program consisting of a single operation) -/
def op (o : sig b) : Prog sig b := .bind o .pure

def progBind : Prog sig a → (a → Prog sig b) → Prog sig b
  | pure x  , f => f x
  | bind o k, f => bind o (fun r => progBind (k r) f)

instance : Monad (Prog sig) where
  pure := pure
  bind := progBind

/-- Interpret a program in a monad `m`, given an algebra (handler) for each operation of `sig`. -/
def interp [Monad m] (alg : {b : Type} → sig b → m b) : Prog sig a → m a
  | pure x   => Pure.pure x
  | bind o k => alg o >>= fun r => (k r).interp alg

end Prog
