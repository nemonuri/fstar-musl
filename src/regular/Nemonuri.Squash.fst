module Nemonuri.Squash

module I = FStar.IntegerIntervals
open FStar.Squash

let prove (p: prop) (x: squash p) : Pure unit (requires True) (ensures (fun _ -> p)) = ()

let prove_b (b: bool) (x: squash (b2t b)) = prove (b2t b) x

let prove_implies (pa: prop) (pc: prop) (x: squash (pa ==> pc)) = prove (pa ==> pc) x

let prove_step (p1: prop) (p2: prop) (x: squash (p1 ==> p2)) 
  : Pure unit (requires p1) (ensures (fun _ -> p2)) =
  ()

let prove_step_b (p1: bool) (p2: bool) (x: squash (p1 ==> p2))
  : Pure unit (requires p1) (ensures (fun _ -> p2)) =
  prove_step (b2t p1) (b2t p2) x

let rec prove_induct
  (predicate: nat -> prop)
  (step: (index:nat) -> Lemma (requires predicate index) (ensures predicate (index+1)))
  (zero_proof: squash (predicate 0))
  (desired_index: nat)
  : Lemma (ensures predicate desired_index)
          (decreases desired_index) 
  =
  match desired_index with
  | 0 -> zero_proof
  | v -> prove (predicate desired_index) 
               (prove_induct predicate step zero_proof (desired_index-1); step (desired_index-1))

let prove_induct_decr
  (imin: int) (emax: int{imin < emax})
  (predicate: (I.interval imin emax) -> prop)
  (step: (index:I.interval (imin+1) emax) -> Lemma (requires predicate index) (ensures predicate (index-1)))
  (first_proof: squash (predicate (emax-1)))
  : Lemma (predicate imin) =
  let to_source_index (index:nat) : int = (emax-1) - index in
  let to_target_index (source_index:I.interval imin emax) : nat = (emax-1) - source_index in
  let predicate' (index:nat) : prop = 
    let source_index = to_source_index index in
    (I.interval_condition imin emax source_index) ==> (predicate source_index) 
  in
  let lemma_step' (index:nat)
    : Lemma (requires predicate' index) (ensures predicate' (index+1)) =
    let source_index = to_source_index index in
    if (not (I.interval_condition (imin+1) emax source_index)) then () 
    else prove (predicate (source_index-1)) (assert (predicate source_index); step source_index)
  in
  let lemma_zero' () : Lemma (predicate' 0) =
    let source_zero = to_source_index 0 in
    prove (predicate source_zero) (first_proof)
  in
  prove_induct predicate' lemma_step' (lemma_zero' ()) (to_target_index imin)


include FStar.Calc