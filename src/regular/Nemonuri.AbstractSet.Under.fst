module Nemonuri.AbstractSet.Under

module I = FStar.IntegerIntervals

type t (size:nat) : eqtype = I.under size

let contains (size:nat) (elem:int) : bool =
  I.interval_condition 0 size elem

let lemma_contains (size:nat) (elem:t size) : Lemma (contains size elem) = ()

let lemma_add (size:nat) (size_extend:nat) (elem:t size)
  : Lemma (contains (size + size_extend) (elem + size_extend)) =
  ()

let add_and_coerce (size:nat) (size_extend:nat) (elem:t size) 
  : Tot (t (size+size_extend)) =
  (elem) + size_extend