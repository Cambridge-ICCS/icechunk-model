import IcechunkModel.ChangeSet

/-- Partial model of `icechunk/src/session.rs` -/

inductive SessionMode
  | Readonly
  | Writable
  | Rearrange
  deriving DecidableEq, Repr

def getNode (s : Snapshot) (cs : EditChanges) (p : Path) : Option Node :=
  match cs.getNewNode p with
  | some n => some n
  | none =>
    match s.nodes.get? p with
    | none => none
    | some n => if cs.isDeleted p n.id then none else some (cs.updateExisting n)


def addGroup (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) (m : Metadata) : EditChanges :=
    if (getNode s cs p).isSome then .error .alreadyExists else .ok (cs.addGroup p id m)

-- TODO: delete_node

def deleteGroup (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) : EditChanges :=
    match getNode s cs p with
    | none => .ok cs
    | some n =>
      if n.kind = .group then
        .ok ((listNodes s cs p).foldl (init := cs) fun acc (q, node) =>
          match node.kind with
          | .group => acc.deleteGroup q node.id
          | .array => acc.deleteArray q node.id)
      else .error .notAGroup

def addArray (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) (m : Metadata) : EditChanges :=
    if (getNode s cs p).isSome then .error .alreadyExists else .ok (addArray s cs p id m)

def updateGroup (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) (m : Metadata) : EditChanges :=    match getNode s cs p with
    | none => .error .nodeNotFound
    | some n => if n.kind = .group then .ok (cs.updateGroup n.id p m) else .error .notAGroup

def updateArray (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) (m : Metadata) : EditChanges :=
    match getNode s cs p with
    | none => .error .nodeNotFound
    | some n => if n.kind = .array then .ok (cs.updateArray n.id p m) else .error .notAnArray

def deleteArray (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) : EditChanges :=
    match getNode s cs p with
    | none => .ok cs
    | some n => if n.kind = .array then .ok (cs.deleteArray p n.id) else .error .notAnArray

def deleteGroup (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) : EditChanges :=
    match getNode s cs p with
    | none => .ok cs
    | some n =>
      if n.kind = .group then
        .ok ((listNodes s cs p).foldl (init := cs) fun acc (q, node) =>
          match node.kind with
          | .group => acc.deleteGroup q node.id
          | .array => acc.deleteArray q node.id)
      else .error .notAGroup
