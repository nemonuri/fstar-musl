module Nemonuri.StrictTotalOrder

module S = Nemonuri.Seq
module I = FStar.IntegerIntervals

(* Reference: https://en.wikipedia.org/wiki/Total_order#Strict_and_non-strict_total_orders *)

type binrel_t (a_t:Type) = a_t -> a_t -> prop

//let is_irreflexive_at #a_t (binrel:binrel_t a_t) (a:a_t) : prop = ~(binrel a a)
//let is_irreflexive #a_t (binrel:binrel_t a_t) : prop = forall a. is_irreflexive_at binrel a

let is_asymmetric_at #a_t (binrel:binrel_t a_t) (a0 a1:a_t) : prop =
  (binrel a0 a1) ==> ~(binrel a1 a0)
let is_asymmetric #a_t (binrel:binrel_t a_t) : prop = forall a0 a1. is_asymmetric_at binrel a0 a1

let is_transitive_at #a_t (binrel:binrel_t a_t) (a0 a1 a2:a_t) : prop =
  ((binrel a0 a1) /\ (binrel a1 a2)) ==> (binrel a0 a2)
let is_transitive #a_t (binrel:binrel_t a_t) : prop = forall a0 a1 a2. is_transitive_at binrel a0 a1 a2

let is_total_at #a_t (binrel:binrel_t a_t) (a0 a1:a_t) : prop =
  (~(binrel a0 a1) /\ ~(binrel a1 a0)) ==> (a0 == a1)
let is_total #a_t (binrel:binrel_t a_t) : prop = forall a0 a1. is_total_at binrel a0 a1

let is_well_defined #a_t (binrel:binrel_t a_t) : prop =
  (is_asymmetric binrel) /\ (is_transitive binrel) /\ (is_total binrel)

type t (a_t:Type) = binrel:(binrel_t a_t){is_well_defined binrel}

let is_sorted_in_at 
  #a_t (binrel:t a_t) (seq:S.seq a_t) 
  (imin:I.under (S.length seq)) 
  (emax:I.under (S.length seq + 1))
  (a0 a1:I.interval imin emax) 
  : prop =
  (a0 < a1) ==> (binrel (S.index seq a0) (S.index seq a1))

let is_sorted_in
  #a_t (binrel:t a_t) (seq:S.seq a_t)
  (imin:I.under (S.length seq)) 
  (emax:I.under (S.length seq + 1))
  : prop = 
  forall a0 a1. is_sorted_in_at binrel seq imin emax a0 a1

let is_sorted_at
  #a_t (binrel:t a_t) (seq:S.seq a_t) (a0 a1:I.interval 0 (S.length seq)) : prop =
  is_sorted_in_at binrel seq 0 (S.length seq) a0 a1

let is_sorted #a_t (binrel:t a_t) (seq:S.seq a_t) : prop =
  forall a0 a1. is_sorted_at binrel seq a0 a1

let lemma_is_sorted #a_t (binrel:t a_t) (seq:S.seq a_t{S.length seq > 0}) 
  : Lemma (is_sorted binrel seq <==> is_sorted_in binrel seq 0 (S.length seq)) =
  admit ()

let lemma_empty_interval 
  #a_t (binrel:t a_t) (seq:S.seq a_t)
  (imin:I.under (S.length seq)) 
  (emax:I.under (S.length seq + 1))
  : Lemma (requires imin >= emax)
          (ensures is_sorted_in binrel seq imin emax)
  = ()

let lemma_slice
  #a_t (binrel:t a_t) (seq:S.seq a_t)
  (imin:I.under (S.length seq)) 
  (emax:I.under (S.length seq + 1))
  (imin2:I.interval imin emax)
  (emax2:I.interval imin (emax+1))
  : Lemma (requires is_sorted_in binrel seq imin emax)
          (ensures is_sorted_in binrel seq imin2 emax2)
  =
  let open Nemonuri.Squash in
  let open FStar.Classical in
  let lemma_empty_interval' = (lemma_empty_interval binrel seq) in
  if imin2 >= emax2 then lemma_empty_interval' imin2 emax2
  else if imin >= emax then (assert (imin2 >= emax2); lemma_empty_interval' imin2 emax2)
  else begin
    assert (imin <= imin2) /\ (imin2 < emax2) /\ (emax2 <= emax);
    let p1 = is_sorted_in binrel seq imin emax in
    let p2 = is_sorted_in binrel seq imin2 emax2 in
    let lemma_aux' (imin_n:I.interval imin emax) (imax_n:I.interval imin emax)
      : Lemma (requires imin_n <= imax_n) (ensures is_sorted_in_at binrel seq imin emax imin_n imax_n)
      = ()
    in
    let lemma_aux2' () 
      : Lemma (requires forall imin_n imax_n. (imin_n <= imax_n) ==> is_sorted_in_at binrel seq imin emax imin_n imax_n)
              (ensures forall a0 a1. is_sorted_in_at binrel seq imin2 emax2 a0 a1)
      = 
      let lemma_aux3' (a0 a1: I.interval imin2 emax2) : Lemma (is_sorted_in_at binrel seq imin2 emax2 a0 a1) =
        assert ((a0 <= a1) ==> is_sorted_in_at binrel seq imin emax a0 a1);
        if (not (a0 <= a1)) then ()
        else begin
          assert (is_sorted_in_at binrel seq imin emax a0 a1);
          assert (is_sorted_in_at binrel seq imin2 emax2 a0 a1)
        end
      in
      lemma_aux3' |> forall_intro_2
    in
    move_requires lemma_aux2' ();
    lemma_aux' |> move_requires_2 |> forall_intro_2;
    assert (is_sorted_in binrel seq imin2 emax2)
  end
  

let lemma_empty #a_t (binrel:t a_t) : Lemma (is_sorted binrel (S.empty)) = ()

let lemma_length_0 #a_t (binrel:t a_t) (seq:S.seq a_t{S.length seq == 0}) : Lemma (is_sorted binrel seq) =
  let open Nemonuri.Squash in
  let pa: prop = (S.length seq == 0) in
  let pc: prop = (is_sorted binrel seq) in
  prove_step pa pc (calc (==>) {
    pa;
      ==> { S.lemma_empty seq }
    seq == S.empty;
      ==> { lemma_empty binrel }
    pc;
  })

let lemma_singleton #a_t (binrel:t a_t) (a:a_t) : Lemma (is_sorted binrel (S.singleton a)) = ()

let compare_head #a_t (binrel:t a_t) (a:a_t) (seq:S.seq a_t) : prop = (S.length seq > 0) ==> (binrel a (S.head seq))

let lemma_tail #a_t (binrel:t a_t) (seq:S.seq a_t{S.length seq > 0})
  : Lemma (requires (is_sorted binrel seq)) 
          (ensures (is_sorted binrel (S.tail seq)))
  =
  let tail_seq = (S.tail seq) in
  if not (S.length seq > 1) then (assert (S.length tail_seq = 0); lemma_length_0 binrel tail_seq)
  else begin
    lemma_is_sorted binrel seq;
    lemma_slice binrel seq 0 (S.length seq) 1 (S.length seq);
    assert (is_sorted_in binrel seq 1 (S.length seq));
    assume (is_sorted_in binrel tail_seq 0 (S.length tail_seq));
    lemma_is_sorted binrel tail_seq;
    assert (is_sorted binrel tail_seq)
  end

let lemma_cons_tail #a_t (a:a_t) (seq:S.seq a_t)
  : Lemma (S.tail (S.cons a seq) == seq) =
  S.append_slices (S.singleton a) seq;
  let seq2 = (S.tail (S.cons a seq)) in
  assert (S.equal seq2 seq);
  S.lemma_eq_elim seq2 seq

val lemma_cons #a_t (binrel:t a_t) (a:a_t) (seq:S.seq a_t)
  : Lemma (requires (is_sorted binrel seq) /\ (compare_head binrel a seq))
          (ensures (is_sorted binrel (S.cons a seq)))  
          (decreases S.length seq)
let rec lemma_cons #a_t (binrel:t a_t) (a:a_t) (seq:S.seq a_t) =
  let open FStar.Classical in
  let sgt = S.singleton a in
  if S.length seq = 0 then begin
    S.lemma_empty seq;
    assert (seq == S.empty);
    S.append_empty_r sgt;
    lemma_singleton binrel a
  end else begin
    let coned_seq = S.cons a seq in
    lemma_cons_tail a seq;
    assert (S.tail coned_seq == seq);
    let lemma_aux' a0 a1
      : Lemma (is_sorted_in_at binrel coned_seq 0 (S.length coned_seq) a0 a1) =
      admit ()
    in
    lemma_aux' |> forall_intro_2
  end




