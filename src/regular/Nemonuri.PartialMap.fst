module Nemonuri.PartialMap

module S = FStar.Seq
module USet = Nemonuri.AbstractSet.Under
module L = FStar.List.Tot

type cell_t (kl:pos) (vl:pos) = (USet.t kl & USet.t vl)

type raw_t (kl:pos) (vl:pos) = S.seq (cell_t kl vl)

let empty #kl #vl : raw_t kl vl = S.empty

let is_greater_or_equal #kl #vl (left:cell_t kl vl) (right:cell_t kl vl) : bool = 
  (fst left) >= (fst right)

let to_keys #kl #vl (map:raw_t kl vl) : list (USet.t kl) = L.unzip (S.seq_to_list map) |> fst

let to_values #kl #vl (map:raw_t kl vl) : list (USet.t vl) = L.unzip (S.seq_to_list map) |> snd

let rec contains_key #kl #vl (map:raw_t kl vl) (key:USet.t kl)
  : Tot bool (decreases (S.length map)) =
  if S.length map = 0 then false
  else if (fst (S.head map)) = key then true 
  else contains_key (S.tail map) key

val index_of_key #kl #vl (map:raw_t kl vl) (key:USet.t kl{contains_key map key}) : Tot (x:nat{x < S.length map})
let rec index_of_key #kl #vl map key : Tot nat (decreases (S.length map)) =
  if (fst (S.head map)) = key then 0
  else 1 + (index_of_key (S.tail map) key)

let update #kl #vl (map:raw_t kl vl) (key:USet.t kl{contains_key map key}) (value:USet.t vl)
  : raw_t kl vl =
  let idx = index_of_key map key in
  let cell = (key, value) in
  if (S.index map idx) = cell then map
  else S.upd map idx cell

val insert #kl #vl (map:raw_t kl vl) (key:USet.t kl{not (contains_key map key)}) (value:USet.t vl) 
  : Tot (x:raw_t kl vl{S.length x = (S.length map + 1)})
let rec insert #kl #vl map key value
  : Tot (raw_t kl vl) (decreases (S.length map)) =
  let new_head_cell = (key, value) in
  if S.length map = 0 then S.seq_of_list [new_head_cell]
  else 
    let cur_head_cell = S.head map in
    if (new_head_cell) `is_greater_or_equal` (cur_head_cell) 
    then S.cons new_head_cell map
    else S.cons cur_head_cell (insert (S.tail map) key value)

let insert_or_update #kl #vl (map:raw_t kl vl) (key:USet.t kl) (value:USet.t vl) : raw_t kl vl =
  if (contains_key map key) 
  then update map key value
  else insert map key value

let try_select #kl #vl (map:raw_t kl vl) (key:USet.t kl) : option (USet.t vl) =
  L.assoc key (S.seq_to_list map)


let is_sorted #kl #vl (map:raw_t kl vl) : bool = S.sorted (is_greater_or_equal #kl #vl) map

let are_keys_distinct #kl #vl (map:raw_t kl vl) : bool = L.noRepeats (to_keys map)

let is_well_formed #kl #vl (map:raw_t kl vl) : bool = (is_sorted map) && (are_keys_distinct map)


let are_keys_sorted #kl #vl (map:raw_t kl vl) : bool = L.sorted (>=) (to_keys map)


type t (kl:pos) (vl:pos) = x:(raw_t kl vl){is_well_formed x}

//--- properties ---
let lemma_'is_sorted'_and_'are_keys_sorted'_are_same #kl #vl (map:raw_t kl vl)
  : Lemma ((is_sorted map) = (are_keys_sorted map)) =
  let open FStar.Classical in
  let pl: prop = (is_sorted map) in
  let pr: prop = (are_keys_sorted map) in
  let lemma_l_to_r () : Lemma (requires pl) (ensures pr) =
    admit ()
  in
  let lemma_r_to_t () : Lemma (requires pr) (ensures pl) =
    admit ()
  in
  move_requires lemma_l_to_r ();
  move_requires lemma_r_to_t ()

let lemma_'update'_is_keys_invariant #kl #vl (map:raw_t kl vl) (key:USet.t kl{contains_key map key}) (value:USet.t vl)
  : Lemma (to_keys map = to_keys (update map key value)) =
  let next_map = update map key value in
  let idx = index_of_key map key in
  let cell: cell_t kl vl = (key, value) in
  if (S.index map idx) = cell then assert (map = next_map)
  else assume (to_keys map = to_keys (update map key value))

let lemma_empty_is_well_formed (kl:pos) (vl:pos)
  : Lemma (is_well_formed (empty #kl #vl)) =
  ()

let lemma_insert_or_update_is_well_formed #kl #vl (map:t kl vl) (key:USet.t kl) (value:USet.t vl)
  : Lemma (is_well_formed (insert_or_update map key value)) =
  let open Nemonuri.Squash in
  let open FStar.Calc in
  if (contains_key map key)
  then 
    let lemma_update_is_well_formed' () 
      : Lemma (is_well_formed (update map key value)) =
      let next_map = update map key value in
      prove_step_b (is_well_formed map) (is_sorted next_map) (calc (==>) {
        is_well_formed map |> b2t;
          ==> { assert (is_sorted map); lemma_'is_sorted'_and_'are_keys_sorted'_are_same map }
        are_keys_sorted map |> b2t;
          ==> { lemma_'update'_is_keys_invariant map key value }
        are_keys_sorted next_map |> b2t;
          ==> { lemma_'is_sorted'_and_'are_keys_sorted'_are_same next_map }
        is_sorted next_map;
      });
      prove_step_b (is_well_formed map) (are_keys_distinct next_map) (calc (==>) {
        is_well_formed map |> b2t;
          ==> { }
        are_keys_distinct map |> b2t;
          ==> { lemma_'update'_is_keys_invariant map key value }
        are_keys_distinct next_map;
      })
    in
    lemma_update_is_well_formed' ()
  else 
    let lemma_insert_is_well_formed' ()
      : Lemma (is_well_formed (insert map key value)) =
      let next_map = insert map key value in
      admit ()
    in
    lemma_insert_is_well_formed' ()
  
//---|
(*
type t (kl:pos) (vl:pos) : raw_t kl vl -> eqtype =
| Empty: t kl vl (empty #kl #vl)
| InsertOrUpdate: 
    (#raw_map:raw_t kl vl) ->
    (map:t kl vl raw_map) -> 
    (key:USet.t kl) -> 
    (value:USet.t vl) -> t kl vl raw_map
*)



