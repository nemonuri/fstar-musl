module Nemonuri.RegularLanguage

module I = FStar.IntegerIntervals

(* Reference: https://en.wikipedia.org/wiki/Regular_language *)
type alphabet_t (k:pos) = I.under k

type t (k:pos) = 
(* The empty language ∅ is a regular language. *)
| Empty
(* For each a ∈ Σ (a belongs to Σ), the singleton language {a} is a regular language. *)
| Singleton: (alphabet_t k) -> t k
(* If A is a regular language, A* (Kleene star) is a regular language. Due to this, the empty string language {ε} is also regular. *)
| KleeneStar: (t k) -> t k
(* If A and B are regular languages, then A ∪ B (union) and A • B (concatenation) are regular languages. *)
| Union: (left:t k) -> (right:t k) -> t k
| Concat: (left:t k) -> (right:t k) -> t k



