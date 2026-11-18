import IcechunkModel.ChangeSet

/-! Partial model of `icechunk/src/session.rs` -/

inductive SessionMode
  | Readonly
  | Writable
  | Rearrange
  deriving DecidableEq, Repr

inductive OpError
  | alreadyExists
  | nodeNotFound
  | notAnArray
  | notAGroup
  deriving DecidableEq, Repr

def getNode (s : Snapshot) (cs : EditChanges) (p : Path) : Option NodeSnapshot :=
  match cs.getNewNode p with
  | some n => some n
  | none =>
    match s.nodes.get? p with
    | none => none
    | some n => cs.updateExistingNode n

/-- `list_nodes`: existing nodes under `p`, plus all new nodes (as in the Rust). -/
def listNodes (s : Snapshot) (cs : EditChanges) (p : Path) : List NodeSnapshot :=
  let existing := s.nodes.keys.filterMap fun q =>
    if p.isPrefixOf q then (s.nodes.get? q).bind cs.updateExistingNode else none
  existing ++ cs.newNodes

def addGroup (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) (m : Meta) : Except OpError EditChanges :=
    if (getNode s cs p).isSome then .error .alreadyExists else .ok (cs.addGroup p id m)

-- TODO: delete_node

def addArray (s : Snapshot) (cs : EditChanges) (p : Path) (id : NodeId) (m : ArrayData) : Except OpError EditChanges :=
    if (getNode s cs p).isSome then .error .alreadyExists else .ok (cs.addArray p id m)

def updateGroup (s : Snapshot) (cs : EditChanges) (p : Path) (m : Meta) : Except OpError EditChanges :=
    match getNode s cs p with
    | none => .error .nodeNotFound
    | some n => if n.nodeType = .group then .ok (cs.updateGroup n.id p m) else .error .notAGroup

def updateArray (s : Snapshot) (cs : EditChanges) (p : Path) (m : Meta) : Except OpError EditChanges :=
    match getNode s cs p with
    | none => .error .nodeNotFound
    | some n => if n.nodeType = .array then .ok (cs.updateArray n.id p m) else .error .notAnArray

def deleteArray (s : Snapshot) (cs : EditChanges) (p : Path) : Except OpError EditChanges :=
    match getNode s cs p with
    | none => .ok cs
    | some n => if n.nodeType = .array then .ok (cs.deleteArray p n.id) else .error .notAnArray

def deleteGroup (s : Snapshot) (cs : EditChanges) (p : Path) : Except OpError EditChanges :=
    match getNode s cs p with
    | none => .ok cs
    | some n =>
      if n.nodeType = .group then
        .ok (((listNodes s cs p).filter (p.isPrefixOf ·.path)).foldl (init := cs) fun acc node =>
          match node.nodeType with
          | .group => acc.deleteGroup node.path node.id
          | .array => acc.deleteArray node.path node.id)
      else .error .notAGroup

def setChunkRef (s : Snapshot) (cs : EditChanges) (p : Path) (c : Coord) (v : Option Payload) : Except OpError EditChanges :=
    match getNode s cs p with
    | none => .error .nodeNotFound
    | some n => if n.nodeType = .array then .ok (cs.setChunkRef n.id c v) else .error .notAnArray

/-- `get_chunk_ref`: chunks written in this session take precedence.
 Otherwise the Rust code reads the snapshot's manifests (`get_old_chunk`);
  manifests are not yet modelled, so the base snapshot has no chunks.
  The `valid_chunk_coord` bounds check is omitted. -/
def getChunkRef (s : Snapshot) (cs : EditChanges) (p : Path) (c : Coord) :
    Except OpError (Option Payload) :=
  match getNode s cs p with
  | none => .error .nodeNotFound
  | some n =>
    match n.nodeData with
    | .group => .error .notAnArray
    | .array .. =>
      match cs.getChunkRef n.id c with
      | some res => .ok res
      | none => .ok none -- `get_old_chunk`
