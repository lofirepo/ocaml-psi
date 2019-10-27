(*
  Copyright (C) 2019 TG x Thoth

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*)

(**
{1 Bloom filter-based PSI}

This an implementation of the Private Set Intersection protocol based on Bloom filters as described in the paper
{{:https://eprint.iacr.org/2013/620} Do I know you? -- Efficient and Privacy-Preserving Common Friend-Finder Protocols and Applications}
*)

(** Functor building an implementaticon of Bloom filter-based PSI
    given a [Hash] implementation. *)
module Make
         (Hash : Nocrypto.Hash.S)
       : S.BF = struct

  module Kdf = Hkdf.Make (Hash)
  module CSet = Set.Make (Cstruct)

  type elt = Cstruct.t
  type pset = CSet.t

  type t = {
      pset : CSet.t;
      bf : Cstruct.t Bloomf.t;
      salt : Cstruct.t;
      seed : int;
      key_len : int;
      error_rate : float;
      size : int;
      rng : Nocrypto.Rng.g option;
    }

  let init
        ?(salt = Cstruct.empty)
        ?(key_len = 32)
        ?rng
        ?(error_rate = 0.01)
        size =
    let seed = Hashtbl.hash salt in
    { pset = CSet.empty;
      bf = Bloomf.create ~error_rate ~seed size;
      key_len;
      salt;
      error_rate;
      seed;
      size;
      rng }

  let add elt t =
    let selt = Cstruct.append elt t.salt in
    Bloomf.add t.bf selt;
    let pset = CSet.add elt t.pset in
    { t with pset }

  let add_set pset t =
    CSet.fold (fun elt t -> add elt t) pset t

  (** Candidate intersection based on Bloom filter tests *)
  let inter_bf t bits =
    let rbf = Bloomf.create ~error_rate:t.error_rate ~seed:t.seed ~bits
                t.size in
    CSet.fold
      (fun elt iset ->
        let selt = Cstruct.append elt t.salt in
        if Bloomf.mem rbf selt
        then CSet.add elt iset
        else iset)
      t.pset CSet.empty

  let inter_set t lset rset key =
    CSet.fold
      (fun elt iset ->
        let selt = Cstruct.append elt t.salt in
        let helt = Hash.hmac ~key selt in
        if CSet.mem helt rset
        then CSet.add elt iset
        else iset)
      lset CSet.empty

  (** Map each element of the intersection set [iset]
      to its HMAC with given [key] *)
  let crset t iset key =
    CSet.map
      (fun elt ->
        let selt = Cstruct.append elt t.salt in
        Hash.hmac ~key selt)
      iset

  let rkey t irand rrand =
    let ikm = Cstruct.append irand rrand in
    Kdf.extract ~salt:t.salt ikm

  let cr_resp t ~bf =
    let ckey = Nocrypto.Rng.generate ?g:t.rng t.key_len in
    let rrand = Nocrypto.Rng.generate ?g:t.rng t.key_len in
    let iset = inter_bf t bf in
    let cset = crset t iset ckey in
    (rrand, ckey, cset, iset)

  let cr_init t ~rrand ~ckey ~cset =
    let irand = Nocrypto.Rng.generate ?g:t.rng t.key_len in
    let rkey = rkey t irand rrand in
    let iset = inter_set t t.pset cset ckey in
    let rset = crset t iset rkey in
    (irand, rset, iset)

  let cr_resp2 t ~irand ~rrand ~rset ~iset =
    let rkey = rkey t irand rrand in
    let iset = inter_set t iset rset rkey in
    iset

  let priv t =
    t.pset

  let pub t =
    Bloomf.bits t.bf

end
