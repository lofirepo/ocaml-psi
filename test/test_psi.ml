open OUnit2
open Printf

module NH = Psi.NH.Make (Nocrypto.Hash.SHA512)
module BF = Psi.BF.Make (Nocrypto.Hash.SHA512)
module CSet = Psi.CSet

let seta = CSet.of_list @@
             List.map (fun e -> Cstruct.of_string e)
               [ "A"; "B"; "C"; "M"; "X"; "Y"; "Z" ]
let setb = CSet.of_list @@
             List.map (fun e -> Cstruct.of_string e)
               [ "C"; "D"; "E"; "M"; "V"; "W"; "X" ]
let setx = CSet.of_list @@
             List.map (fun e -> Cstruct.of_string e)
               [ "C"; "M"; "X" ]

let print_set set name =
  printf "%s = " name;
  CSet.iter (fun e -> printf "%s" (Cstruct.to_string e)) set;
  printf "\n"

let print_set_hex set name =
  printf "%s = " name;
  CSet.iter (fun e -> Cstruct.hexdump e ) set;
  printf "\n"

let print_bitv bitv name =
  printf "%s = " name;
  List.iter (fun e -> printf "%3d " e) (Bitv.to_list bitv);
  printf "\n"

let test_nh _ctx =
  printf "\nTest NH\n\n";
  print_set seta "Set A  ";
  print_set setb "Set B  ";
  print_set setx "Inter  ";

  let salt = Cstruct.of_string "Node1Node2" in

  let nha = NH.init ~salt () in
  let nha = NH.add_set seta nha in

  let nhb = NH.init ~salt () in
  let nhb = NH.add_set setb nhb in

  let nha = NH.add (Cstruct.of_string "O") nha in
  let nhb = NH.add (Cstruct.of_string "O") nhb in
  let nha = NH.remove (Cstruct.of_string "O") nha in
  let nhb = NH.remove (Cstruct.of_string "O") nhb in

  let priva = NH.priv nha in
  let puba = NH.pub nha in
  print_set priva "Priv A ";
  assert_equal (CSet.equal priva seta) true;

  let privb = NH.priv nhb in
  let pubb = NH.pub nhb in
  print_set privb "Priv B ";
  assert_equal (CSet.equal privb setb) true;

  let setia = NH.inter nha pubb in
  print_set setia "Inter A";
  assert_equal (CSet.equal setia setx) true;

  let setib = NH.inter nhb puba in
  print_set setib "Inter B";
  assert_equal (CSet.equal setib setx) true

let test_bf _ctx =
  printf "\nTest BF\n\n";
  print_set seta "Set A  ";
  print_set setb "Set B  ";
  print_set setx "Inter  ";

  let salt = Cstruct.of_string "Node1Node2" in

  let bfa = BF.init ~salt 10 in
  let bfa = BF.add_set seta bfa in
  let priva = BF.priv bfa in
  let puba = BF.pub bfa in

  print_set priva "Priv A ";
  print_bitv puba "Pub A  ";

  let bfb = BF.init ~salt 10 in
  let bfb = BF.add_set setb bfb in
  let privb = BF.priv bfb in
  let pubb = BF.pub bfb in

  print_set privb "Priv B ";
  print_bitv pubb "Pub B  ";

  let (rrand, ckey, cset, isetb) = BF.cr_resp bfb ~bf:puba in
  print_set isetb "isetb  ";
  let (irand, rset, iseta) = BF.cr_init bfa ~rrand ~ckey ~cset in
  print_set iseta "iseta  ";
  let isetb = BF.cr_resp2 bfb ~irand ~rrand ~rset ~iset:isetb in
  print_set isetb "isetb  ";

  assert_equal (CSet.equal iseta setx) true;
  assert_equal (CSet.equal isetb setx) true

let suite =
  "suite">:::
    [
      "nh">:: test_nh;
      "bf">:: test_bf;
    ]

let () =
  Nocrypto_entropy_unix.initialize ();
  run_test_tt_main suite
