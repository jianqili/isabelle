(*  Title:      Codatatype_Examples/Misc_Data.thy
    Author:     Dmitriy Traytel, TU Muenchen
    Author:     Andrei Popescu, TU Muenchen
    Copyright   2012

Miscellaneous codatatype declarations.
*)

header {* Miscellaneous Codatatype Declarations *}

theory Misc_Codata
imports "../Codatatype"
begin

codata_raw simple: 'a = "unit + unit + unit + unit"

codata_raw stream: 's = "'a \<times> 's"

codata_raw llist: 'llist = "unit + 'a \<times> 'llist"

codata_raw some_passive: 'a = "'a + 'b + 'c + 'd + 'e"

(*
  ('a, 'b1, 'b2) F1 = 'a * 'b1 + 'a * 'b2
  ('a, 'b1, 'b2) F2 = unit + 'b1 * 'b2
*)

codata_raw F1: 'b1 = "'a \<times> 'b1 + 'a \<times> 'b2"
and F2: 'b2 = "unit + 'b1 * 'b2"

codata_raw EXPR:   'E = "'T + 'T \<times> 'E"
and TERM:   'T = "'F + 'F \<times> 'T"
and FACTOR: 'F = "'a + 'b + 'E"

codata_raw llambda:
  'trm = "string +
          'trm \<times> 'trm +
          string \<times> 'trm +
          (string \<times> 'trm) fset \<times> 'trm"

codata_raw par_llambda:
  'trm = "'a +
          'trm \<times> 'trm +
          'a \<times> 'trm +
          ('a \<times> 'trm) fset \<times> 'trm"

(*
  'a tree = Empty | Node of 'a * 'a forest      ('b = unit + 'a * 'c)
  'a forest = Nil | Cons of 'a tree * 'a forest ('c = unit + 'b * 'c)
*)

codata_raw tree:     'tree = "unit + 'a \<times> 'forest"
and forest: 'forest = "unit + 'tree \<times> 'forest"

codata_raw CPS: 'a = "'b + 'b \<Rightarrow> 'a"

codata_raw fun_rhs: 'a = "'b1 \<Rightarrow> 'b2 \<Rightarrow> 'b3 \<Rightarrow> 'b4 \<Rightarrow> 'b5 \<Rightarrow> 'b6 \<Rightarrow> 'b7 \<Rightarrow> 'b8 \<Rightarrow> 'b9 \<Rightarrow> 'a"

codata_raw fun_rhs': 'a = "'b1 \<Rightarrow> 'b2 \<Rightarrow> 'b3 \<Rightarrow> 'b4 \<Rightarrow> 'b5 \<Rightarrow> 'b6 \<Rightarrow> 'b7 \<Rightarrow> 'b8 \<Rightarrow> 'b9 \<Rightarrow> 'b10 \<Rightarrow>
                    'b11 \<Rightarrow> 'b12 \<Rightarrow> 'b13 \<Rightarrow> 'b14 \<Rightarrow> 'b15 \<Rightarrow> 'b16 \<Rightarrow> 'b17 \<Rightarrow> 'b18 \<Rightarrow> 'b19 \<Rightarrow> 'b20 \<Rightarrow> 'a"

codata_raw some_killing: 'a = "'b \<Rightarrow> 'd \<Rightarrow> ('a + 'c)"
and in_here: 'c = "'d \<times> 'b + 'e"

codata_raw some_killing': 'a = "'b \<Rightarrow> 'd \<Rightarrow> ('a + 'c)"
and in_here': 'c = "'d + 'e"

codata_raw some_killing'': 'a = "'b \<Rightarrow> 'c"
and in_here'': 'c = "'d \<times> 'b + 'e"

codata_raw less_killing: 'a = "'b \<Rightarrow> 'c"

codata_raw
    wit3_F1: 'b1 = "'a1 \<times> 'b1 \<times> 'b2"
and wit3_F2: 'b2 = "'a2 \<times> 'b2"
and wit3_F3: 'b3 = "'a1 \<times> 'a2 \<times> 'b1 + 'a3 \<times> 'a1 \<times> 'a2 \<times> 'b1"

codata_raw
    coind_wit1: 'a = "'c \<times> 'a \<times> 'b \<times> 'd"
and coind_wit2: 'd = "'d \<times> 'e + 'c \<times> 'g"
and ind_wit:    'b = "unit + 'c"

(* SLOW, MEMORY-HUNGRY
codata_raw K1': 'K1 = "'K2 + 'a list"
and K2': 'K2 = "'K3 + 'c fset"
and K3': 'K3 = "'K3 + 'K4 + 'K4 \<times> 'K5"
and K4': 'K4 = "'K5 + 'a list list list"
and K5': 'K5 = "'K6"
and K6': 'K6 = "'K7"
and K7': 'K7 = "'K8"
and K8': 'K8 = "'K1 list"
*)

end