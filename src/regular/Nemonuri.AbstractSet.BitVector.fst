module Nemonuri.AbstractSet.BitVector

module Bv = FStar.BitVector
module USet = Nemonuri.AbstractSet.Under
module S = FStar.Seq
module Ss = FStar.Seq.Sorted
module Sto = Nemonuri.StrictTotalOrder

type t (capacity: nat) : eqtype = Bv.bv_t capacity

let lemma_length #c (set:t c) : Lemma (c = S.length set) = ()

let size #c (set: t c) : nat = S.count true set

let contains #c (set: t c) (index: USet.t c) : bool = S.index set index

let is_greater (a b:int) : prop = a < b

let lemma_is_greater () : Lemma (Sto.is_well_defined is_greater) = ()

private let rec to_seq_core' #c (set: t c) (index: USet.t (c+1))
  : Tot (S.seq (USet.t c)) 
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

(*
let lemma_to_seq #c (set: t c) 
  : Lemma (Sto.is_sorted is_greater (to_seq set)) =
  assert (S.length == c);
  let sorted' = (Sto.is_sorted is_greater) in
  if (c = 0) then () 
  else if (c = 1) then Sto.lemma_singleton binrel 
  else begin
    let lemma_aux' #c (set: t c) (index: USet.t c)
      : Lemma (requires sorted' (to_seq_core' set c index)) 
              (ensures  )
      =

    in
  end
*)

//private let rec lemma_to_set_core' #c (set: t c) (index: USet.t (c+1))
//  : Lemma (ensures Sto.is_sorted is_greater (to_set_core' set index))
//          (decreases (S.length set) - index)
//  =


(*
private let to_seq_core' #c (set: t c) (index: USet.t (c+1)) (prev_result: S.seq (USet.t c))
  : Pure (S.seq (USet.t c)) 
      (requires (S.sorted (<=) prev_result) /\ ((S.length prev_result > 0) ==> (index <= S.head prev_result)))
      (ensures (fun r -> S.sorted (<=) r))
  =
  if index = c then S.empty
  else 
    //let tail_part = (to_seq_core' set (index+1)) in
    if contains set index then begin
      let result = S.cons index prev_result in
      if S.length result > 1 
      then begin
        S.cons_head_tail result;
        assume (prev_result == (S.tail result));
        assert (S.sorted (<=) (S.tail result));
        Ss.sorted_pred_cons_lemma (<=) result
      end else ();
      result
    end else prev_result
*)

(*
private let rec lemma_to_seq_core' #c (set: t c) (index: USet.t (c+1))
  : Lemma (ensures S.sorted (<=) (to_seq_core' set index)) (decreases (S.length set) - index) =
  if index = c then ()
  else 
    let tail_part = (to_seq_core' set (index+1)) in
    if contains set index 
    then if S.length tail_part = 0 then () else 
      begin
        assert (index < (S.head tail_part));
        lemma_to_seq_core' #c set (index+1)
      end
    else lemma_to_seq_core' #c set (index+1)
*)


  





