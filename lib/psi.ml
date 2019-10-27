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

{1 Private Set Intersection}

Collection of PSI protocols.

*)

module NH = NH
(** Naive hash-based PSI *)

module BF = BF
(** Bloom filter-based PSI *)

module S = S
(** Signatures *)

module CSet = Set.Make (Cstruct)
(** Cstruct Set *)
