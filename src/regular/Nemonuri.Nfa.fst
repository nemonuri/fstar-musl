module Nemonuri.Nfa

module R = Nemonuri.RegularLanguage
module Pm = Nemonuri.PartialMap
module I = FStar.IntegerIntervals

(* Reference:
   [1] Xing, G. (2004). Minimized Thompson NFA. International Journal of Computer Mathematics, 81(9), 1097–1106. https://doi.org/10.1080/03057920412331272153 *)

(* A nondeterministic finite automaton (NFA for short) N is defined as a 5-tuple *)
type raw_t = {
  states_length: pos;
  alphabets_length: pos;
  state_transition: ((I.under states_length & option (I.under alphabets_length)) & (list (I.under states_length)));
  initial_state: I.under states_length;
  final_states: list (I.under states_length);
}




