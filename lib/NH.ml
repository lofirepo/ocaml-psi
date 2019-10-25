(**
{1 Naive hash-based PSI}

This is an implementation of Private Set Intersection based on naive hashing.
*)

(** Functor building an implementation of Naive Hashing PSI
    given a [Hash] implementation. *)
module Make
         (Hash : Nocrypto.Hash.S)
       : S.NH = struct

  module CSet = Set.Make (Cstruct)
  module CMap = Map.Make (Cstruct)

  type elt = Cstruct.t
  type pset = CSet.t
  type hset = CSet.t

  type t = {
      hset : CSet.t;
      hmap : Cstruct.t CMap.t;
      salt : Cstruct.t;
    }

  let init ?(salt = Cstruct.empty) () =
    { hset = CSet.empty;
      hmap = CMap.empty;
      salt }

  let add elt t =
    let selt = Cstruct.append elt t.salt in
    let helt = Hash.digest selt in
    let hset = CSet.add helt t.hset in
    let hmap = CMap.add helt elt t.hmap in
    { t with hset; hmap }

  let add_set pset t =
    CSet.fold (fun elt t -> add elt t) pset t

  let remove elt t =
    let selt = Cstruct.append elt t.salt in
    let helt = Hash.digest selt in
    let hset = CSet.remove helt t.hset in
    let hmap = CMap.remove helt t.hmap in
    { t with hset; hmap }

  let h2p t hset =
    CSet.fold (fun helt pset ->
        match CMap.find_opt helt t.hmap with
        | Some elt -> CSet.add elt pset
        | None -> pset
      ) hset CSet.empty

  let inter t rset =
    let iset = CSet.inter t.hset rset in
    h2p t iset

  let priv t =
    h2p t t.hset

  let pub t =
    t.hset

end
