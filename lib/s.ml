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

(** Naive hash-based PSI *)
module type NH = sig

  type t

  type elt = Cstruct.t
  (** Plaintext element *)

  type pset = Set.Make(Cstruct).t
  (** Plaintext set *)

  type hset = Set.Make(Cstruct).t
  (** Hashed set *)

  val init : ?salt:Cstruct.t -> unit -> t
  (** [init ?salt ?set ()] initializes a NH PSI instance.

      @param ?salt  Salt for hashing elements *)

  val add : elt -> t -> t
  (** [add elem t] adds [elt] to the set *)

  val add_set : pset -> t -> t
  (** [add_set pset t] adds [pset] of elements to the set *)

  val remove : elt -> t -> t
  (** [remove elem t] removes [elt] from the set *)

  val inter : t -> hset -> pset
  (** [inter t hset] computes the intersection of a private,
      plaintext set and a public, hashed set *)

  val priv : t -> pset
  (** [priv t] returns the set of private, plaintext set *)

  val pub : t -> hset
  (** [pub t] returns the set of public, hashed set *)

end

(** Bloom filter-based PSI *)
module type BF = sig

  type t

  type elt = Cstruct.t
  (** Plaintext element *)

  type pset = Set.Make(Cstruct).t
  (** Plaintext set *)

  val init : ?salt:Cstruct.t -> ?key_len:int -> ?rng:Nocrypto.Rng.g
             -> ?error_rate:float -> int -> t
  (** [init ?salt ?error_rate ?set size] initializes a BF PSI instance.

      @param ?salt        Salt for hashing elements
      @param ?key_len     Byte length of random tokens generated
      @param ?rng         Random number generator; defaults to global generator
                          which must be seeded prior to using this module;
                          see {!Nocrypto.Rng}
      @param ?error_rate  Bloom filter error rate
      @param size         Expected number of elements in Bloom filter;
                          see {!Bloomf.create} *)

  val add : elt -> t -> t
  (** [add elem t] adds [elem] to the Bloom filter *)

  val add_set : pset -> t -> t
  (** [add_set pset t] adds [pset] of elements to the Bloom filter *)

  val cr_resp : t -> bf:Bitv.t ->
                (Cstruct.t * Cstruct.t * pset * pset)
  (** 1st step of the challenge-response protocol, run by the responder.

      @param bf  Initiator's Bloom filter

      @return [(rrand, ckey, cset, iset)]
      @param rrand  Responder's random value
      @param ckey   Challenge HMAC key
      @param cset   Challenge set with HMAC values
                    of candidate intersection elements
      @param iset   Candidate intersection set with plaintext elements  *)

  val cr_init : t -> rrand:Cstruct.t -> ckey:Cstruct.t -> cset:pset
                -> (Cstruct.t * pset * pset)
  (** 2nd step of the challenge-response protocol, run by the initiator.

      @param rrand  Responder's random value
      @param ckey   Challenge HMAC key
      @param cset   Challenge set with HMAC values
                    of candidate intersection elements

      @return [(irand, rset, iset)]
      @param irand  Initiator's random value
      @param rset   Response set with HMAC values of intersection elements
      @param iset   Final intersection set with plaintext elements *)

  val cr_resp2 : t -> irand:Cstruct.t -> rrand:Cstruct.t
                 -> rset:pset -> iset:pset
                 -> pset
  (** 3rd step of the challenge-response protocol, run by the responder.

      @param irand  Initiator's random value
      @param rrand  Responder's random value
      @param rset   Response set with HMAC values of intersection elements
      @param iset   Candidate intersection set returned by [cr_resp]
                    in the 1st step

      @return Final intersection set with plaintext elements *)

  val priv : t -> pset
  (** [priv t] returns the set of private, plaintext elements *)

  val pub : t -> Bitv.t
  (** [pub t] returns the bit vector representation
      of the Bloom filter with all elements added *)

end
