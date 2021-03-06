(*  Title:      HOL/SMT_Examples/SMT_Tests.thy
    Author:     Sascha Boehme, TU Muenchen
*)

header {* Tests for the SMT binding *}

theory SMT_Tests
imports Complex_Main
begin

smt_status
smt2_status

text {* Most examples are taken from various Isabelle theories and from HOL4. *}


section {* Propositional logic *}

lemma
  "True"
  "\<not> False"
  "\<not> \<not> True"
  "True \<and> True"
  "True \<or> False"
  "False \<longrightarrow> True"
  "\<not> (False \<longleftrightarrow> True)"
  by smt2+

lemma
  "P \<or> \<not> P"
  "\<not> (P \<and> \<not> P)"
  "(True \<and> P) \<or> \<not> P \<or> (False \<and> P) \<or> P"
  "P \<longrightarrow> P"
  "P \<and> \<not> P \<longrightarrow> False"
  "P \<and> Q \<longrightarrow> Q \<and> P"
  "P \<or> Q \<longrightarrow> Q \<or> P"
  "P \<and> Q \<longrightarrow> P \<or> Q"
  "\<not> (P \<or> Q) \<longrightarrow> \<not> P"
  "\<not> (P \<or> Q) \<longrightarrow> \<not> Q"
  "\<not> P \<longrightarrow> \<not> (P \<and> Q)"
  "\<not> Q \<longrightarrow> \<not> (P \<and> Q)"
  "(P \<and> Q) \<longleftrightarrow> (\<not> (\<not> P \<or> \<not> Q))"
  "(P \<and> Q) \<and> R \<longrightarrow> P \<and> (Q \<and> R)"
  "(P \<or> Q) \<or> R \<longrightarrow> P \<or> (Q \<or> R)"
  "(P \<and> Q) \<or> R  \<longrightarrow> (P \<or> R) \<and> (Q \<or> R)"
  "(P \<or> R) \<and> (Q \<or> R) \<longrightarrow> (P \<and> Q) \<or> R"
  "(P \<or> Q) \<and> R \<longrightarrow> (P \<and> R) \<or> (Q \<and> R)"
  "(P \<and> R) \<or> (Q \<and> R) \<longrightarrow> (P \<or> Q) \<and> R"
  "((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P"
  "(P \<longrightarrow> R) \<and> (Q \<longrightarrow> R) \<longleftrightarrow> (P \<or> Q \<longrightarrow> R)"
  "(P \<and> Q \<longrightarrow> R) \<longleftrightarrow> (P \<longrightarrow> (Q \<longrightarrow> R))"
  "((P \<longrightarrow> R) \<longrightarrow> R) \<longrightarrow>  ((Q \<longrightarrow> R) \<longrightarrow> R) \<longrightarrow> (P \<and> Q \<longrightarrow> R) \<longrightarrow> R"
  "\<not> (P \<longrightarrow> R) \<longrightarrow>  \<not> (Q \<longrightarrow> R) \<longrightarrow> \<not> (P \<and> Q \<longrightarrow> R)"
  "(P \<longrightarrow> Q \<and> R) \<longleftrightarrow> (P \<longrightarrow> Q) \<and> (P \<longrightarrow> R)"
  "P \<longrightarrow> (Q \<longrightarrow> P)"
  "(P \<longrightarrow> Q \<longrightarrow> R) \<longrightarrow> (P \<longrightarrow> Q)\<longrightarrow> (P \<longrightarrow> R)"
  "(P \<longrightarrow> Q) \<or> (P \<longrightarrow> R) \<longrightarrow> (P \<longrightarrow> Q \<or> R)"
  "((((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P) \<longrightarrow> Q) \<longrightarrow> Q"
  "(P \<longrightarrow> Q) \<longrightarrow> (\<not> Q \<longrightarrow> \<not> P)"
  "(P \<longrightarrow> Q \<or> R) \<longrightarrow> (P \<longrightarrow> Q) \<or> (P \<longrightarrow> R)"
  "(P \<longrightarrow> Q) \<and> (Q  \<longrightarrow> P) \<longrightarrow> (P \<longleftrightarrow> Q)"
  "(P \<longleftrightarrow> Q) \<longleftrightarrow> (Q \<longleftrightarrow> P)"
  "\<not> (P \<longleftrightarrow> \<not> P)"
  "(P \<longrightarrow> Q) \<longleftrightarrow> (\<not> Q \<longrightarrow> \<not> P)"
  "P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P \<longleftrightarrow> P"
  by smt2+

lemma
  "(if P then Q1 else Q2) \<longleftrightarrow> ((P \<longrightarrow> Q1) \<and> (\<not> P \<longrightarrow> Q2))"
  "if P then (Q \<longrightarrow> P) else (P \<longrightarrow> Q)"
  "(if P1 \<or> P2 then Q1 else Q2) \<longleftrightarrow> (if P1 then Q1 else if P2 then Q1 else Q2)"
  "(if P1 \<and> P2 then Q1 else Q2) \<longleftrightarrow> (if P1 then if P2 then Q1 else Q2 else Q2)"
  "(P1 \<longrightarrow> (if P2 then Q1 else Q2)) \<longleftrightarrow>
   (if P1 \<longrightarrow> P2 then P1 \<longrightarrow> Q1 else P1 \<longrightarrow> Q2)"
  by smt2+

lemma
  "case P of True \<Rightarrow> P | False \<Rightarrow> \<not> P"
  "case P of False \<Rightarrow> \<not> P | True \<Rightarrow> P"
  "case \<not> P of True \<Rightarrow> \<not> P | False \<Rightarrow> P"
  "case P of True \<Rightarrow> (Q \<longrightarrow> P) | False \<Rightarrow> (P \<longrightarrow> Q)"
  by smt2+


section {* First-order logic with equality *}

lemma
  "x = x"
  "x = y \<longrightarrow> y = x"
  "x = y \<and> y = z \<longrightarrow> x = z"
  "x = y \<longrightarrow> f x = f y"
  "x = y \<longrightarrow> g x y = g y x"
  "f (f x) = x \<and> f (f (f (f (f x)))) = x \<longrightarrow> f x = x"
  "((if a then b else c) = d) = ((a \<longrightarrow> (b = d)) \<and> (\<not> a \<longrightarrow> (c = d)))"
  by smt2+

lemma
  "\<forall>x. x = x"
  "(\<forall>x. P x) \<longleftrightarrow> (\<forall>y. P y)"
  "\<forall>x. P x \<longrightarrow> (\<forall>y. P x \<or> P y)"
  "(\<forall>x. P x \<and> Q x) \<longleftrightarrow> (\<forall>x. P x) \<and> (\<forall>x. Q x)"
  "(\<forall>x. P x) \<or> R \<longleftrightarrow> (\<forall>x. P x \<or> R)"
  "(\<forall>x y z. S x z) \<longleftrightarrow> (\<forall>x z. S x z)"
  "(\<forall>x y. S x y \<longrightarrow> S y x) \<longrightarrow> (\<forall>x. S x y) \<longrightarrow> S y x"
  "(\<forall>x. P x \<longrightarrow> P (f x)) \<and> P d \<longrightarrow> P (f(f(f(d))))"
  "(\<forall>x y. s x y = s y x) \<longrightarrow> a = a \<and> s a b = s b a"
  "(\<forall>s. q s \<longrightarrow> r s) \<and> \<not> r s \<and> (\<forall>s. \<not> r s \<and> \<not> q s \<longrightarrow> p t \<or> q t) \<longrightarrow> p t \<or> r t"
  by smt2+

lemma
  "(\<forall>x. P x) \<and> R \<longleftrightarrow> (\<forall>x. P x \<and> R)"
  by smt2

lemma
  "\<exists>x. x = x"
  "(\<exists>x. P x) \<longleftrightarrow> (\<exists>y. P y)"
  "(\<exists>x. P x \<or> Q x) \<longleftrightarrow> (\<exists>x. P x) \<or> (\<exists>x. Q x)"
  "(\<exists>x. P x) \<and> R \<longleftrightarrow> (\<exists>x. P x \<and> R)"
  "(\<exists>x y z. S x z) \<longleftrightarrow> (\<exists>x z. S x z)"
  "\<not> ((\<exists>x. \<not> P x) \<and> ((\<exists>x. P x) \<or> (\<exists>x. P x \<and> Q x)) \<and> \<not> (\<exists>x. P x))"
  by smt2+

lemma
  "\<exists>x y. x = y"
  "\<exists>x. P x \<longrightarrow> (\<exists>y. P x \<and> P y)"
  "(\<exists>x. P x) \<or> R \<longleftrightarrow> (\<exists>x. P x \<or> R)"
  "\<exists>x. P x \<longrightarrow> P a \<and> P b"
  "\<exists>x. (\<exists>y. P y) \<longrightarrow> P x"
  "(\<exists>x. Q \<longrightarrow> P x) \<longleftrightarrow> (Q \<longrightarrow> (\<exists>x. P x))"
  by smt2+

lemma
  "(\<not> (\<exists>x. P x)) \<longleftrightarrow> (\<forall>x. \<not> P x)"
  "(\<exists>x. P x \<longrightarrow> Q) \<longleftrightarrow> (\<forall>x. P x) \<longrightarrow> Q"
  "(\<forall>x y. R x y = x) \<longrightarrow> (\<exists>y. R x y) = R x c"
  "(if P x then \<not> (\<exists>y. P y) else (\<forall>y. \<not> P y)) \<longrightarrow> P x \<longrightarrow> P y"
  "(\<forall>x y. R x y = x) \<and> (\<forall>x. \<exists>y. R x y) = (\<forall>x. R x c) \<longrightarrow> (\<exists>y. R x y) = R x c"
  by smt2+

lemma
  "\<forall>x. \<exists>y. f x y = f x (g x)"
  "(\<not> \<not> (\<exists>x. P x)) \<longleftrightarrow> (\<not> (\<forall>x. \<not> P x))"
  "\<forall>u. \<exists>v. \<forall>w. \<exists>x. f u v w x = f u (g u) w (h u w)"
  "\<exists>x. if x = y then (\<forall>y. y = x \<or> y \<noteq> x) else (\<forall>y. y = (x, x) \<or> y \<noteq> (x, x))"
  "\<exists>x. if x = y then (\<exists>y. y = x \<or> y \<noteq> x) else (\<exists>y. y = (x, x) \<or> y \<noteq> (x, x))"
  "(\<exists>x. \<forall>y. P x \<longleftrightarrow> P y) \<longrightarrow> ((\<exists>x. P x) \<longleftrightarrow> (\<forall>y. P y))"
  "\<exists>z. P z \<longrightarrow> (\<forall>x. P x)"
  "(\<exists>y. \<forall>x. R x y) \<longrightarrow> (\<forall>x. \<exists>y. R x y)"
  by smt2+

lemma
  "(\<exists>!x. P x) \<longrightarrow> (\<exists>x. P x)"
  "(\<exists>!x. P x) \<longleftrightarrow> (\<exists>x. P x \<and> (\<forall>y. y \<noteq> x \<longrightarrow> \<not> P y))"
  "P a \<longrightarrow> (\<forall>x. P x \<longrightarrow> x = a) \<longrightarrow> (\<exists>!x. P x)"
  "(\<exists>x. P x) \<and> (\<forall>x y. P x \<and> P y \<longrightarrow> x = y) \<longrightarrow> (\<exists>!x. P x)"
  "(\<exists>!x. P x) \<and> (\<forall>x. P x \<and> (\<forall>y. P y \<longrightarrow> y = x) \<longrightarrow> R) \<longrightarrow> R"
  by smt2+

lemma
  "(\<forall>x\<in>M. P x) \<and> c \<in> M \<longrightarrow> P c"
  "(\<exists>x\<in>M. P x) \<or> \<not> (P c \<and> c \<in> M)"
  by smt2+

lemma
  "let P = True in P"
  "let P = P1 \<or> P2 in P \<or> \<not> P"
  "let P1 = True; P2 = False in P1 \<and> P2 \<longrightarrow> P2 \<or> P1"
  "(let x = y in x) = y"
  "(let x = y in Q x) \<longleftrightarrow> (let z = y in Q z)"
  "(let x = y1; z = y2 in R x z) \<longleftrightarrow> (let z = y2; x = y1 in R x z)"
  "(let x = y1; z = y2 in R x z) \<longleftrightarrow> (let z = y1; x = y2 in R z x)"
  "let P = (\<forall>x. Q x) in if P then P else \<not> P"
  by smt2+

lemma
  "a \<noteq> b \<and> a \<noteq> c \<and> b \<noteq> c \<and> (\<forall>x y. f x = f y \<longrightarrow> y = x) \<longrightarrow> f a \<noteq> f b"
  by smt2

lemma
  "(\<forall>x y z. f x y = f x z \<longrightarrow> y = z) \<and> b \<noteq> c \<longrightarrow> f a b \<noteq> f a c"
  "(\<forall>x y z. f x y = f z y \<longrightarrow> x = z) \<and> a \<noteq> d \<longrightarrow> f a b \<noteq> f d b"
  by smt2+


section {* Guidance for quantifier heuristics: patterns *}

lemma
  assumes "\<forall>x.
    SMT2.trigger (SMT2.Symb_Cons (SMT2.Symb_Cons (SMT2.pat (f x)) SMT2.Symb_Nil) SMT2.Symb_Nil)
    (f x = x)"
  shows "f 1 = 1"
  using assms using [[smt2_trace]] by smt2

lemma
  assumes "\<forall>x y.
    SMT2.trigger (SMT2.Symb_Cons (SMT2.Symb_Cons (SMT2.pat (f x))
      (SMT2.Symb_Cons (SMT2.pat (g y)) SMT2.Symb_Nil)) SMT2.Symb_Nil) (f x = g y)"
  shows "f a = g b"
  using assms by smt2


section {* Meta-logical connectives *}

lemma
  "True \<Longrightarrow> True"
  "False \<Longrightarrow> True"
  "False \<Longrightarrow> False"
  "P' x \<Longrightarrow> P' x"
  "P \<Longrightarrow> P \<or> Q"
  "Q \<Longrightarrow> P \<or> Q"
  "\<not> P \<Longrightarrow> P \<longrightarrow> Q"
  "Q \<Longrightarrow> P \<longrightarrow> Q"
  "\<lbrakk>P; \<not> Q\<rbrakk> \<Longrightarrow> \<not> (P \<longrightarrow> Q)"
  "P' x \<equiv> P' x"
  "P' x \<equiv> Q' x \<Longrightarrow> P' x = Q' x"
  "P' x = Q' x \<Longrightarrow> P' x \<equiv> Q' x"
  "x \<equiv> y \<Longrightarrow> y \<equiv> z \<Longrightarrow> x \<equiv> (z::'a::type)"
  "x \<equiv> y \<Longrightarrow> (f x :: 'b::type) \<equiv> f y"
  "(\<And>x. g x) \<Longrightarrow> g a \<or> a"
  "(\<And>x y. h x y \<and> h y x) \<Longrightarrow> \<forall>x. h x x"
  "(p \<or> q) \<and> \<not> p \<Longrightarrow> q"
  "(a \<and> b) \<or> (c \<and> d) \<Longrightarrow> (a \<and> b) \<or> (c \<and> d)"
  by smt2+


section {* Integers *}

lemma
  "(0::int) = 0"
  "(0::int) = (- 0)"
  "(1::int) = 1"
  "\<not> (-1 = (1::int))"
  "(0::int) < 1"
  "(0::int) \<le> 1"
  "-123 + 345 < (567::int)"
  "(123456789::int) < 2345678901"
  "(-123456789::int) < 2345678901"
  by smt2+

lemma
  "(x::int) + 0 = x"
  "0 + x = x"
  "x + y = y + x"
  "x + (y + z) = (x + y) + z"
  "(x + y = 0) = (x = -y)"
  by smt2+

lemma
  "(-1::int) = - 1"
  "(-3::int) = - 3"
  "-(x::int) < 0 \<longleftrightarrow> x > 0"
  "x > 0 \<longrightarrow> -x < 0"
  "x < 0 \<longrightarrow> -x > 0"
  by smt2+

lemma
  "(x::int) - 0 = x"
  "0 - x = -x"
  "x < y \<longrightarrow> x - y < 0"
  "x - y = -(y - x)"
  "x - y = -y + x"
  "x - y - z = x - (y + z)"
  by smt2+

lemma
  "(x::int) * 0 = 0"
  "0 * x = 0"
  "x * 1 = x"
  "1 * x = x"
  "x * -1 = -x"
  "-1 * x = -x"
  "3 * x = x * 3"
  by smt2+

lemma
  "(0::int) div 0 = 0"
  "(x::int) div 0 = 0"
  "(0::int) div 1 = 0"
  "(1::int) div 1 = 1"
  "(3::int) div 1 = 3"
  "(x::int) div 1 = x"
  "(0::int) div -1 = 0"
  "(1::int) div -1 = -1"
  "(3::int) div -1 = -3"
  "(x::int) div -1 = -x"
  "(0::int) div 3 = 0"
  "(0::int) div -3 = 0"
  "(1::int) div 3 = 0"
  "(3::int) div 3 = 1"
  "(5::int) div 3 = 1"
  "(1::int) div -3 = -1"
  "(3::int) div -3 = -1"
  "(5::int) div -3 = -2"
  "(-1::int) div 3 = -1"
  "(-3::int) div 3 = -1"
  "(-5::int) div 3 = -2"
  "(-1::int) div -3 = 0"
  "(-3::int) div -3 = 1"
  "(-5::int) div -3 = 1"
  using [[z3_new_extensions]]
  by smt2+

lemma
  "(0::int) mod 0 = 0"
  "(x::int) mod 0 = x"
  "(0::int) mod 1 = 0"
  "(1::int) mod 1 = 0"
  "(3::int) mod 1 = 0"
  "(x::int) mod 1 = 0"
  "(0::int) mod -1 = 0"
  "(1::int) mod -1 = 0"
  "(3::int) mod -1 = 0"
  "(x::int) mod -1 = 0"
  "(0::int) mod 3 = 0"
  "(0::int) mod -3 = 0"
  "(1::int) mod 3 = 1"
  "(3::int) mod 3 = 0"
  "(5::int) mod 3 = 2"
  "(1::int) mod -3 = -2"
  "(3::int) mod -3 = 0"
  "(5::int) mod -3 = -1"
  "(-1::int) mod 3 = 2"
  "(-3::int) mod 3 = 0"
  "(-5::int) mod 3 = 1"
  "(-1::int) mod -3 = -1"
  "(-3::int) mod -3 = 0"
  "(-5::int) mod -3 = -2"
  "x mod 3 < 3"
  "(x mod 3 = x) \<longrightarrow> (x < 3)"
  using [[z3_new_extensions]]
  by smt2+

lemma
  "(x::int) = x div 1 * 1 + x mod 1"
  "x = x div 3 * 3 + x mod 3"
  using [[z3_new_extensions]]
  by smt2+

lemma
  "abs (x::int) \<ge> 0"
  "(abs x = 0) = (x = 0)"
  "(x \<ge> 0) = (abs x = x)"
  "(x \<le> 0) = (abs x = -x)"
  "abs (abs x) = abs x"
  by smt2+

lemma
  "min (x::int) y \<le> x"
  "min x y \<le> y"
  "z < x \<and> z < y \<longrightarrow> z < min x y"
  "min x y = min y x"
  "x \<ge> 0 \<longrightarrow> min x 0 = 0"
  "min x y \<le> abs (x + y)"
  by smt2+

lemma
  "max (x::int) y \<ge> x"
  "max x y \<ge> y"
  "z > x \<and> z > y \<longrightarrow> z > max x y"
  "max x y = max y x"
  "x \<ge> 0 \<longrightarrow> max x 0 = x"
  "max x y \<ge> - abs x - abs y"
  by smt2+

lemma
  "0 < (x::int) \<and> x \<le> 1 \<longrightarrow> x = 1"
  "x \<le> x"
  "x \<le> y \<longrightarrow> 3 * x \<le> 3 * y"
  "x < y \<longrightarrow> 3 * x < 3 * y"
  "x < y \<longrightarrow> x \<le> y"
  "(x < y) = (x + 1 \<le> y)"
  "\<not> (x < x)"
  "x \<le> y \<longrightarrow> y \<le> z \<longrightarrow> x \<le> z"
  "x < y \<longrightarrow> y \<le> z \<longrightarrow> x \<le> z"
  "x \<le> y \<longrightarrow> y < z \<longrightarrow> x \<le> z"
  "x < y \<longrightarrow> y < z \<longrightarrow> x < z"
  "x < y \<and> y < z \<longrightarrow> \<not> (z < x)"
  by smt2+


section {* Reals *}

lemma
  "(0::real) = 0"
  "(0::real) = -0"
  "(0::real) = (- 0)"
  "(1::real) = 1"
  "\<not> (-1 = (1::real))"
  "(0::real) < 1"
  "(0::real) \<le> 1"
  "-123 + 345 < (567::real)"
  "(123456789::real) < 2345678901"
  "(-123456789::real) < 2345678901"
  by smt2+

lemma
  "(x::real) + 0 = x"
  "0 + x = x"
  "x + y = y + x"
  "x + (y + z) = (x + y) + z"
  "(x + y = 0) = (x = -y)"
  by smt2+

lemma
  "(-1::real) = - 1"
  "(-3::real) = - 3"
  "-(x::real) < 0 \<longleftrightarrow> x > 0"
  "x > 0 \<longrightarrow> -x < 0"
  "x < 0 \<longrightarrow> -x > 0"
  by smt2+

lemma
  "(x::real) - 0 = x"
  "0 - x = -x"
  "x < y \<longrightarrow> x - y < 0"
  "x - y = -(y - x)"
  "x - y = -y + x"
  "x - y - z = x - (y + z)"
  by smt2+

lemma
  "(x::real) * 0 = 0"
  "0 * x = 0"
  "x * 1 = x"
  "1 * x = x"
  "x * -1 = -x"
  "-1 * x = -x"
  "3 * x = x * 3"
  by smt2+

lemma
  "(1/2 :: real) < 1"
  "(1::real) / 3 = 1 / 3"
  "(1::real) / -3 = - 1 / 3"
  "(-1::real) / 3 = - 1 / 3"
  "(-1::real) / -3 = 1 / 3"
  "(x::real) / 1 = x"
  "x > 0 \<longrightarrow> x / 3 < x"
  "x < 0 \<longrightarrow> x / 3 > x"
  using [[z3_new_extensions]]
  by smt2+

lemma
  "(3::real) * (x / 3) = x"
  "(x * 3) / 3 = x"
  "x > 0 \<longrightarrow> 2 * x / 3 < x"
  "x < 0 \<longrightarrow> 2 * x / 3 > x"
  using [[z3_new_extensions]]
  by smt2+

lemma
  "abs (x::real) \<ge> 0"
  "(abs x = 0) = (x = 0)"
  "(x \<ge> 0) = (abs x = x)"
  "(x \<le> 0) = (abs x = -x)"
  "abs (abs x) = abs x"
  by smt2+

lemma
  "min (x::real) y \<le> x"
  "min x y \<le> y"
  "z < x \<and> z < y \<longrightarrow> z < min x y"
  "min x y = min y x"
  "x \<ge> 0 \<longrightarrow> min x 0 = 0"
  "min x y \<le> abs (x + y)"
  by smt2+

lemma
  "max (x::real) y \<ge> x"
  "max x y \<ge> y"
  "z > x \<and> z > y \<longrightarrow> z > max x y"
  "max x y = max y x"
  "x \<ge> 0 \<longrightarrow> max x 0 = x"
  "max x y \<ge> - abs x - abs y"
  by smt2+

lemma
  "x \<le> (x::real)"
  "x \<le> y \<longrightarrow> 3 * x \<le> 3 * y"
  "x < y \<longrightarrow> 3 * x < 3 * y"
  "x < y \<longrightarrow> x \<le> y"
  "\<not> (x < x)"
  "x \<le> y \<longrightarrow> y \<le> z \<longrightarrow> x \<le> z"
  "x < y \<longrightarrow> y \<le> z \<longrightarrow> x \<le> z"
  "x \<le> y \<longrightarrow> y < z \<longrightarrow> x \<le> z"
  "x < y \<longrightarrow> y < z \<longrightarrow> x < z"
  "x < y \<and> y < z \<longrightarrow> \<not> (z < x)"
  by smt2+


section {* Datatypes, Records, and Typedefs *}

subsection {* Without support by the SMT solver *}

subsubsection {* Algebraic datatypes *}

lemma
  "x = fst (x, y)"
  "y = snd (x, y)"
  "((x, y) = (y, x)) = (x = y)"
  "((x, y) = (u, v)) = (x = u \<and> y = v)"
  "(fst (x, y, z) = fst (u, v, w)) = (x = u)"
  "(snd (x, y, z) = snd (u, v, w)) = (y = v \<and> z = w)"
  "(fst (snd (x, y, z)) = fst (snd (u, v, w))) = (y = v)"
  "(snd (snd (x, y, z)) = snd (snd (u, v, w))) = (z = w)"
  "(fst (x, y) = snd (x, y)) = (x = y)"
  "p1 = (x, y) \<and> p2 = (y, x) \<longrightarrow> fst p1 = snd p2"
  "(fst (x, y) = snd (x, y)) = (x = y)"
  "(fst p = snd p) = (p = (snd p, fst p))"
  using fst_conv snd_conv pair_collapse
  by smt2+

lemma
  "[x] \<noteq> Nil"
  "[x, y] \<noteq> Nil"
  "x \<noteq> y \<longrightarrow> [x] \<noteq> [y]"
  "hd (x # xs) = x"
  "tl (x # xs) = xs"
  "hd [x, y, z] = x"
  "tl [x, y, z] = [y, z]"
  "hd (tl [x, y, z]) = y"
  "tl (tl [x, y, z]) = [z]"
  using list.sel(1,3) list.simps
  by smt2+

lemma
  "fst (hd [(a, b)]) = a"
  "snd (hd [(a, b)]) = b"
  using fst_conv snd_conv pair_collapse list.sel(1,3) list.simps
  by smt2+


subsubsection {* Records *}

record point =
  cx :: int
  cy :: int

record bw_point = point +
  black :: bool

lemma
  "p1 = p2 \<longrightarrow> cx p1 = cx p2"
  "p1 = p2 \<longrightarrow> cy p1 = cy p2"
  "cx p1 \<noteq> cx p2 \<longrightarrow> p1 \<noteq> p2"
  "cy p1 \<noteq> cy p2 \<longrightarrow> p1 \<noteq> p2"
  using point.simps
  by smt2+

lemma
  "cx \<lparr> cx = 3, cy = 4 \<rparr> = 3"
  "cy \<lparr> cx = 3, cy = 4 \<rparr> = 4"
  "cx \<lparr> cx = 3, cy = 4 \<rparr> \<noteq> cy \<lparr> cx = 3, cy = 4 \<rparr>"
  "\<lparr> cx = 3, cy = 4 \<rparr> \<lparr> cx := 5 \<rparr> = \<lparr> cx = 5, cy = 4 \<rparr>"
  "\<lparr> cx = 3, cy = 4 \<rparr> \<lparr> cy := 6 \<rparr> = \<lparr> cx = 3, cy = 6 \<rparr>"
  "p = \<lparr> cx = 3, cy = 4 \<rparr> \<longrightarrow> p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> = p"
  "p = \<lparr> cx = 3, cy = 4 \<rparr> \<longrightarrow> p \<lparr> cy := 4 \<rparr> \<lparr> cx := 3 \<rparr> = p"
  using point.simps
  by smt2+

lemma
  "cy (p \<lparr> cx := a \<rparr>) = cy p"
  "cx (p \<lparr> cy := a \<rparr>) = cx p"
  "p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> = p \<lparr> cy := 4 \<rparr> \<lparr> cx := 3 \<rparr>"
  sorry

lemma
  "p1 = p2 \<longrightarrow> cx p1 = cx p2"
  "p1 = p2 \<longrightarrow> cy p1 = cy p2"
  "p1 = p2 \<longrightarrow> black p1 = black p2"
  "cx p1 \<noteq> cx p2 \<longrightarrow> p1 \<noteq> p2"
  "cy p1 \<noteq> cy p2 \<longrightarrow> p1 \<noteq> p2"
  "black p1 \<noteq> black p2 \<longrightarrow> p1 \<noteq> p2"
  using point.simps bw_point.simps
  by smt2+

lemma
  "cx \<lparr> cx = 3, cy = 4, black = b \<rparr> = 3"
  "cy \<lparr> cx = 3, cy = 4, black = b \<rparr> = 4"
  "black \<lparr> cx = 3, cy = 4, black = b \<rparr> = b"
  "cx \<lparr> cx = 3, cy = 4, black = b \<rparr> \<noteq> cy \<lparr> cx = 3, cy = 4, black = b \<rparr>"
  "\<lparr> cx = 3, cy = 4, black = b \<rparr> \<lparr> cx := 5 \<rparr> = \<lparr> cx = 5, cy = 4, black = b \<rparr>"
  "\<lparr> cx = 3, cy = 4, black = b \<rparr> \<lparr> cy := 6 \<rparr> = \<lparr> cx = 3, cy = 6, black = b \<rparr>"
  "p = \<lparr> cx = 3, cy = 4, black = True \<rparr> \<longrightarrow>
     p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> \<lparr> black := True \<rparr> = p"
  "p = \<lparr> cx = 3, cy = 4, black = True \<rparr> \<longrightarrow>
     p \<lparr> cy := 4 \<rparr> \<lparr> black := True \<rparr> \<lparr> cx := 3 \<rparr> = p"
  "p = \<lparr> cx = 3, cy = 4, black = True \<rparr> \<longrightarrow>
     p \<lparr> black := True \<rparr> \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> = p"
  using point.simps bw_point.simps
  by smt+ (* smt2 FIXME: bad Z3 4.3.x proof *)

lemma
  "\<lparr> cx = 3, cy = 4, black = b \<rparr> \<lparr> black := w \<rparr> = \<lparr> cx = 3, cy = 4, black = w \<rparr>"
  "\<lparr> cx = 3, cy = 4, black = True \<rparr> \<lparr> black := False \<rparr> =
     \<lparr> cx = 3, cy = 4, black = False \<rparr>"
  "p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> \<lparr> black := True \<rparr> =
     p \<lparr> black := True \<rparr> \<lparr> cy := 4 \<rparr> \<lparr> cx := 3 \<rparr>"
  sorry


subsubsection {* Type definitions *}

typedef int' = "UNIV::int set" by (rule UNIV_witness)

definition n0 where "n0 = Abs_int' 0"
definition n1 where "n1 = Abs_int' 1"
definition n2 where "n2 = Abs_int' 2"
definition plus' where "plus' n m = Abs_int' (Rep_int' n + Rep_int' m)"

lemma
  "n0 \<noteq> n1"
  "plus' n1 n1 = n2"
  "plus' n0 n2 = n2"
  by (smt2 n0_def n1_def n2_def plus'_def Abs_int'_inverse Rep_int'_inverse UNIV_I)+


subsection {* With support by the SMT solver (but without proofs) *}

subsubsection {* Algebraic datatypes *}

lemma
  "x = fst (x, y)"
  "y = snd (x, y)"
  "((x, y) = (y, x)) = (x = y)"
  "((x, y) = (u, v)) = (x = u \<and> y = v)"
  "(fst (x, y, z) = fst (u, v, w)) = (x = u)"
  "(snd (x, y, z) = snd (u, v, w)) = (y = v \<and> z = w)"
  "(fst (snd (x, y, z)) = fst (snd (u, v, w))) = (y = v)"
  "(snd (snd (x, y, z)) = snd (snd (u, v, w))) = (z = w)"
  "(fst (x, y) = snd (x, y)) = (x = y)"
  "p1 = (x, y) \<and> p2 = (y, x) \<longrightarrow> fst p1 = snd p2"
  "(fst (x, y) = snd (x, y)) = (x = y)"
  "(fst p = snd p) = (p = (snd p, fst p))"
  using fst_conv snd_conv pair_collapse
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "[x] \<noteq> Nil"
  "[x, y] \<noteq> Nil"
  "x \<noteq> y \<longrightarrow> [x] \<noteq> [y]"
  "hd (x # xs) = x"
  "tl (x # xs) = xs"
  "hd [x, y, z] = x"
  "tl [x, y, z] = [y, z]"
  "hd (tl [x, y, z]) = y"
  "tl (tl [x, y, z]) = [z]"
  using list.sel(1,3)
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "fst (hd [(a, b)]) = a"
  "snd (hd [(a, b)]) = b"
  using fst_conv snd_conv pair_collapse list.sel(1,3)
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+


subsubsection {* Records *}

lemma
  "p1 = p2 \<longrightarrow> cx p1 = cx p2"
  "p1 = p2 \<longrightarrow> cy p1 = cy p2"
  "cx p1 \<noteq> cx p2 \<longrightarrow> p1 \<noteq> p2"
  "cy p1 \<noteq> cy p2 \<longrightarrow> p1 \<noteq> p2"
  using point.simps
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "cx \<lparr> cx = 3, cy = 4 \<rparr> = 3"
  "cy \<lparr> cx = 3, cy = 4 \<rparr> = 4"
  "cx \<lparr> cx = 3, cy = 4 \<rparr> \<noteq> cy \<lparr> cx = 3, cy = 4 \<rparr>"
  "\<lparr> cx = 3, cy = 4 \<rparr> \<lparr> cx := 5 \<rparr> = \<lparr> cx = 5, cy = 4 \<rparr>"
  "\<lparr> cx = 3, cy = 4 \<rparr> \<lparr> cy := 6 \<rparr> = \<lparr> cx = 3, cy = 6 \<rparr>"
  "p = \<lparr> cx = 3, cy = 4 \<rparr> \<longrightarrow> p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> = p"
  "p = \<lparr> cx = 3, cy = 4 \<rparr> \<longrightarrow> p \<lparr> cy := 4 \<rparr> \<lparr> cx := 3 \<rparr> = p"
  using point.simps
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "cy (p \<lparr> cx := a \<rparr>) = cy p"
  "cx (p \<lparr> cy := a \<rparr>) = cx p"
  "p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> = p \<lparr> cy := 4 \<rparr> \<lparr> cx := 3 \<rparr>"
  using point.simps
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "p1 = p2 \<longrightarrow> cx p1 = cx p2"
  "p1 = p2 \<longrightarrow> cy p1 = cy p2"
  "p1 = p2 \<longrightarrow> black p1 = black p2"
  "cx p1 \<noteq> cx p2 \<longrightarrow> p1 \<noteq> p2"
  "cy p1 \<noteq> cy p2 \<longrightarrow> p1 \<noteq> p2"
  "black p1 \<noteq> black p2 \<longrightarrow> p1 \<noteq> p2"
  using point.simps bw_point.simps
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "cx \<lparr> cx = 3, cy = 4, black = b \<rparr> = 3"
  "cy \<lparr> cx = 3, cy = 4, black = b \<rparr> = 4"
  "black \<lparr> cx = 3, cy = 4, black = b \<rparr> = b"
  "cx \<lparr> cx = 3, cy = 4, black = b \<rparr> \<noteq> cy \<lparr> cx = 3, cy = 4, black = b \<rparr>"
  "\<lparr> cx = 3, cy = 4, black = b \<rparr> \<lparr> cx := 5 \<rparr> = \<lparr> cx = 5, cy = 4, black = b \<rparr>"
  "\<lparr> cx = 3, cy = 4, black = b \<rparr> \<lparr> cy := 6 \<rparr> = \<lparr> cx = 3, cy = 6, black = b \<rparr>"
  "p = \<lparr> cx = 3, cy = 4, black = True \<rparr> \<longrightarrow>
     p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> \<lparr> black := True \<rparr> = p"
  "p = \<lparr> cx = 3, cy = 4, black = True \<rparr> \<longrightarrow>
     p \<lparr> cy := 4 \<rparr> \<lparr> black := True \<rparr> \<lparr> cx := 3 \<rparr> = p"
  "p = \<lparr> cx = 3, cy = 4, black = True \<rparr> \<longrightarrow>
     p \<lparr> black := True \<rparr> \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> = p"
  using point.simps bw_point.simps
  using [[smt2_oracle, z3_new_extensions]]
  by smt2+

lemma
  "\<lparr> cx = 3, cy = 4, black = b \<rparr> \<lparr> black := w \<rparr> = \<lparr> cx = 3, cy = 4, black = w \<rparr>"
  "\<lparr> cx = 3, cy = 4, black = True \<rparr> \<lparr> black := False \<rparr> =
     \<lparr> cx = 3, cy = 4, black = False \<rparr>"
  sorry

lemma
  "p \<lparr> cx := 3 \<rparr> \<lparr> cy := 4 \<rparr> \<lparr> black := True \<rparr> =
     p \<lparr> black := True \<rparr> \<lparr> cy := 4 \<rparr> \<lparr> cx := 3 \<rparr>"
  using point.simps bw_point.simps
  using [[smt2_oracle, z3_new_extensions]]
  by smt2


subsubsection {* Type definitions *}

lemma
  "n0 \<noteq> n1"
  "plus' n1 n1 = n2"
  "plus' n0 n2 = n2"
  using [[smt2_oracle, z3_new_extensions]]
  by (smt2 n0_def n1_def n2_def plus'_def)+


section {* Function updates *}

lemma
  "(f (i := v)) i = v"
  "i1 \<noteq> i2 \<longrightarrow> (f (i1 := v)) i2 = f i2"
  "i1 \<noteq> i2 \<longrightarrow> (f (i1 := v1, i2 := v2)) i1 = v1"
  "i1 \<noteq> i2 \<longrightarrow> (f (i1 := v1, i2 := v2)) i2 = v2"
  "i1 = i2 \<longrightarrow> (f (i1 := v1, i2 := v2)) i1 = v2"
  "i1 = i2 \<longrightarrow> (f (i1 := v1, i2 := v2)) i1 = v2"
  "i1 \<noteq> i2 \<and>i1 \<noteq> i3 \<and>  i2 \<noteq> i3 \<longrightarrow> (f (i1 := v1, i2 := v2)) i3 = f i3"
  using fun_upd_same fun_upd_apply
  by smt2+


section {* Sets *}

lemma Empty: "x \<notin> {}" by simp

lemmas smt2_sets = Empty UNIV_I Un_iff Int_iff

lemma
  "x \<notin> {}"
  "x \<in> UNIV"
  "x \<in> A \<union> B \<longleftrightarrow> x \<in> A \<or> x \<in> B"
  "x \<in> P \<union> {} \<longleftrightarrow> x \<in> P"
  "x \<in> P \<union> UNIV"
  "x \<in> P \<union> Q \<longleftrightarrow> x \<in> Q \<union> P"
  "x \<in> P \<union> P \<longleftrightarrow> x \<in> P"
  "x \<in> P \<union> (Q \<union> R) \<longleftrightarrow> x \<in> (P \<union> Q) \<union> R"
  "x \<in> A \<inter> B \<longleftrightarrow> x \<in> A \<and> x \<in> B"
  "x \<notin> P \<inter> {}"
  "x \<in> P \<inter> UNIV \<longleftrightarrow> x \<in> P"
  "x \<in> P \<inter> Q \<longleftrightarrow> x \<in> Q \<inter> P"
  "x \<in> P \<inter> P \<longleftrightarrow> x \<in> P"
  "x \<in> P \<inter> (Q \<inter> R) \<longleftrightarrow> x \<in> (P \<inter> Q) \<inter> R"
  "{x. x \<in> P} = {y. y \<in> P}"
  by (smt2 smt2_sets)+

end
