module Nemonuri.Intension.Meta

(**
# 내포적 의미 기반 프로그램 검증 및 컴파일

## 들어가기

- 주어진 프로그램의 유효성을 검증하기 위한 많은 기술들이 이미 많이 개발되었고, 많은 학자들에 의해 활발하게 연구중이다.
  - Lamda calculus, Hoare logic, Separation logic 등 

- 프로그램의 유효성 검증은, 주어진 프로그램의 각 명령어가 실행될 때 마다 Heap 과 Value 가 주어진 논리식을 만족시킨다는 것을 증명하는 방식으로 동작한다.
  - 즉, 프로그램의 '외연적 의미'를 검증한다.

- 프로그램의 외연적 의미 검증의 한계
  - 한계1: 현실 프로그램은 '일관된 값'을 증명하기 어렵다.
    - 언제, 어떤 외부 프로세스에 의해 Heap 의 어느 위치의 값이 어떻게 변경될지 알 수 없다.
    - 매 순간마다 값이 변하는 것이 의도된 사양인 Heap 도 있다.
      - CPU Clock, 난수 생성기
  - 한계2: 반복문이 포함된 프로그램에 대해, '이 프로그램은 정지한다/하지 않는다'를 증명하기 어렵다.
  - **한계3**: 현실에서는, '한계1'과 '한계2'가 몇 겹으로 중첩된 프로시저가 '기본 api'로서 사용된다!
    - Spin lock, mutex
    - thread init, join
    - barrier, voliate
    - file stream (read, write)

- Posix C 표준 라이브러리에도 '못 믿을 값'을 '반복문'에 넣어 실행한다는 의미의 api 가 가득하다.
  - 즉, 현실에서 외연적 의미 검증을 유용하게 쓸 수 있는 범위는 생각보다 좁다.

- 그래서 나는 대안으로 프로그램의 '내포적 의미 검증'을 제안한다.

## 예시: Atomic compare and swap (a_cas)
*)

module U = FStar.UInt
module U32 = FStar.UInt32
open FStar.FunctionalExtensionality
module F = FStar.FunctionalExtensionality
module Seq = FStar.Seq

type bit_width_t = nat

type lifted_t (a_t:Type) = 
| Value: (v:a_t) -> lifted_t a_t
| Poison (* Bottom *)

type addr_t (bw:bit_width_t) : eqtype = lifted_t (U.uint_t bw)

type stream_t (bw:bit_width_t) = nat ^-> (U.uint_t bw)

type cell_t (a_t:Type) = lifted_t a_t

noeq
type config_t = {
  bit_width: bit_width_t;
  stream: stream_t bit_width;
}

let to_addr_type (cfg:config_t) = addr_t cfg.bit_width
let to_cell_value_type (cfg:config_t) = (U.uint_t cfg.bit_width)
let to_cell_type (cfg:config_t) = (cell_t (to_cell_value_type cfg))

let select0 (cfg:config_t) (n:nat) (addr:(to_addr_type cfg)) : (to_cell_type cfg) =
  match addr with
  | Value _ -> cfg.stream n |> Value
  | Poison -> Poison
   
let update0 (cfg:config_t) (addr:(to_addr_type cfg)) (cell:(to_cell_type cfg)) : unit = ()

(*
Reference:
- https://github.com/bminor/musl/blob/v1.2.5/src/internal/atomic.h
- https://en.wikipedia.org/wiki/Compare-and-swap#Implementation_in_C
*)
let rec a_cas0 
  (cfg:config_t) (n:nat) 
  (addr:(to_addr_type cfg)) 
  (expected:(to_cell_value_type cfg))
  (source:(to_cell_value_type cfg))
  : Dv (to_cell_type cfg) 
  =
  match addr with
  | Poison -> Poison
  | Value _ -> 
  begin
    let old = select0 cfg n addr in
    if old = Value expected then
    begin
      update0 cfg addr (Value source); (* Try store *)
      let cur = select0 cfg (n+1) addr in
      if cur = Value source then old (* Check store successed *)
        else a_cas0 cfg (n+2) addr expected source (* Recursion *)
    end
    else old
  end

