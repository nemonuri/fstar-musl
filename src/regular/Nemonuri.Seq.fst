module Nemonuri.Seq

include FStar.Seq

let singleton (#a_t:Type) (a:a_t) : seq a_t = create 1 a
