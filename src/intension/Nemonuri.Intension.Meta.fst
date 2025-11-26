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

module U32 = FStar.UInt32
open FStar.FunctionalExtensionality
module F = FStar.FunctionalExtensionality
module Seq = FStar.Seq

type addr_t = U32.t

type stream_t (n:nat) = nat ^-> U32.t

type cell_t =
| Value of U32.t
| Poison

type heap_t = Seq.seq cell_t

let size (heap:heap_t) : nat = Seq.length heap

let select (addr:addr_t) (heap:heap_t) : cell_t =
  let addr_nat = U32.v addr in
  match addr_nat < (size heap) with
  | true -> Seq.index heap addr_nat
  | false -> Poison
   
let extend (goal_size:nat) (heap:heap_t) 
  : Tot (x:heap_t{goal_size <= (size x)}) =
  match goal_size <= (size heap) with
  | true -> heap
  | false -> 
  begin
    let size_diff: pos = goal_size - (size heap) in
    let right_heap: heap_t = Seq.create size_diff Poison in
    Seq.append heap right_heap
  end

//let update (addr:addr_t) (heap:heap_t) : (heap)
  


