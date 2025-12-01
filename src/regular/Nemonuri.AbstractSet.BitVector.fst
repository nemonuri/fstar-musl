module Nemonuri.AbstractSet.BitVector

module Bv = FStar.BitVector
module USet = Nemonuri.AbstractSet.Under
module S = FStar.Seq
module Ss = FStar.Seq.Sorted
module Sto = Nemonuri.StrictTotalOrder
module I = FStar.IntegerIntervals

type t (capacity: nat) : eqtype = Bv.bv_t capacity

let lemma_length #c (set:t c) : Lemma (c = S.length set) = ()

let size #c (set: t c) : nat = S.count true set

let contains #c (set: t c) (index: USet.t c) : bool = S.index set index

let is_greater (a b:int) : prop = a < b

let lemma_is_greater () : Lemma (Sto.is_well_defined is_greater) = ()

private let rec to_seq_core' #c (set: t c) (index: USet.t (c+1))
  : Pure (S.seq (USet.t c)) 
         (requires True)
         (ensures (fun r -> S.for_all ((<=) index) r))
         (decreases (S.length set) - index)
  =
  if index = c then S.empty
  else let tail_part = to_seq_core' set (index+1) in
  if contains set index then S.cons index tail_part 
  else tail_part

let to_seq #c (set: t c) : (S.seq (USet.t c)) = to_seq_core' set 0

let lemma_to_seq_length #c (set: t c)
  : Lemma (S.length (to_seq set) <= S.length set) =
  let open Nemonuri.Squash in
  lemma_length set;
  if (c = 0) then assert (S.length (to_seq set) = c) else
  let pred (index: USet.t (c+1)) : prop = (S.length (to_seq_core' set index)) <= (c - index) in
  let lemma_step' (index: USet.t (c+1){index > 0})
    : Lemma (requires pred index)
            (ensures pred (index-1))
    = 
    let index' = index-1 in
    let tail_seq = to_seq_core' set (index'+1) in
    let cons_seq = S.cons index' tail_seq in
    assert (S.length tail_seq <= (c - (index'+1)));
    if contains set index' then begin
      assert (S.length cons_seq = S.length tail_seq + 1);
      assert (pred index')
    end else assert (S.length tail_seq <= (c - (index')))
  in
  prove_induct_decr 0 (c+1) pred lemma_step' (assert (S.length (to_seq_core' set c) == 0))

let lemma_to_seq #c (set: t c) 
  : Lemma (Sto.is_sorted is_greater (to_seq set)) =
  assert (S.length set == c);
  let open Nemonuri.Squash in
  if (c = 0) then () 
  else if (c = 1) then begin
    let to_seq_length = S.length (to_seq set) in
    prove (to_seq_length <= 1) (lemma_to_seq_length set);
    match to_seq_length with
    | 0 -> ()
    | 1 -> Sto.lemma_singleton_seq is_greater (to_seq set) 
  end else begin
    assert (c >= 2);
    let step_pred (index:USet.t (c+1)) : prop = Sto.is_sorted is_greater (to_seq_core' set index) in
    let lemma_aux' (index: USet.t (c+1){index > 0})
      : Lemma (requires step_pred index) 
              (ensures step_pred (index-1))
      =
      let p_goal = step_pred (index-1) in
      let index' = index-1 in
      let tail_seq = to_seq_core' set (index'+1) in
      let cons_seq = S.cons index' tail_seq in
      if contains set index' then begin 
        assert (Sto.compare_head is_greater index' tail_seq);
        Sto.lemma_cons is_greater index' tail_seq;
        assert p_goal
      end else assert p_goal
    in
    prove_induct_decr 0 (c+1) step_pred lemma_aux' (assert (S.length (to_seq_core' set c) == 0))
  end

