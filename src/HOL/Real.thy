(*  Title:      HOL/Real.thy
    Author:     Jacques D. Fleuriot, University of Edinburgh, 1998
    Author:     Larry Paulson, University of Cambridge
    Author:     Jeremy Avigad, Carnegie Mellon University
    Author:     Florian Zuleger, Johannes Hoelzl, and Simon Funke, TU Muenchen
    Conversion to Isar and new proofs by Lawrence C Paulson, 2003/4
    Construction of Cauchy Reals by Brian Huffman, 2010
*)

header {* Development of the Reals using Cauchy Sequences *}

theory Real
imports Rat Conditionally_Complete_Lattices
begin

text {*
  This theory contains a formalization of the real numbers as
  equivalence classes of Cauchy sequences of rationals.  See
  @{file "~~/src/HOL/ex/Dedekind_Real.thy"} for an alternative
  construction using Dedekind cuts.
*}

subsection {* Preliminary lemmas *}

lemma add_diff_add:
  fixes a b c d :: "'a::ab_group_add"
  shows "(a + c) - (b + d) = (a - b) + (c - d)"
  by simp

lemma minus_diff_minus:
  fixes a b :: "'a::ab_group_add"
  shows "- a - - b = - (a - b)"
  by simp

lemma mult_diff_mult:
  fixes x y a b :: "'a::ring"
  shows "(x * y - a * b) = x * (y - b) + (x - a) * b"
  by (simp add: algebra_simps)

lemma inverse_diff_inverse:
  fixes a b :: "'a::division_ring"
  assumes "a \<noteq> 0" and "b \<noteq> 0"
  shows "inverse a - inverse b = - (inverse a * (a - b) * inverse b)"
  using assms by (simp add: algebra_simps)

lemma obtain_pos_sum:
  fixes r :: rat assumes r: "0 < r"
  obtains s t where "0 < s" and "0 < t" and "r = s + t"
proof
    from r show "0 < r/2" by simp
    from r show "0 < r/2" by simp
    show "r = r/2 + r/2" by simp
qed

subsection {* Sequences that converge to zero *}

definition
  vanishes :: "(nat \<Rightarrow> rat) \<Rightarrow> bool"
where
  "vanishes X = (\<forall>r>0. \<exists>k. \<forall>n\<ge>k. \<bar>X n\<bar> < r)"

lemma vanishesI: "(\<And>r. 0 < r \<Longrightarrow> \<exists>k. \<forall>n\<ge>k. \<bar>X n\<bar> < r) \<Longrightarrow> vanishes X"
  unfolding vanishes_def by simp

lemma vanishesD: "\<lbrakk>vanishes X; 0 < r\<rbrakk> \<Longrightarrow> \<exists>k. \<forall>n\<ge>k. \<bar>X n\<bar> < r"
  unfolding vanishes_def by simp

lemma vanishes_const [simp]: "vanishes (\<lambda>n. c) \<longleftrightarrow> c = 0"
  unfolding vanishes_def
  apply (cases "c = 0", auto)
  apply (rule exI [where x="\<bar>c\<bar>"], auto)
  done

lemma vanishes_minus: "vanishes X \<Longrightarrow> vanishes (\<lambda>n. - X n)"
  unfolding vanishes_def by simp

lemma vanishes_add:
  assumes X: "vanishes X" and Y: "vanishes Y"
  shows "vanishes (\<lambda>n. X n + Y n)"
proof (rule vanishesI)
  fix r :: rat assume "0 < r"
  then obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
    by (rule obtain_pos_sum)
  obtain i where i: "\<forall>n\<ge>i. \<bar>X n\<bar> < s"
    using vanishesD [OF X s] ..
  obtain j where j: "\<forall>n\<ge>j. \<bar>Y n\<bar> < t"
    using vanishesD [OF Y t] ..
  have "\<forall>n\<ge>max i j. \<bar>X n + Y n\<bar> < r"
  proof (clarsimp)
    fix n assume n: "i \<le> n" "j \<le> n"
    have "\<bar>X n + Y n\<bar> \<le> \<bar>X n\<bar> + \<bar>Y n\<bar>" by (rule abs_triangle_ineq)
    also have "\<dots> < s + t" by (simp add: add_strict_mono i j n)
    finally show "\<bar>X n + Y n\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>n\<ge>k. \<bar>X n + Y n\<bar> < r" ..
qed

lemma vanishes_diff:
  assumes X: "vanishes X" and Y: "vanishes Y"
  shows "vanishes (\<lambda>n. X n - Y n)"
  unfolding diff_conv_add_uminus by (intro vanishes_add vanishes_minus X Y)

lemma vanishes_mult_bounded:
  assumes X: "\<exists>a>0. \<forall>n. \<bar>X n\<bar> < a"
  assumes Y: "vanishes (\<lambda>n. Y n)"
  shows "vanishes (\<lambda>n. X n * Y n)"
proof (rule vanishesI)
  fix r :: rat assume r: "0 < r"
  obtain a where a: "0 < a" "\<forall>n. \<bar>X n\<bar> < a"
    using X by fast
  obtain b where b: "0 < b" "r = a * b"
  proof
    show "0 < r / a" using r a by simp
    show "r = a * (r / a)" using a by simp
  qed
  obtain k where k: "\<forall>n\<ge>k. \<bar>Y n\<bar> < b"
    using vanishesD [OF Y b(1)] ..
  have "\<forall>n\<ge>k. \<bar>X n * Y n\<bar> < r"
    by (simp add: b(2) abs_mult mult_strict_mono' a k)
  thus "\<exists>k. \<forall>n\<ge>k. \<bar>X n * Y n\<bar> < r" ..
qed

subsection {* Cauchy sequences *}

definition
  cauchy :: "(nat \<Rightarrow> rat) \<Rightarrow> bool"
where
  "cauchy X \<longleftrightarrow> (\<forall>r>0. \<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < r)"

lemma cauchyI:
  "(\<And>r. 0 < r \<Longrightarrow> \<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < r) \<Longrightarrow> cauchy X"
  unfolding cauchy_def by simp

lemma cauchyD:
  "\<lbrakk>cauchy X; 0 < r\<rbrakk> \<Longrightarrow> \<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < r"
  unfolding cauchy_def by simp

lemma cauchy_const [simp]: "cauchy (\<lambda>n. x)"
  unfolding cauchy_def by simp

lemma cauchy_add [simp]:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "cauchy (\<lambda>n. X n + Y n)"
proof (rule cauchyI)
  fix r :: rat assume "0 < r"
  then obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
    by (rule obtain_pos_sum)
  obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  obtain j where j: "\<forall>m\<ge>j. \<forall>n\<ge>j. \<bar>Y m - Y n\<bar> < t"
    using cauchyD [OF Y t] ..
  have "\<forall>m\<ge>max i j. \<forall>n\<ge>max i j. \<bar>(X m + Y m) - (X n + Y n)\<bar> < r"
  proof (clarsimp)
    fix m n assume *: "i \<le> m" "j \<le> m" "i \<le> n" "j \<le> n"
    have "\<bar>(X m + Y m) - (X n + Y n)\<bar> \<le> \<bar>X m - X n\<bar> + \<bar>Y m - Y n\<bar>"
      unfolding add_diff_add by (rule abs_triangle_ineq)
    also have "\<dots> < s + t"
      by (rule add_strict_mono, simp_all add: i j *)
    finally show "\<bar>(X m + Y m) - (X n + Y n)\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>(X m + Y m) - (X n + Y n)\<bar> < r" ..
qed

lemma cauchy_minus [simp]:
  assumes X: "cauchy X"
  shows "cauchy (\<lambda>n. - X n)"
using assms unfolding cauchy_def
unfolding minus_diff_minus abs_minus_cancel .

lemma cauchy_diff [simp]:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "cauchy (\<lambda>n. X n - Y n)"
  using assms unfolding diff_conv_add_uminus by (simp del: add_uminus_conv_diff)

lemma cauchy_imp_bounded:
  assumes "cauchy X" shows "\<exists>b>0. \<forall>n. \<bar>X n\<bar> < b"
proof -
  obtain k where k: "\<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < 1"
    using cauchyD [OF assms zero_less_one] ..
  show "\<exists>b>0. \<forall>n. \<bar>X n\<bar> < b"
  proof (intro exI conjI allI)
    have "0 \<le> \<bar>X 0\<bar>" by simp
    also have "\<bar>X 0\<bar> \<le> Max (abs ` X ` {..k})" by simp
    finally have "0 \<le> Max (abs ` X ` {..k})" .
    thus "0 < Max (abs ` X ` {..k}) + 1" by simp
  next
    fix n :: nat
    show "\<bar>X n\<bar> < Max (abs ` X ` {..k}) + 1"
    proof (rule linorder_le_cases)
      assume "n \<le> k"
      hence "\<bar>X n\<bar> \<le> Max (abs ` X ` {..k})" by simp
      thus "\<bar>X n\<bar> < Max (abs ` X ` {..k}) + 1" by simp
    next
      assume "k \<le> n"
      have "\<bar>X n\<bar> = \<bar>X k + (X n - X k)\<bar>" by simp
      also have "\<bar>X k + (X n - X k)\<bar> \<le> \<bar>X k\<bar> + \<bar>X n - X k\<bar>"
        by (rule abs_triangle_ineq)
      also have "\<dots> < Max (abs ` X ` {..k}) + 1"
        by (rule add_le_less_mono, simp, simp add: k `k \<le> n`)
      finally show "\<bar>X n\<bar> < Max (abs ` X ` {..k}) + 1" .
    qed
  qed
qed

lemma cauchy_mult [simp]:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "cauchy (\<lambda>n. X n * Y n)"
proof (rule cauchyI)
  fix r :: rat assume "0 < r"
  then obtain u v where u: "0 < u" and v: "0 < v" and "r = u + v"
    by (rule obtain_pos_sum)
  obtain a where a: "0 < a" "\<forall>n. \<bar>X n\<bar> < a"
    using cauchy_imp_bounded [OF X] by fast
  obtain b where b: "0 < b" "\<forall>n. \<bar>Y n\<bar> < b"
    using cauchy_imp_bounded [OF Y] by fast
  obtain s t where s: "0 < s" and t: "0 < t" and r: "r = a * t + s * b"
  proof
    show "0 < v/b" using v b(1) by simp
    show "0 < u/a" using u a(1) by simp
    show "r = a * (u/a) + (v/b) * b"
      using a(1) b(1) `r = u + v` by simp
  qed
  obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  obtain j where j: "\<forall>m\<ge>j. \<forall>n\<ge>j. \<bar>Y m - Y n\<bar> < t"
    using cauchyD [OF Y t] ..
  have "\<forall>m\<ge>max i j. \<forall>n\<ge>max i j. \<bar>X m * Y m - X n * Y n\<bar> < r"
  proof (clarsimp)
    fix m n assume *: "i \<le> m" "j \<le> m" "i \<le> n" "j \<le> n"
    have "\<bar>X m * Y m - X n * Y n\<bar> = \<bar>X m * (Y m - Y n) + (X m - X n) * Y n\<bar>"
      unfolding mult_diff_mult ..
    also have "\<dots> \<le> \<bar>X m * (Y m - Y n)\<bar> + \<bar>(X m - X n) * Y n\<bar>"
      by (rule abs_triangle_ineq)
    also have "\<dots> = \<bar>X m\<bar> * \<bar>Y m - Y n\<bar> + \<bar>X m - X n\<bar> * \<bar>Y n\<bar>"
      unfolding abs_mult ..
    also have "\<dots> < a * t + s * b"
      by (simp_all add: add_strict_mono mult_strict_mono' a b i j *)
    finally show "\<bar>X m * Y m - X n * Y n\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m * Y m - X n * Y n\<bar> < r" ..
qed

lemma cauchy_not_vanishes_cases:
  assumes X: "cauchy X"
  assumes nz: "\<not> vanishes X"
  shows "\<exists>b>0. \<exists>k. (\<forall>n\<ge>k. b < - X n) \<or> (\<forall>n\<ge>k. b < X n)"
proof -
  obtain r where "0 < r" and r: "\<forall>k. \<exists>n\<ge>k. r \<le> \<bar>X n\<bar>"
    using nz unfolding vanishes_def by (auto simp add: not_less)
  obtain s t where s: "0 < s" and t: "0 < t" and "r = s + t"
    using `0 < r` by (rule obtain_pos_sum)
  obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  obtain k where "i \<le> k" and "r \<le> \<bar>X k\<bar>"
    using r by fast
  have k: "\<forall>n\<ge>k. \<bar>X n - X k\<bar> < s"
    using i `i \<le> k` by auto
  have "X k \<le> - r \<or> r \<le> X k"
    using `r \<le> \<bar>X k\<bar>` by auto
  hence "(\<forall>n\<ge>k. t < - X n) \<or> (\<forall>n\<ge>k. t < X n)"
    unfolding `r = s + t` using k by auto
  hence "\<exists>k. (\<forall>n\<ge>k. t < - X n) \<or> (\<forall>n\<ge>k. t < X n)" ..
  thus "\<exists>t>0. \<exists>k. (\<forall>n\<ge>k. t < - X n) \<or> (\<forall>n\<ge>k. t < X n)"
    using t by auto
qed

lemma cauchy_not_vanishes:
  assumes X: "cauchy X"
  assumes nz: "\<not> vanishes X"
  shows "\<exists>b>0. \<exists>k. \<forall>n\<ge>k. b < \<bar>X n\<bar>"
using cauchy_not_vanishes_cases [OF assms]
by clarify (rule exI, erule conjI, rule_tac x=k in exI, auto)

lemma cauchy_inverse [simp]:
  assumes X: "cauchy X"
  assumes nz: "\<not> vanishes X"
  shows "cauchy (\<lambda>n. inverse (X n))"
proof (rule cauchyI)
  fix r :: rat assume "0 < r"
  obtain b i where b: "0 < b" and i: "\<forall>n\<ge>i. b < \<bar>X n\<bar>"
    using cauchy_not_vanishes [OF X nz] by fast
  from b i have nz: "\<forall>n\<ge>i. X n \<noteq> 0" by auto
  obtain s where s: "0 < s" and r: "r = inverse b * s * inverse b"
  proof
    show "0 < b * r * b" by (simp add: `0 < r` b)
    show "r = inverse b * (b * r * b) * inverse b"
      using b by simp
  qed
  obtain j where j: "\<forall>m\<ge>j. \<forall>n\<ge>j. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  have "\<forall>m\<ge>max i j. \<forall>n\<ge>max i j. \<bar>inverse (X m) - inverse (X n)\<bar> < r"
  proof (clarsimp)
    fix m n assume *: "i \<le> m" "j \<le> m" "i \<le> n" "j \<le> n"
    have "\<bar>inverse (X m) - inverse (X n)\<bar> =
          inverse \<bar>X m\<bar> * \<bar>X m - X n\<bar> * inverse \<bar>X n\<bar>"
      by (simp add: inverse_diff_inverse nz * abs_mult)
    also have "\<dots> < inverse b * s * inverse b"
      by (simp add: mult_strict_mono less_imp_inverse_less
                    i j b * s)
    finally show "\<bar>inverse (X m) - inverse (X n)\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>inverse (X m) - inverse (X n)\<bar> < r" ..
qed

lemma vanishes_diff_inverse:
  assumes X: "cauchy X" "\<not> vanishes X"
  assumes Y: "cauchy Y" "\<not> vanishes Y"
  assumes XY: "vanishes (\<lambda>n. X n - Y n)"
  shows "vanishes (\<lambda>n. inverse (X n) - inverse (Y n))"
proof (rule vanishesI)
  fix r :: rat assume r: "0 < r"
  obtain a i where a: "0 < a" and i: "\<forall>n\<ge>i. a < \<bar>X n\<bar>"
    using cauchy_not_vanishes [OF X] by fast
  obtain b j where b: "0 < b" and j: "\<forall>n\<ge>j. b < \<bar>Y n\<bar>"
    using cauchy_not_vanishes [OF Y] by fast
  obtain s where s: "0 < s" and "inverse a * s * inverse b = r"
  proof
    show "0 < a * r * b"
      using a r b by simp
    show "inverse a * (a * r * b) * inverse b = r"
      using a r b by simp
  qed
  obtain k where k: "\<forall>n\<ge>k. \<bar>X n - Y n\<bar> < s"
    using vanishesD [OF XY s] ..
  have "\<forall>n\<ge>max (max i j) k. \<bar>inverse (X n) - inverse (Y n)\<bar> < r"
  proof (clarsimp)
    fix n assume n: "i \<le> n" "j \<le> n" "k \<le> n"
    have "X n \<noteq> 0" and "Y n \<noteq> 0"
      using i j a b n by auto
    hence "\<bar>inverse (X n) - inverse (Y n)\<bar> =
        inverse \<bar>X n\<bar> * \<bar>X n - Y n\<bar> * inverse \<bar>Y n\<bar>"
      by (simp add: inverse_diff_inverse abs_mult)
    also have "\<dots> < inverse a * s * inverse b"
      apply (intro mult_strict_mono' less_imp_inverse_less)
      apply (simp_all add: a b i j k n)
      done
    also note `inverse a * s * inverse b = r`
    finally show "\<bar>inverse (X n) - inverse (Y n)\<bar> < r" .
  qed
  thus "\<exists>k. \<forall>n\<ge>k. \<bar>inverse (X n) - inverse (Y n)\<bar> < r" ..
qed

subsection {* Equivalence relation on Cauchy sequences *}

definition realrel :: "(nat \<Rightarrow> rat) \<Rightarrow> (nat \<Rightarrow> rat) \<Rightarrow> bool"
  where "realrel = (\<lambda>X Y. cauchy X \<and> cauchy Y \<and> vanishes (\<lambda>n. X n - Y n))"

lemma realrelI [intro?]:
  assumes "cauchy X" and "cauchy Y" and "vanishes (\<lambda>n. X n - Y n)"
  shows "realrel X Y"
  using assms unfolding realrel_def by simp

lemma realrel_refl: "cauchy X \<Longrightarrow> realrel X X"
  unfolding realrel_def by simp

lemma symp_realrel: "symp realrel"
  unfolding realrel_def
  by (rule sympI, clarify, drule vanishes_minus, simp)

lemma transp_realrel: "transp realrel"
  unfolding realrel_def
  apply (rule transpI, clarify)
  apply (drule (1) vanishes_add)
  apply (simp add: algebra_simps)
  done

lemma part_equivp_realrel: "part_equivp realrel"
  by (fast intro: part_equivpI symp_realrel transp_realrel
    realrel_refl cauchy_const)

subsection {* The field of real numbers *}

quotient_type real = "nat \<Rightarrow> rat" / partial: realrel
  morphisms rep_real Real
  by (rule part_equivp_realrel)

lemma cr_real_eq: "pcr_real = (\<lambda>x y. cauchy x \<and> Real x = y)"
  unfolding real.pcr_cr_eq cr_real_def realrel_def by auto

lemma Real_induct [induct type: real]: (* TODO: generate automatically *)
  assumes "\<And>X. cauchy X \<Longrightarrow> P (Real X)" shows "P x"
proof (induct x)
  case (1 X)
  hence "cauchy X" by (simp add: realrel_def)
  thus "P (Real X)" by (rule assms)
qed

lemma eq_Real:
  "cauchy X \<Longrightarrow> cauchy Y \<Longrightarrow> Real X = Real Y \<longleftrightarrow> vanishes (\<lambda>n. X n - Y n)"
  using real.rel_eq_transfer
  unfolding real.pcr_cr_eq cr_real_def rel_fun_def realrel_def by simp

lemma Domainp_pcr_real [transfer_domain_rule]: "Domainp pcr_real = cauchy"
by (simp add: real.domain_eq realrel_def)

instantiation real :: field_inverse_zero
begin

lift_definition zero_real :: "real" is "\<lambda>n. 0"
  by (simp add: realrel_refl)

lift_definition one_real :: "real" is "\<lambda>n. 1"
  by (simp add: realrel_refl)

lift_definition plus_real :: "real \<Rightarrow> real \<Rightarrow> real" is "\<lambda>X Y n. X n + Y n"
  unfolding realrel_def add_diff_add
  by (simp only: cauchy_add vanishes_add simp_thms)

lift_definition uminus_real :: "real \<Rightarrow> real" is "\<lambda>X n. - X n"
  unfolding realrel_def minus_diff_minus
  by (simp only: cauchy_minus vanishes_minus simp_thms)

lift_definition times_real :: "real \<Rightarrow> real \<Rightarrow> real" is "\<lambda>X Y n. X n * Y n"
  unfolding realrel_def mult_diff_mult
  by (subst (4) mult.commute, simp only: cauchy_mult vanishes_add
    vanishes_mult_bounded cauchy_imp_bounded simp_thms)

lift_definition inverse_real :: "real \<Rightarrow> real"
  is "\<lambda>X. if vanishes X then (\<lambda>n. 0) else (\<lambda>n. inverse (X n))"
proof -
  fix X Y assume "realrel X Y"
  hence X: "cauchy X" and Y: "cauchy Y" and XY: "vanishes (\<lambda>n. X n - Y n)"
    unfolding realrel_def by simp_all
  have "vanishes X \<longleftrightarrow> vanishes Y"
  proof
    assume "vanishes X"
    from vanishes_diff [OF this XY] show "vanishes Y" by simp
  next
    assume "vanishes Y"
    from vanishes_add [OF this XY] show "vanishes X" by simp
  qed
  thus "?thesis X Y"
    unfolding realrel_def
    by (simp add: vanishes_diff_inverse X Y XY)
qed

definition
  "x - y = (x::real) + - y"

definition
  "x / y = (x::real) * inverse y"

lemma add_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X + Real Y = Real (\<lambda>n. X n + Y n)"
  using assms plus_real.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma minus_Real:
  assumes X: "cauchy X"
  shows "- Real X = Real (\<lambda>n. - X n)"
  using assms uminus_real.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma diff_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X - Real Y = Real (\<lambda>n. X n - Y n)"
  unfolding minus_real_def
  by (simp add: minus_Real add_Real X Y)

lemma mult_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X * Real Y = Real (\<lambda>n. X n * Y n)"
  using assms times_real.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma inverse_Real:
  assumes X: "cauchy X"
  shows "inverse (Real X) =
    (if vanishes X then 0 else Real (\<lambda>n. inverse (X n)))"
  using assms inverse_real.transfer zero_real.transfer
  unfolding cr_real_eq rel_fun_def by (simp split: split_if_asm, metis)

instance proof
  fix a b c :: real
  show "a + b = b + a"
    by transfer (simp add: ac_simps realrel_def)
  show "(a + b) + c = a + (b + c)"
    by transfer (simp add: ac_simps realrel_def)
  show "0 + a = a"
    by transfer (simp add: realrel_def)
  show "- a + a = 0"
    by transfer (simp add: realrel_def)
  show "a - b = a + - b"
    by (rule minus_real_def)
  show "(a * b) * c = a * (b * c)"
    by transfer (simp add: ac_simps realrel_def)
  show "a * b = b * a"
    by transfer (simp add: ac_simps realrel_def)
  show "1 * a = a"
    by transfer (simp add: ac_simps realrel_def)
  show "(a + b) * c = a * c + b * c"
    by transfer (simp add: distrib_right realrel_def)
  show "(0\<Colon>real) \<noteq> (1\<Colon>real)"
    by transfer (simp add: realrel_def)
  show "a \<noteq> 0 \<Longrightarrow> inverse a * a = 1"
    apply transfer
    apply (simp add: realrel_def)
    apply (rule vanishesI)
    apply (frule (1) cauchy_not_vanishes, clarify)
    apply (rule_tac x=k in exI, clarify)
    apply (drule_tac x=n in spec, simp)
    done
  show "a / b = a * inverse b"
    by (rule divide_real_def)
  show "inverse (0::real) = 0"
    by transfer (simp add: realrel_def)
qed

end

subsection {* Positive reals *}

lift_definition positive :: "real \<Rightarrow> bool"
  is "\<lambda>X. \<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < X n"
proof -
  { fix X Y
    assume "realrel X Y"
    hence XY: "vanishes (\<lambda>n. X n - Y n)"
      unfolding realrel_def by simp_all
    assume "\<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < X n"
    then obtain r i where "0 < r" and i: "\<forall>n\<ge>i. r < X n"
      by fast
    obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
      using `0 < r` by (rule obtain_pos_sum)
    obtain j where j: "\<forall>n\<ge>j. \<bar>X n - Y n\<bar> < s"
      using vanishesD [OF XY s] ..
    have "\<forall>n\<ge>max i j. t < Y n"
    proof (clarsimp)
      fix n assume n: "i \<le> n" "j \<le> n"
      have "\<bar>X n - Y n\<bar> < s" and "r < X n"
        using i j n by simp_all
      thus "t < Y n" unfolding r by simp
    qed
    hence "\<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < Y n" using t by fast
  } note 1 = this
  fix X Y assume "realrel X Y"
  hence "realrel X Y" and "realrel Y X"
    using symp_realrel unfolding symp_def by auto
  thus "?thesis X Y"
    by (safe elim!: 1)
qed

lemma positive_Real:
  assumes X: "cauchy X"
  shows "positive (Real X) \<longleftrightarrow> (\<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < X n)"
  using assms positive.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma positive_zero: "\<not> positive 0"
  by transfer auto

lemma positive_add:
  "positive x \<Longrightarrow> positive y \<Longrightarrow> positive (x + y)"
apply transfer
apply (clarify, rename_tac a b i j)
apply (rule_tac x="a + b" in exI, simp)
apply (rule_tac x="max i j" in exI, clarsimp)
apply (simp add: add_strict_mono)
done

lemma positive_mult:
  "positive x \<Longrightarrow> positive y \<Longrightarrow> positive (x * y)"
apply transfer
apply (clarify, rename_tac a b i j)
apply (rule_tac x="a * b" in exI, simp)
apply (rule_tac x="max i j" in exI, clarsimp)
apply (rule mult_strict_mono, auto)
done

lemma positive_minus:
  "\<not> positive x \<Longrightarrow> x \<noteq> 0 \<Longrightarrow> positive (- x)"
apply transfer
apply (simp add: realrel_def)
apply (drule (1) cauchy_not_vanishes_cases, safe, fast, fast)
done

instantiation real :: linordered_field_inverse_zero
begin

definition
  "x < y \<longleftrightarrow> positive (y - x)"

definition
  "x \<le> (y::real) \<longleftrightarrow> x < y \<or> x = y"

definition
  "abs (a::real) = (if a < 0 then - a else a)"

definition
  "sgn (a::real) = (if a = 0 then 0 else if 0 < a then 1 else - 1)"

instance proof
  fix a b c :: real
  show "\<bar>a\<bar> = (if a < 0 then - a else a)"
    by (rule abs_real_def)
  show "a < b \<longleftrightarrow> a \<le> b \<and> \<not> b \<le> a"
    unfolding less_eq_real_def less_real_def
    by (auto, drule (1) positive_add, simp_all add: positive_zero)
  show "a \<le> a"
    unfolding less_eq_real_def by simp
  show "a \<le> b \<Longrightarrow> b \<le> c \<Longrightarrow> a \<le> c"
    unfolding less_eq_real_def less_real_def
    by (auto, drule (1) positive_add, simp add: algebra_simps)
  show "a \<le> b \<Longrightarrow> b \<le> a \<Longrightarrow> a = b"
    unfolding less_eq_real_def less_real_def
    by (auto, drule (1) positive_add, simp add: positive_zero)
  show "a \<le> b \<Longrightarrow> c + a \<le> c + b"
    unfolding less_eq_real_def less_real_def by auto
    (* FIXME: Procedure int_combine_numerals: c + b - (c + a) \<equiv> b + - a *)
    (* Should produce c + b - (c + a) \<equiv> b - a *)
  show "sgn a = (if a = 0 then 0 else if 0 < a then 1 else - 1)"
    by (rule sgn_real_def)
  show "a \<le> b \<or> b \<le> a"
    unfolding less_eq_real_def less_real_def
    by (auto dest!: positive_minus)
  show "a < b \<Longrightarrow> 0 < c \<Longrightarrow> c * a < c * b"
    unfolding less_real_def
    by (drule (1) positive_mult, simp add: algebra_simps)
qed

end

instantiation real :: distrib_lattice
begin

definition
  "(inf :: real \<Rightarrow> real \<Rightarrow> real) = min"

definition
  "(sup :: real \<Rightarrow> real \<Rightarrow> real) = max"

instance proof
qed (auto simp add: inf_real_def sup_real_def max_min_distrib2)

end

lemma of_nat_Real: "of_nat x = Real (\<lambda>n. of_nat x)"
apply (induct x)
apply (simp add: zero_real_def)
apply (simp add: one_real_def add_Real)
done

lemma of_int_Real: "of_int x = Real (\<lambda>n. of_int x)"
apply (cases x rule: int_diff_cases)
apply (simp add: of_nat_Real diff_Real)
done

lemma of_rat_Real: "of_rat x = Real (\<lambda>n. x)"
apply (induct x)
apply (simp add: Fract_of_int_quotient of_rat_divide)
apply (simp add: of_int_Real divide_inverse)
apply (simp add: inverse_Real mult_Real)
done

instance real :: archimedean_field
proof
  fix x :: real
  show "\<exists>z. x \<le> of_int z"
    apply (induct x)
    apply (frule cauchy_imp_bounded, clarify)
    apply (rule_tac x="ceiling b + 1" in exI)
    apply (rule less_imp_le)
    apply (simp add: of_int_Real less_real_def diff_Real positive_Real)
    apply (rule_tac x=1 in exI, simp add: algebra_simps)
    apply (rule_tac x=0 in exI, clarsimp)
    apply (rule le_less_trans [OF abs_ge_self])
    apply (rule less_le_trans [OF _ le_of_int_ceiling])
    apply simp
    done
qed

instantiation real :: floor_ceiling
begin

definition [code del]:
  "floor (x::real) = (THE z. of_int z \<le> x \<and> x < of_int (z + 1))"

instance proof
  fix x :: real
  show "of_int (floor x) \<le> x \<and> x < of_int (floor x + 1)"
    unfolding floor_real_def using floor_exists1 by (rule theI')
qed

end

subsection {* Completeness *}

lemma not_positive_Real:
  assumes X: "cauchy X"
  shows "\<not> positive (Real X) \<longleftrightarrow> (\<forall>r>0. \<exists>k. \<forall>n\<ge>k. X n \<le> r)"
unfolding positive_Real [OF X]
apply (auto, unfold not_less)
apply (erule obtain_pos_sum)
apply (drule_tac x=s in spec, simp)
apply (drule_tac r=t in cauchyD [OF X], clarify)
apply (drule_tac x=k in spec, clarsimp)
apply (rule_tac x=n in exI, clarify, rename_tac m)
apply (drule_tac x=m in spec, simp)
apply (drule_tac x=n in spec, simp)
apply (drule spec, drule (1) mp, clarify, rename_tac i)
apply (rule_tac x="max i k" in exI, simp)
done

lemma le_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X \<le> Real Y = (\<forall>r>0. \<exists>k. \<forall>n\<ge>k. X n \<le> Y n + r)"
unfolding not_less [symmetric, where 'a=real] less_real_def
apply (simp add: diff_Real not_positive_Real X Y)
apply (simp add: diff_le_eq ac_simps)
done

lemma le_RealI:
  assumes Y: "cauchy Y"
  shows "\<forall>n. x \<le> of_rat (Y n) \<Longrightarrow> x \<le> Real Y"
proof (induct x)
  fix X assume X: "cauchy X" and "\<forall>n. Real X \<le> of_rat (Y n)"
  hence le: "\<And>m r. 0 < r \<Longrightarrow> \<exists>k. \<forall>n\<ge>k. X n \<le> Y m + r"
    by (simp add: of_rat_Real le_Real)
  {
    fix r :: rat assume "0 < r"
    then obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
      by (rule obtain_pos_sum)
    obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>Y m - Y n\<bar> < s"
      using cauchyD [OF Y s] ..
    obtain j where j: "\<forall>n\<ge>j. X n \<le> Y i + t"
      using le [OF t] ..
    have "\<forall>n\<ge>max i j. X n \<le> Y n + r"
    proof (clarsimp)
      fix n assume n: "i \<le> n" "j \<le> n"
      have "X n \<le> Y i + t" using n j by simp
      moreover have "\<bar>Y i - Y n\<bar> < s" using n i by simp
      ultimately show "X n \<le> Y n + r" unfolding r by simp
    qed
    hence "\<exists>k. \<forall>n\<ge>k. X n \<le> Y n + r" ..
  }
  thus "Real X \<le> Real Y"
    by (simp add: of_rat_Real le_Real X Y)
qed

lemma Real_leI:
  assumes X: "cauchy X"
  assumes le: "\<forall>n. of_rat (X n) \<le> y"
  shows "Real X \<le> y"
proof -
  have "- y \<le> - Real X"
    by (simp add: minus_Real X le_RealI of_rat_minus le)
  thus ?thesis by simp
qed

lemma less_RealD:
  assumes Y: "cauchy Y"
  shows "x < Real Y \<Longrightarrow> \<exists>n. x < of_rat (Y n)"
by (erule contrapos_pp, simp add: not_less, erule Real_leI [OF Y])

lemma of_nat_less_two_power:
  "of_nat n < (2::'a::linordered_idom) ^ n"
apply (induct n)
apply simp
apply (subgoal_tac "(1::'a) \<le> 2 ^ n")
apply (drule (1) add_le_less_mono, simp)
apply simp
done

lemma complete_real:
  fixes S :: "real set"
  assumes "\<exists>x. x \<in> S" and "\<exists>z. \<forall>x\<in>S. x \<le> z"
  shows "\<exists>y. (\<forall>x\<in>S. x \<le> y) \<and> (\<forall>z. (\<forall>x\<in>S. x \<le> z) \<longrightarrow> y \<le> z)"
proof -
  obtain x where x: "x \<in> S" using assms(1) ..
  obtain z where z: "\<forall>x\<in>S. x \<le> z" using assms(2) ..

  def P \<equiv> "\<lambda>x. \<forall>y\<in>S. y \<le> of_rat x"
  obtain a where a: "\<not> P a"
  proof
    have "of_int (floor (x - 1)) \<le> x - 1" by (rule of_int_floor_le)
    also have "x - 1 < x" by simp
    finally have "of_int (floor (x - 1)) < x" .
    hence "\<not> x \<le> of_int (floor (x - 1))" by (simp only: not_le)
    then show "\<not> P (of_int (floor (x - 1)))"
      unfolding P_def of_rat_of_int_eq using x by fast
  qed
  obtain b where b: "P b"
  proof
    show "P (of_int (ceiling z))"
    unfolding P_def of_rat_of_int_eq
    proof
      fix y assume "y \<in> S"
      hence "y \<le> z" using z by simp
      also have "z \<le> of_int (ceiling z)" by (rule le_of_int_ceiling)
      finally show "y \<le> of_int (ceiling z)" .
    qed
  qed

  def avg \<equiv> "\<lambda>x y :: rat. x/2 + y/2"
  def bisect \<equiv> "\<lambda>(x, y). if P (avg x y) then (x, avg x y) else (avg x y, y)"
  def A \<equiv> "\<lambda>n. fst ((bisect ^^ n) (a, b))"
  def B \<equiv> "\<lambda>n. snd ((bisect ^^ n) (a, b))"
  def C \<equiv> "\<lambda>n. avg (A n) (B n)"
  have A_0 [simp]: "A 0 = a" unfolding A_def by simp
  have B_0 [simp]: "B 0 = b" unfolding B_def by simp
  have A_Suc [simp]: "\<And>n. A (Suc n) = (if P (C n) then A n else C n)"
    unfolding A_def B_def C_def bisect_def split_def by simp
  have B_Suc [simp]: "\<And>n. B (Suc n) = (if P (C n) then C n else B n)"
    unfolding A_def B_def C_def bisect_def split_def by simp

  have width: "\<And>n. B n - A n = (b - a) / 2^n"
    apply (simp add: eq_divide_eq)
    apply (induct_tac n, simp)
    apply (simp add: C_def avg_def algebra_simps)
    done

  have twos: "\<And>y r :: rat. 0 < r \<Longrightarrow> \<exists>n. y / 2 ^ n < r"
    apply (simp add: divide_less_eq)
    apply (subst mult.commute)
    apply (frule_tac y=y in ex_less_of_nat_mult)
    apply clarify
    apply (rule_tac x=n in exI)
    apply (erule less_trans)
    apply (rule mult_strict_right_mono)
    apply (rule le_less_trans [OF _ of_nat_less_two_power])
    apply simp
    apply assumption
    done

  have PA: "\<And>n. \<not> P (A n)"
    by (induct_tac n, simp_all add: a)
  have PB: "\<And>n. P (B n)"
    by (induct_tac n, simp_all add: b)
  have ab: "a < b"
    using a b unfolding P_def
    apply (clarsimp simp add: not_le)
    apply (drule (1) bspec)
    apply (drule (1) less_le_trans)
    apply (simp add: of_rat_less)
    done
  have AB: "\<And>n. A n < B n"
    by (induct_tac n, simp add: ab, simp add: C_def avg_def)
  have A_mono: "\<And>i j. i \<le> j \<Longrightarrow> A i \<le> A j"
    apply (auto simp add: le_less [where 'a=nat])
    apply (erule less_Suc_induct)
    apply (clarsimp simp add: C_def avg_def)
    apply (simp add: add_divide_distrib [symmetric])
    apply (rule AB [THEN less_imp_le])
    apply simp
    done
  have B_mono: "\<And>i j. i \<le> j \<Longrightarrow> B j \<le> B i"
    apply (auto simp add: le_less [where 'a=nat])
    apply (erule less_Suc_induct)
    apply (clarsimp simp add: C_def avg_def)
    apply (simp add: add_divide_distrib [symmetric])
    apply (rule AB [THEN less_imp_le])
    apply simp
    done
  have cauchy_lemma:
    "\<And>X. \<forall>n. \<forall>i\<ge>n. A n \<le> X i \<and> X i \<le> B n \<Longrightarrow> cauchy X"
    apply (rule cauchyI)
    apply (drule twos [where y="b - a"])
    apply (erule exE)
    apply (rule_tac x=n in exI, clarify, rename_tac i j)
    apply (rule_tac y="B n - A n" in le_less_trans) defer
    apply (simp add: width)
    apply (drule_tac x=n in spec)
    apply (frule_tac x=i in spec, drule (1) mp)
    apply (frule_tac x=j in spec, drule (1) mp)
    apply (frule A_mono, drule B_mono)
    apply (frule A_mono, drule B_mono)
    apply arith
    done
  have "cauchy A"
    apply (rule cauchy_lemma [rule_format])
    apply (simp add: A_mono)
    apply (erule order_trans [OF less_imp_le [OF AB] B_mono])
    done
  have "cauchy B"
    apply (rule cauchy_lemma [rule_format])
    apply (simp add: B_mono)
    apply (erule order_trans [OF A_mono less_imp_le [OF AB]])
    done
  have 1: "\<forall>x\<in>S. x \<le> Real B"
  proof
    fix x assume "x \<in> S"
    then show "x \<le> Real B"
      using PB [unfolded P_def] `cauchy B`
      by (simp add: le_RealI)
  qed
  have 2: "\<forall>z. (\<forall>x\<in>S. x \<le> z) \<longrightarrow> Real A \<le> z"
    apply clarify
    apply (erule contrapos_pp)
    apply (simp add: not_le)
    apply (drule less_RealD [OF `cauchy A`], clarify)
    apply (subgoal_tac "\<not> P (A n)")
    apply (simp add: P_def not_le, clarify)
    apply (erule rev_bexI)
    apply (erule (1) less_trans)
    apply (simp add: PA)
    done
  have "vanishes (\<lambda>n. (b - a) / 2 ^ n)"
  proof (rule vanishesI)
    fix r :: rat assume "0 < r"
    then obtain k where k: "\<bar>b - a\<bar> / 2 ^ k < r"
      using twos by fast
    have "\<forall>n\<ge>k. \<bar>(b - a) / 2 ^ n\<bar> < r"
    proof (clarify)
      fix n assume n: "k \<le> n"
      have "\<bar>(b - a) / 2 ^ n\<bar> = \<bar>b - a\<bar> / 2 ^ n"
        by simp
      also have "\<dots> \<le> \<bar>b - a\<bar> / 2 ^ k"
        using n by (simp add: divide_left_mono)
      also note k
      finally show "\<bar>(b - a) / 2 ^ n\<bar> < r" .
    qed
    thus "\<exists>k. \<forall>n\<ge>k. \<bar>(b - a) / 2 ^ n\<bar> < r" ..
  qed
  hence 3: "Real B = Real A"
    by (simp add: eq_Real `cauchy A` `cauchy B` width)
  show "\<exists>y. (\<forall>x\<in>S. x \<le> y) \<and> (\<forall>z. (\<forall>x\<in>S. x \<le> z) \<longrightarrow> y \<le> z)"
    using 1 2 3 by (rule_tac x="Real B" in exI, simp)
qed

instantiation real :: linear_continuum
begin

subsection{*Supremum of a set of reals*}

definition "Sup X = (LEAST z::real. \<forall>x\<in>X. x \<le> z)"
definition "Inf (X::real set) = - Sup (uminus ` X)"

instance
proof
  { fix x :: real and X :: "real set"
    assume x: "x \<in> X" "bdd_above X"
    then obtain s where s: "\<forall>y\<in>X. y \<le> s" "\<And>z. \<forall>y\<in>X. y \<le> z \<Longrightarrow> s \<le> z"
      using complete_real[of X] unfolding bdd_above_def by blast
    then show "x \<le> Sup X"
      unfolding Sup_real_def by (rule LeastI2_order) (auto simp: x) }
  note Sup_upper = this

  { fix z :: real and X :: "real set"
    assume x: "X \<noteq> {}" and z: "\<And>x. x \<in> X \<Longrightarrow> x \<le> z"
    then obtain s where s: "\<forall>y\<in>X. y \<le> s" "\<And>z. \<forall>y\<in>X. y \<le> z \<Longrightarrow> s \<le> z"
      using complete_real[of X] by blast
    then have "Sup X = s"
      unfolding Sup_real_def by (best intro: Least_equality)  
    also from s z have "... \<le> z"
      by blast
    finally show "Sup X \<le> z" . }
  note Sup_least = this

  { fix x :: real and X :: "real set" assume x: "x \<in> X" "bdd_below X" then show "Inf X \<le> x"
      using Sup_upper[of "-x" "uminus ` X"] by (auto simp: Inf_real_def) }
  { fix z :: real and X :: "real set" assume "X \<noteq> {}" "\<And>x. x \<in> X \<Longrightarrow> z \<le> x" then show "z \<le> Inf X"
      using Sup_least[of "uminus ` X" "- z"] by (force simp: Inf_real_def) }
  show "\<exists>a b::real. a \<noteq> b"
    using zero_neq_one by blast
qed
end


subsection {* Hiding implementation details *}

hide_const (open) vanishes cauchy positive Real

declare Real_induct [induct del]
declare Abs_real_induct [induct del]
declare Abs_real_cases [cases del]

lifting_update real.lifting
lifting_forget real.lifting
  
subsection{*More Lemmas*}

text {* BH: These lemmas should not be necessary; they should be
covered by existing simp rules and simplification procedures. *}

lemma real_mult_less_iff1 [simp]: "(0::real) < z ==> (x*z < y*z) = (x < y)"
by simp (* solved by linordered_ring_less_cancel_factor simproc *)

lemma real_mult_le_cancel_iff1 [simp]: "(0::real) < z ==> (x*z \<le> y*z) = (x\<le>y)"
by simp (* solved by linordered_ring_le_cancel_factor simproc *)

lemma real_mult_le_cancel_iff2 [simp]: "(0::real) < z ==> (z*x \<le> z*y) = (x\<le>y)"
by simp (* solved by linordered_ring_le_cancel_factor simproc *)


subsection {* Embedding numbers into the Reals *}

abbreviation
  real_of_nat :: "nat \<Rightarrow> real"
where
  "real_of_nat \<equiv> of_nat"

abbreviation
  real_of_int :: "int \<Rightarrow> real"
where
  "real_of_int \<equiv> of_int"

abbreviation
  real_of_rat :: "rat \<Rightarrow> real"
where
  "real_of_rat \<equiv> of_rat"

consts
  (*overloaded constant for injecting other types into "real"*)
  real :: "'a => real"

defs (overloaded)
  real_of_nat_def [code_unfold]: "real == real_of_nat"
  real_of_int_def [code_unfold]: "real == real_of_int"

declare [[coercion_enabled]]
declare [[coercion "real::nat\<Rightarrow>real"]]
declare [[coercion "real::int\<Rightarrow>real"]]
declare [[coercion "int"]]

declare [[coercion_map map]]
declare [[coercion_map "% f g h x. g (h (f x))"]]
declare [[coercion_map "% f g (x,y) . (f x, g y)"]]

lemma real_eq_of_nat: "real = of_nat"
  unfolding real_of_nat_def ..

lemma real_eq_of_int: "real = of_int"
  unfolding real_of_int_def ..

lemma real_of_int_zero [simp]: "real (0::int) = 0"  
by (simp add: real_of_int_def) 

lemma real_of_one [simp]: "real (1::int) = (1::real)"
by (simp add: real_of_int_def) 

lemma real_of_int_add [simp]: "real(x + y) = real (x::int) + real y"
by (simp add: real_of_int_def) 

lemma real_of_int_minus [simp]: "real(-x) = -real (x::int)"
by (simp add: real_of_int_def) 

lemma real_of_int_diff [simp]: "real(x - y) = real (x::int) - real y"
by (simp add: real_of_int_def) 

lemma real_of_int_mult [simp]: "real(x * y) = real (x::int) * real y"
by (simp add: real_of_int_def) 

lemma real_of_int_power [simp]: "real (x ^ n) = real (x::int) ^ n"
by (simp add: real_of_int_def of_int_power)

lemmas power_real_of_int = real_of_int_power [symmetric]

lemma real_of_int_setsum [simp]: "real ((SUM x:A. f x)::int) = (SUM x:A. real(f x))"
  apply (subst real_eq_of_int)+
  apply (rule of_int_setsum)
done

lemma real_of_int_setprod [simp]: "real ((PROD x:A. f x)::int) = 
    (PROD x:A. real(f x))"
  apply (subst real_eq_of_int)+
  apply (rule of_int_setprod)
done

lemma real_of_int_zero_cancel [simp, algebra, presburger]: "(real x = 0) = (x = (0::int))"
by (simp add: real_of_int_def) 

lemma real_of_int_inject [iff, algebra, presburger]: "(real (x::int) = real y) = (x = y)"
by (simp add: real_of_int_def) 

lemma real_of_int_less_iff [iff, presburger]: "(real (x::int) < real y) = (x < y)"
by (simp add: real_of_int_def) 

lemma real_of_int_le_iff [simp, presburger]: "(real (x::int) \<le> real y) = (x \<le> y)"
by (simp add: real_of_int_def) 

lemma real_of_int_gt_zero_cancel_iff [simp, presburger]: "(0 < real (n::int)) = (0 < n)"
by (simp add: real_of_int_def) 

lemma real_of_int_ge_zero_cancel_iff [simp, presburger]: "(0 <= real (n::int)) = (0 <= n)"
by (simp add: real_of_int_def) 

lemma real_of_int_lt_zero_cancel_iff [simp, presburger]: "(real (n::int) < 0) = (n < 0)" 
by (simp add: real_of_int_def)

lemma real_of_int_le_zero_cancel_iff [simp, presburger]: "(real (n::int) <= 0) = (n <= 0)"
by (simp add: real_of_int_def)

lemma one_less_real_of_int_cancel_iff: "1 < real (i :: int) \<longleftrightarrow> 1 < i"
  unfolding real_of_one[symmetric] real_of_int_less_iff ..

lemma one_le_real_of_int_cancel_iff: "1 \<le> real (i :: int) \<longleftrightarrow> 1 \<le> i"
  unfolding real_of_one[symmetric] real_of_int_le_iff ..

lemma real_of_int_less_one_cancel_iff: "real (i :: int) < 1 \<longleftrightarrow> i < 1"
  unfolding real_of_one[symmetric] real_of_int_less_iff ..

lemma real_of_int_le_one_cancel_iff: "real (i :: int) \<le> 1 \<longleftrightarrow> i \<le> 1"
  unfolding real_of_one[symmetric] real_of_int_le_iff ..

lemma real_of_int_abs [simp]: "real (abs x) = abs(real (x::int))"
by (auto simp add: abs_if)

lemma int_less_real_le: "((n::int) < m) = (real n + 1 <= real m)"
  apply (subgoal_tac "real n + 1 = real (n + 1)")
  apply (simp del: real_of_int_add)
  apply auto
done

lemma int_le_real_less: "((n::int) <= m) = (real n < real m + 1)"
  apply (subgoal_tac "real m + 1 = real (m + 1)")
  apply (simp del: real_of_int_add)
  apply simp
done

lemma real_of_int_div_aux: "(real (x::int)) / (real d) = 
    real (x div d) + (real (x mod d)) / (real d)"
proof -
  have "x = (x div d) * d + x mod d"
    by auto
  then have "real x = real (x div d) * real d + real(x mod d)"
    by (simp only: real_of_int_mult [THEN sym] real_of_int_add [THEN sym])
  then have "real x / real d = ... / real d"
    by simp
  then show ?thesis
    by (auto simp add: add_divide_distrib algebra_simps)
qed

lemma real_of_int_div: "(d :: int) dvd n ==>
    real(n div d) = real n / real d"
  apply (subst real_of_int_div_aux)
  apply simp
  apply (simp add: dvd_eq_mod_eq_0)
done

lemma real_of_int_div2:
  "0 <= real (n::int) / real (x) - real (n div x)"
  apply (case_tac "x = 0")
  apply simp
  apply (case_tac "0 < x")
  apply (simp add: algebra_simps)
  apply (subst real_of_int_div_aux)
  apply simp
  apply (simp add: algebra_simps)
  apply (subst real_of_int_div_aux)
  apply simp
  apply (subst zero_le_divide_iff)
  apply auto
done

lemma real_of_int_div3:
  "real (n::int) / real (x) - real (n div x) <= 1"
  apply (simp add: algebra_simps)
  apply (subst real_of_int_div_aux)
  apply (auto simp add: divide_le_eq intro: order_less_imp_le)
done

lemma real_of_int_div4: "real (n div x) <= real (n::int) / real x" 
by (insert real_of_int_div2 [of n x], simp)

lemma Ints_real_of_int [simp]: "real (x::int) \<in> Ints"
unfolding real_of_int_def by (rule Ints_of_int)


subsection{*Embedding the Naturals into the Reals*}

lemma real_of_nat_zero [simp]: "real (0::nat) = 0"
by (simp add: real_of_nat_def)

lemma real_of_nat_1 [simp]: "real (1::nat) = 1"
by (simp add: real_of_nat_def)

lemma real_of_nat_one [simp]: "real (Suc 0) = (1::real)"
by (simp add: real_of_nat_def)

lemma real_of_nat_add [simp]: "real (m + n) = real (m::nat) + real n"
by (simp add: real_of_nat_def)

(*Not for addsimps: often the LHS is used to represent a positive natural*)
lemma real_of_nat_Suc: "real (Suc n) = real n + (1::real)"
by (simp add: real_of_nat_def)

lemma real_of_nat_less_iff [iff]: 
     "(real (n::nat) < real m) = (n < m)"
by (simp add: real_of_nat_def)

lemma real_of_nat_le_iff [iff]: "(real (n::nat) \<le> real m) = (n \<le> m)"
by (simp add: real_of_nat_def)

lemma real_of_nat_ge_zero [iff]: "0 \<le> real (n::nat)"
by (simp add: real_of_nat_def)

lemma real_of_nat_Suc_gt_zero: "0 < real (Suc n)"
by (simp add: real_of_nat_def del: of_nat_Suc)

lemma real_of_nat_mult [simp]: "real (m * n) = real (m::nat) * real n"
by (simp add: real_of_nat_def of_nat_mult)

lemma real_of_nat_power [simp]: "real (m ^ n) = real (m::nat) ^ n"
by (simp add: real_of_nat_def of_nat_power)

lemmas power_real_of_nat = real_of_nat_power [symmetric]

lemma real_of_nat_setsum [simp]: "real ((SUM x:A. f x)::nat) = 
    (SUM x:A. real(f x))"
  apply (subst real_eq_of_nat)+
  apply (rule of_nat_setsum)
done

lemma real_of_nat_setprod [simp]: "real ((PROD x:A. f x)::nat) = 
    (PROD x:A. real(f x))"
  apply (subst real_eq_of_nat)+
  apply (rule of_nat_setprod)
done

lemma real_of_card: "real (card A) = setsum (%x.1) A"
  apply (subst card_eq_setsum)
  apply (subst real_of_nat_setsum)
  apply simp
done

lemma real_of_nat_inject [iff]: "(real (n::nat) = real m) = (n = m)"
by (simp add: real_of_nat_def)

lemma real_of_nat_zero_iff [iff]: "(real (n::nat) = 0) = (n = 0)"
by (simp add: real_of_nat_def)

lemma real_of_nat_diff: "n \<le> m ==> real (m - n) = real (m::nat) - real n"
by (simp add: add: real_of_nat_def of_nat_diff)

lemma real_of_nat_gt_zero_cancel_iff [simp]: "(0 < real (n::nat)) = (0 < n)"
by (auto simp: real_of_nat_def)

lemma real_of_nat_le_zero_cancel_iff [simp]: "(real (n::nat) \<le> 0) = (n = 0)"
by (simp add: add: real_of_nat_def)

lemma not_real_of_nat_less_zero [simp]: "~ real (n::nat) < 0"
by (simp add: add: real_of_nat_def)

lemma nat_less_real_le: "((n::nat) < m) = (real n + 1 <= real m)"
  apply (subgoal_tac "real n + 1 = real (Suc n)")
  apply simp
  apply (auto simp add: real_of_nat_Suc)
done

lemma nat_le_real_less: "((n::nat) <= m) = (real n < real m + 1)"
  apply (subgoal_tac "real m + 1 = real (Suc m)")
  apply (simp add: less_Suc_eq_le)
  apply (simp add: real_of_nat_Suc)
done

lemma real_of_nat_div_aux: "(real (x::nat)) / (real d) = 
    real (x div d) + (real (x mod d)) / (real d)"
proof -
  have "x = (x div d) * d + x mod d"
    by auto
  then have "real x = real (x div d) * real d + real(x mod d)"
    by (simp only: real_of_nat_mult [THEN sym] real_of_nat_add [THEN sym])
  then have "real x / real d = \<dots> / real d"
    by simp
  then show ?thesis
    by (auto simp add: add_divide_distrib algebra_simps)
qed

lemma real_of_nat_div: "(d :: nat) dvd n ==>
    real(n div d) = real n / real d"
  by (subst real_of_nat_div_aux)
    (auto simp add: dvd_eq_mod_eq_0 [symmetric])

lemma real_of_nat_div2:
  "0 <= real (n::nat) / real (x) - real (n div x)"
apply (simp add: algebra_simps)
apply (subst real_of_nat_div_aux)
apply simp
done

lemma real_of_nat_div3:
  "real (n::nat) / real (x) - real (n div x) <= 1"
apply(case_tac "x = 0")
apply (simp)
apply (simp add: algebra_simps)
apply (subst real_of_nat_div_aux)
apply simp
done

lemma real_of_nat_div4: "real (n div x) <= real (n::nat) / real x" 
by (insert real_of_nat_div2 [of n x], simp)

lemma real_of_int_of_nat_eq [simp]: "real (of_nat n :: int) = real n"
by (simp add: real_of_int_def real_of_nat_def)

lemma real_nat_eq_real [simp]: "0 <= x ==> real(nat x) = real x"
  apply (subgoal_tac "real(int(nat x)) = real(nat x)")
  apply force
  apply (simp only: real_of_int_of_nat_eq)
done

lemma Nats_real_of_nat [simp]: "real (n::nat) \<in> Nats"
unfolding real_of_nat_def by (rule of_nat_in_Nats)

lemma Ints_real_of_nat [simp]: "real (n::nat) \<in> Ints"
unfolding real_of_nat_def by (rule Ints_of_nat)

subsection {* The Archimedean Property of the Reals *}

theorem reals_Archimedean:
  assumes x_pos: "0 < x"
  shows "\<exists>n. inverse (real (Suc n)) < x"
  unfolding real_of_nat_def using x_pos
  by (rule ex_inverse_of_nat_Suc_less)

lemma reals_Archimedean2: "\<exists>n. (x::real) < real (n::nat)"
  unfolding real_of_nat_def by (rule ex_less_of_nat)

lemma reals_Archimedean3:
  assumes x_greater_zero: "0 < x"
  shows "\<forall>(y::real). \<exists>(n::nat). y < real n * x"
  unfolding real_of_nat_def using `0 < x`
  by (auto intro: ex_less_of_nat_mult)


subsection{* Rationals *}

lemma Rats_real_nat[simp]: "real(n::nat) \<in> \<rat>"
by (simp add: real_eq_of_nat)

lemma Rats_eq_int_div_int:
  "\<rat> = { real(i::int)/real(j::int) |i j. j \<noteq> 0}" (is "_ = ?S")
proof
  show "\<rat> \<subseteq> ?S"
  proof
    fix x::real assume "x : \<rat>"
    then obtain r where "x = of_rat r" unfolding Rats_def ..
    have "of_rat r : ?S"
      by (cases r)(auto simp add:of_rat_rat real_eq_of_int)
    thus "x : ?S" using `x = of_rat r` by simp
  qed
next
  show "?S \<subseteq> \<rat>"
  proof(auto simp:Rats_def)
    fix i j :: int assume "j \<noteq> 0"
    hence "real i / real j = of_rat(Fract i j)"
      by (simp add:of_rat_rat real_eq_of_int)
    thus "real i / real j \<in> range of_rat" by blast
  qed
qed

lemma Rats_eq_int_div_nat:
  "\<rat> = { real(i::int)/real(n::nat) |i n. n \<noteq> 0}"
proof(auto simp:Rats_eq_int_div_int)
  fix i j::int assume "j \<noteq> 0"
  show "EX (i'::int) (n::nat). real i/real j = real i'/real n \<and> 0<n"
  proof cases
    assume "j>0"
    hence "real i/real j = real i/real(nat j) \<and> 0<nat j"
      by (simp add: real_eq_of_int real_eq_of_nat of_nat_nat)
    thus ?thesis by blast
  next
    assume "~ j>0"
    hence "real i/real j = real(-i)/real(nat(-j)) \<and> 0<nat(-j)" using `j\<noteq>0`
      by (simp add: real_eq_of_int real_eq_of_nat of_nat_nat)
    thus ?thesis by blast
  qed
next
  fix i::int and n::nat assume "0 < n"
  hence "real i/real n = real i/real(int n) \<and> int n \<noteq> 0" by simp
  thus "\<exists>(i'::int) j::int. real i/real n = real i'/real j \<and> j \<noteq> 0" by blast
qed

lemma Rats_abs_nat_div_natE:
  assumes "x \<in> \<rat>"
  obtains m n :: nat
  where "n \<noteq> 0" and "\<bar>x\<bar> = real m / real n" and "gcd m n = 1"
proof -
  from `x \<in> \<rat>` obtain i::int and n::nat where "n \<noteq> 0" and "x = real i / real n"
    by(auto simp add: Rats_eq_int_div_nat)
  hence "\<bar>x\<bar> = real(nat(abs i)) / real n" by simp
  then obtain m :: nat where x_rat: "\<bar>x\<bar> = real m / real n" by blast
  let ?gcd = "gcd m n"
  from `n\<noteq>0` have gcd: "?gcd \<noteq> 0" by simp
  let ?k = "m div ?gcd"
  let ?l = "n div ?gcd"
  let ?gcd' = "gcd ?k ?l"
  have "?gcd dvd m" .. then have gcd_k: "?gcd * ?k = m"
    by (rule dvd_mult_div_cancel)
  have "?gcd dvd n" .. then have gcd_l: "?gcd * ?l = n"
    by (rule dvd_mult_div_cancel)
  from `n\<noteq>0` and gcd_l have "?l \<noteq> 0" by (auto iff del: neq0_conv)
  moreover
  have "\<bar>x\<bar> = real ?k / real ?l"
  proof -
    from gcd have "real ?k / real ?l =
        real (?gcd * ?k) / real (?gcd * ?l)" by simp
    also from gcd_k and gcd_l have "\<dots> = real m / real n" by simp
    also from x_rat have "\<dots> = \<bar>x\<bar>" ..
    finally show ?thesis ..
  qed
  moreover
  have "?gcd' = 1"
  proof -
    have "?gcd * ?gcd' = gcd (?gcd * ?k) (?gcd * ?l)"
      by (rule gcd_mult_distrib_nat)
    with gcd_k gcd_l have "?gcd * ?gcd' = ?gcd" by simp
    with gcd show ?thesis by auto
  qed
  ultimately show ?thesis ..
qed

subsection{*Density of the Rational Reals in the Reals*}

text{* This density proof is due to Stefan Richter and was ported by TN.  The
original source is \emph{Real Analysis} by H.L. Royden.
It employs the Archimedean property of the reals. *}

lemma Rats_dense_in_real:
  fixes x :: real
  assumes "x < y" shows "\<exists>r\<in>\<rat>. x < r \<and> r < y"
proof -
  from `x<y` have "0 < y-x" by simp
  with reals_Archimedean obtain q::nat 
    where q: "inverse (real q) < y-x" and "0 < q" by auto
  def p \<equiv> "ceiling (y * real q) - 1"
  def r \<equiv> "of_int p / real q"
  from q have "x < y - inverse (real q)" by simp
  also have "y - inverse (real q) \<le> r"
    unfolding r_def p_def
    by (simp add: le_divide_eq left_diff_distrib le_of_int_ceiling `0 < q`)
  finally have "x < r" .
  moreover have "r < y"
    unfolding r_def p_def
    by (simp add: divide_less_eq diff_less_eq `0 < q`
      less_ceiling_iff [symmetric])
  moreover from r_def have "r \<in> \<rat>" by simp
  ultimately show ?thesis by fast
qed

lemma of_rat_dense:
  fixes x y :: real
  assumes "x < y"
  shows "\<exists>q :: rat. x < of_rat q \<and> of_rat q < y"
using Rats_dense_in_real [OF `x < y`]
by (auto elim: Rats_cases)


subsection{*Numerals and Arithmetic*}

lemma [code_abbrev]:
  "real_of_int (numeral k) = numeral k"
  "real_of_int (- numeral k) = - numeral k"
  by simp_all

text{*Collapse applications of @{const real} to @{const numeral}*}
lemma real_numeral [simp]:
  "real (numeral v :: int) = numeral v"
  "real (- numeral v :: int) = - numeral v"
by (simp_all add: real_of_int_def)

lemma  real_of_nat_numeral [simp]:
  "real (numeral v :: nat) = numeral v"
by (simp add: real_of_nat_def)

declaration {*
  K (Lin_Arith.add_inj_thms [@{thm real_of_nat_le_iff} RS iffD2, @{thm real_of_nat_inject} RS iffD2]
    (* not needed because x < (y::nat) can be rewritten as Suc x <= y: real_of_nat_less_iff RS iffD2 *)
  #> Lin_Arith.add_inj_thms [@{thm real_of_int_le_iff} RS iffD2, @{thm real_of_int_inject} RS iffD2]
    (* not needed because x < (y::int) can be rewritten as x + 1 <= y: real_of_int_less_iff RS iffD2 *)
  #> Lin_Arith.add_simps [@{thm real_of_nat_zero}, @{thm real_of_nat_Suc}, @{thm real_of_nat_add},
      @{thm real_of_nat_mult}, @{thm real_of_int_zero}, @{thm real_of_one},
      @{thm real_of_int_add}, @{thm real_of_int_minus}, @{thm real_of_int_diff},
      @{thm real_of_int_mult}, @{thm real_of_int_of_nat_eq},
      @{thm real_of_nat_numeral}, @{thm real_numeral(1)}, @{thm real_numeral(2)}]
  #> Lin_Arith.add_inj_const (@{const_name real}, @{typ "nat \<Rightarrow> real"})
  #> Lin_Arith.add_inj_const (@{const_name real}, @{typ "int \<Rightarrow> real"}))
*}


subsection{* Simprules combining x+y and 0: ARE THEY NEEDED?*}

lemma real_add_minus_iff [simp]: "(x + - a = (0::real)) = (x=a)" 
by arith

text {* FIXME: redundant with @{text add_eq_0_iff} below *}
lemma real_add_eq_0_iff: "(x+y = (0::real)) = (y = -x)"
by auto

lemma real_add_less_0_iff: "(x+y < (0::real)) = (y < -x)"
by auto

lemma real_0_less_add_iff: "((0::real) < x+y) = (-x < y)"
by auto

lemma real_add_le_0_iff: "(x+y \<le> (0::real)) = (y \<le> -x)"
by auto

lemma real_0_le_add_iff: "((0::real) \<le> x+y) = (-x \<le> y)"
by auto

subsection {* Lemmas about powers *}

text {* FIXME: declare this in Rings.thy or not at all *}
declare abs_mult_self [simp]

(* used by Import/HOL/real.imp *)
lemma two_realpow_ge_one: "(1::real) \<le> 2 ^ n"
by simp

lemma two_realpow_gt [simp]: "real (n::nat) < 2 ^ n"
apply (induct "n")
apply (auto simp add: real_of_nat_Suc)
apply (subst mult_2)
apply (erule add_less_le_mono)
apply (rule two_realpow_ge_one)
done

text {* TODO: no longer real-specific; rename and move elsewhere *}
lemma realpow_Suc_le_self:
  fixes r :: "'a::linordered_semidom"
  shows "[| 0 \<le> r; r \<le> 1 |] ==> r ^ Suc n \<le> r"
by (insert power_decreasing [of 1 "Suc n" r], simp)

text {* TODO: no longer real-specific; rename and move elsewhere *}
lemma realpow_minus_mult:
  fixes x :: "'a::monoid_mult"
  shows "0 < n \<Longrightarrow> x ^ (n - 1) * x = x ^ n"
by (simp add: power_commutes split add: nat_diff_split)

text {* FIXME: declare this [simp] for all types, or not at all *}
lemma real_two_squares_add_zero_iff [simp]:
  "(x * x + y * y = 0) = ((x::real) = 0 \<and> y = 0)"
by (rule sum_squares_eq_zero_iff)

text {* FIXME: declare this [simp] for all types, or not at all *}
lemma realpow_two_sum_zero_iff [simp]:
     "(x\<^sup>2 + y\<^sup>2 = (0::real)) = (x = 0 & y = 0)"
by (rule sum_power2_eq_zero_iff)

lemma real_minus_mult_self_le [simp]: "-(u * u) \<le> (x * (x::real))"
by (rule_tac y = 0 in order_trans, auto)

lemma realpow_square_minus_le [simp]: "- u\<^sup>2 \<le> (x::real)\<^sup>2"
by (auto simp add: power2_eq_square)


lemma numeral_power_le_real_of_nat_cancel_iff[simp]:
  "(numeral x::real) ^ n \<le> real a \<longleftrightarrow> (numeral x::nat) ^ n \<le> a"
  unfolding real_of_nat_le_iff[symmetric] by simp

lemma real_of_nat_le_numeral_power_cancel_iff[simp]:
  "real a \<le> (numeral x::real) ^ n \<longleftrightarrow> a \<le> (numeral x::nat) ^ n"
  unfolding real_of_nat_le_iff[symmetric] by simp

lemma numeral_power_le_real_of_int_cancel_iff[simp]:
  "(numeral x::real) ^ n \<le> real a \<longleftrightarrow> (numeral x::int) ^ n \<le> a"
  unfolding real_of_int_le_iff[symmetric] by simp

lemma real_of_int_le_numeral_power_cancel_iff[simp]:
  "real a \<le> (numeral x::real) ^ n \<longleftrightarrow> a \<le> (numeral x::int) ^ n"
  unfolding real_of_int_le_iff[symmetric] by simp

lemma neg_numeral_power_le_real_of_int_cancel_iff[simp]:
  "(- numeral x::real) ^ n \<le> real a \<longleftrightarrow> (- numeral x::int) ^ n \<le> a"
  unfolding real_of_int_le_iff[symmetric] by simp

lemma real_of_int_le_neg_numeral_power_cancel_iff[simp]:
  "real a \<le> (- numeral x::real) ^ n \<longleftrightarrow> a \<le> (- numeral x::int) ^ n"
  unfolding real_of_int_le_iff[symmetric] by simp


subsection{*Density of the Reals*}

lemma real_lbound_gt_zero:
     "[| (0::real) < d1; 0 < d2 |] ==> \<exists>e. 0 < e & e < d1 & e < d2"
apply (rule_tac x = " (min d1 d2) /2" in exI)
apply (simp add: min_def)
done


text{*Similar results are proved in @{text Fields}*}
lemma real_less_half_sum: "x < y ==> x < (x+y) / (2::real)"
  by auto

lemma real_gt_half_sum: "x < y ==> (x+y)/(2::real) < y"
  by auto

lemma real_sum_of_halves: "x/2 + x/2 = (x::real)"
  by simp

subsection{*Absolute Value Function for the Reals*}

lemma abs_minus_add_cancel: "abs(x + (-y)) = abs (y + (-(x::real)))"
by (simp add: abs_if)

(* FIXME: redundant, but used by Integration/RealRandVar.thy in AFP *)
lemma abs_le_interval_iff: "(abs x \<le> r) = (-r\<le>x & x\<le>(r::real))"
by (force simp add: abs_le_iff)

lemma abs_add_one_gt_zero: "(0::real) < 1 + abs(x)"
by (simp add: abs_if)

lemma abs_real_of_nat_cancel [simp]: "abs (real x) = real (x::nat)"
by (rule abs_of_nonneg [OF real_of_nat_ge_zero])

lemma abs_add_one_not_less_self: "~ abs(x) + (1::real) < x"
by simp
 
lemma abs_sum_triangle_ineq: "abs ((x::real) + y + (-l + -m)) \<le> abs(x + -l) + abs(y + -m)"
by simp


subsection{*Floor and Ceiling Functions from the Reals to the Integers*}

(* FIXME: theorems for negative numerals *)
lemma numeral_less_real_of_int_iff [simp]:
     "((numeral n) < real (m::int)) = (numeral n < m)"
apply auto
apply (rule real_of_int_less_iff [THEN iffD1])
apply (drule_tac [2] real_of_int_less_iff [THEN iffD2], auto)
done

lemma numeral_less_real_of_int_iff2 [simp]:
     "(real (m::int) < (numeral n)) = (m < numeral n)"
apply auto
apply (rule real_of_int_less_iff [THEN iffD1])
apply (drule_tac [2] real_of_int_less_iff [THEN iffD2], auto)
done

lemma real_of_nat_less_numeral_iff [simp]:
  "real (n::nat) < numeral w \<longleftrightarrow> n < numeral w"
  using real_of_nat_less_iff[of n "numeral w"] by simp

lemma numeral_less_real_of_nat_iff [simp]:
  "numeral w < real (n::nat) \<longleftrightarrow> numeral w < n"
  using real_of_nat_less_iff[of "numeral w" n] by simp

lemma numeral_le_real_of_int_iff [simp]:
     "((numeral n) \<le> real (m::int)) = (numeral n \<le> m)"
by (simp add: linorder_not_less [symmetric])

lemma numeral_le_real_of_int_iff2 [simp]:
     "(real (m::int) \<le> (numeral n)) = (m \<le> numeral n)"
by (simp add: linorder_not_less [symmetric])

lemma floor_real_of_nat [simp]: "floor (real (n::nat)) = int n"
unfolding real_of_nat_def by simp

lemma floor_minus_real_of_nat [simp]: "floor (- real (n::nat)) = - int n"
unfolding real_of_nat_def by (simp add: floor_minus)

lemma floor_real_of_int [simp]: "floor (real (n::int)) = n"
unfolding real_of_int_def by simp

lemma floor_minus_real_of_int [simp]: "floor (- real (n::int)) = - n"
unfolding real_of_int_def by (simp add: floor_minus)

lemma real_lb_ub_int: " \<exists>n::int. real n \<le> r & r < real (n+1)"
unfolding real_of_int_def by (rule floor_exists)

lemma lemma_floor:
  assumes a1: "real m \<le> r" and a2: "r < real n + 1"
  shows "m \<le> (n::int)"
proof -
  have "real m < real n + 1" using a1 a2 by (rule order_le_less_trans)
  also have "... = real (n + 1)" by simp
  finally have "m < n + 1" by (simp only: real_of_int_less_iff)
  thus ?thesis by arith
qed

lemma real_of_int_floor_le [simp]: "real (floor r) \<le> r"
unfolding real_of_int_def by (rule of_int_floor_le)

lemma lemma_floor2: "real n < real (x::int) + 1 ==> n \<le> x"
by (auto intro: lemma_floor)

lemma real_of_int_floor_cancel [simp]:
    "(real (floor x) = x) = (\<exists>n::int. x = real n)"
  using floor_real_of_int by metis

lemma floor_eq: "[| real n < x; x < real n + 1 |] ==> floor x = n"
  unfolding real_of_int_def using floor_unique [of n x] by simp

lemma floor_eq2: "[| real n \<le> x; x < real n + 1 |] ==> floor x = n"
  unfolding real_of_int_def by (rule floor_unique)

lemma floor_eq3: "[| real n < x; x < real (Suc n) |] ==> nat(floor x) = n"
apply (rule inj_int [THEN injD])
apply (simp add: real_of_nat_Suc)
apply (simp add: real_of_nat_Suc floor_eq floor_eq [where n = "int n"])
done

lemma floor_eq4: "[| real n \<le> x; x < real (Suc n) |] ==> nat(floor x) = n"
apply (drule order_le_imp_less_or_eq)
apply (auto intro: floor_eq3)
done

lemma real_of_int_floor_ge_diff_one [simp]: "r - 1 \<le> real(floor r)"
  unfolding real_of_int_def using floor_correct [of r] by simp

lemma real_of_int_floor_gt_diff_one [simp]: "r - 1 < real(floor r)"
  unfolding real_of_int_def using floor_correct [of r] by simp

lemma real_of_int_floor_add_one_ge [simp]: "r \<le> real(floor r) + 1"
  unfolding real_of_int_def using floor_correct [of r] by simp

lemma real_of_int_floor_add_one_gt [simp]: "r < real(floor r) + 1"
  unfolding real_of_int_def using floor_correct [of r] by simp

lemma le_floor: "real a <= x ==> a <= floor x"
  unfolding real_of_int_def by (simp add: le_floor_iff)

lemma real_le_floor: "a <= floor x ==> real a <= x"
  unfolding real_of_int_def by (simp add: le_floor_iff)

lemma le_floor_eq: "(a <= floor x) = (real a <= x)"
  unfolding real_of_int_def by (rule le_floor_iff)

lemma floor_less_eq: "(floor x < a) = (x < real a)"
  unfolding real_of_int_def by (rule floor_less_iff)

lemma less_floor_eq: "(a < floor x) = (real a + 1 <= x)"
  unfolding real_of_int_def by (rule less_floor_iff)

lemma floor_le_eq: "(floor x <= a) = (x < real a + 1)"
  unfolding real_of_int_def by (rule floor_le_iff)

lemma floor_add [simp]: "floor (x + real a) = floor x + a"
  unfolding real_of_int_def by (rule floor_add_of_int)

lemma floor_subtract [simp]: "floor (x - real a) = floor x - a"
  unfolding real_of_int_def by (rule floor_diff_of_int)

lemma le_mult_floor:
  assumes "0 \<le> (a :: real)" and "0 \<le> b"
  shows "floor a * floor b \<le> floor (a * b)"
proof -
  have "real (floor a) \<le> a"
    and "real (floor b) \<le> b" by auto
  hence "real (floor a * floor b) \<le> a * b"
    using assms by (auto intro!: mult_mono)
  also have "a * b < real (floor (a * b) + 1)" by auto
  finally show ?thesis unfolding real_of_int_less_iff by simp
qed

lemma floor_divide_eq_div:
  "floor (real a / real b) = a div b"
proof cases
  assume "b \<noteq> 0 \<or> b dvd a"
  with real_of_int_div3[of a b] show ?thesis
    by (auto simp: real_of_int_div[symmetric] intro!: floor_eq2 real_of_int_div4 neq_le_trans)
       (metis add_left_cancel zero_neq_one real_of_int_div_aux real_of_int_inject
              real_of_int_zero_cancel right_inverse_eq div_self mod_div_trivial)
qed (auto simp: real_of_int_div)

lemma ceiling_real_of_nat [simp]: "ceiling (real (n::nat)) = int n"
  unfolding real_of_nat_def by simp

lemma real_of_int_ceiling_ge [simp]: "r \<le> real (ceiling r)"
  unfolding real_of_int_def by (rule le_of_int_ceiling)

lemma ceiling_real_of_int [simp]: "ceiling (real (n::int)) = n"
  unfolding real_of_int_def by simp

lemma real_of_int_ceiling_cancel [simp]:
     "(real (ceiling x) = x) = (\<exists>n::int. x = real n)"
  using ceiling_real_of_int by metis

lemma ceiling_eq: "[| real n < x; x < real n + 1 |] ==> ceiling x = n + 1"
  unfolding real_of_int_def using ceiling_unique [of "n + 1" x] by simp

lemma ceiling_eq2: "[| real n < x; x \<le> real n + 1 |] ==> ceiling x = n + 1"
  unfolding real_of_int_def using ceiling_unique [of "n + 1" x] by simp

lemma ceiling_eq3: "[| real n - 1 < x; x \<le> real n  |] ==> ceiling x = n"
  unfolding real_of_int_def using ceiling_unique [of n x] by simp

lemma real_of_int_ceiling_diff_one_le [simp]: "real (ceiling r) - 1 \<le> r"
  unfolding real_of_int_def using ceiling_correct [of r] by simp

lemma real_of_int_ceiling_le_add_one [simp]: "real (ceiling r) \<le> r + 1"
  unfolding real_of_int_def using ceiling_correct [of r] by simp

lemma ceiling_le: "x <= real a ==> ceiling x <= a"
  unfolding real_of_int_def by (simp add: ceiling_le_iff)

lemma ceiling_le_real: "ceiling x <= a ==> x <= real a"
  unfolding real_of_int_def by (simp add: ceiling_le_iff)

lemma ceiling_le_eq: "(ceiling x <= a) = (x <= real a)"
  unfolding real_of_int_def by (rule ceiling_le_iff)

lemma less_ceiling_eq: "(a < ceiling x) = (real a < x)"
  unfolding real_of_int_def by (rule less_ceiling_iff)

lemma ceiling_less_eq: "(ceiling x < a) = (x <= real a - 1)"
  unfolding real_of_int_def by (rule ceiling_less_iff)

lemma le_ceiling_eq: "(a <= ceiling x) = (real a - 1 < x)"
  unfolding real_of_int_def by (rule le_ceiling_iff)

lemma ceiling_add [simp]: "ceiling (x + real a) = ceiling x + a"
  unfolding real_of_int_def by (rule ceiling_add_of_int)

lemma ceiling_subtract [simp]: "ceiling (x - real a) = ceiling x - a"
  unfolding real_of_int_def by (rule ceiling_diff_of_int)


subsubsection {* Versions for the natural numbers *}

definition
  natfloor :: "real => nat" where
  "natfloor x = nat(floor x)"

definition
  natceiling :: "real => nat" where
  "natceiling x = nat(ceiling x)"

lemma natfloor_zero [simp]: "natfloor 0 = 0"
  by (unfold natfloor_def, simp)

lemma natfloor_one [simp]: "natfloor 1 = 1"
  by (unfold natfloor_def, simp)

lemma zero_le_natfloor [simp]: "0 <= natfloor x"
  by (unfold natfloor_def, simp)

lemma natfloor_numeral_eq [simp]: "natfloor (numeral n) = numeral n"
  by (unfold natfloor_def, simp)

lemma natfloor_real_of_nat [simp]: "natfloor(real n) = n"
  by (unfold natfloor_def, simp)

lemma real_natfloor_le: "0 <= x ==> real(natfloor x) <= x"
  by (unfold natfloor_def, simp)

lemma natfloor_neg: "x <= 0 ==> natfloor x = 0"
  unfolding natfloor_def by simp

lemma natfloor_mono: "x <= y ==> natfloor x <= natfloor y"
  unfolding natfloor_def by (intro nat_mono floor_mono)

lemma le_natfloor: "real x <= a ==> x <= natfloor a"
  apply (unfold natfloor_def)
  apply (subst nat_int [THEN sym])
  apply (rule nat_mono)
  apply (rule le_floor)
  apply simp
done

lemma natfloor_less_iff: "0 \<le> x \<Longrightarrow> natfloor x < n \<longleftrightarrow> x < real n"
  unfolding natfloor_def real_of_nat_def
  by (simp add: nat_less_iff floor_less_iff)

lemma less_natfloor:
  assumes "0 \<le> x" and "x < real (n :: nat)"
  shows "natfloor x < n"
  using assms by (simp add: natfloor_less_iff)

lemma le_natfloor_eq: "0 <= x ==> (a <= natfloor x) = (real a <= x)"
  apply (rule iffI)
  apply (rule order_trans)
  prefer 2
  apply (erule real_natfloor_le)
  apply (subst real_of_nat_le_iff)
  apply assumption
  apply (erule le_natfloor)
done

lemma le_natfloor_eq_numeral [simp]:
    "~ neg((numeral n)::int) ==> 0 <= x ==>
      (numeral n <= natfloor x) = (numeral n <= x)"
  apply (subst le_natfloor_eq, assumption)
  apply simp
done

lemma le_natfloor_eq_one [simp]: "(1 <= natfloor x) = (1 <= x)"
  apply (case_tac "0 <= x")
  apply (subst le_natfloor_eq, assumption, simp)
  apply (rule iffI)
  apply (subgoal_tac "natfloor x <= natfloor 0")
  apply simp
  apply (rule natfloor_mono)
  apply simp
  apply simp
done

lemma natfloor_eq: "real n <= x ==> x < real n + 1 ==> natfloor x = n"
  unfolding natfloor_def by (simp add: floor_eq2 [where n="int n"])

lemma real_natfloor_add_one_gt: "x < real(natfloor x) + 1"
  apply (case_tac "0 <= x")
  apply (unfold natfloor_def)
  apply simp
  apply simp_all
done

lemma real_natfloor_gt_diff_one: "x - 1 < real(natfloor x)"
using real_natfloor_add_one_gt by (simp add: algebra_simps)

lemma ge_natfloor_plus_one_imp_gt: "natfloor z + 1 <= n ==> z < real n"
  apply (subgoal_tac "z < real(natfloor z) + 1")
  apply arith
  apply (rule real_natfloor_add_one_gt)
done

lemma natfloor_add [simp]: "0 <= x ==> natfloor (x + real a) = natfloor x + a"
  unfolding natfloor_def
  unfolding real_of_int_of_nat_eq [symmetric] floor_add
  by (simp add: nat_add_distrib)

lemma natfloor_add_numeral [simp]:
    "~neg ((numeral n)::int) ==> 0 <= x ==>
      natfloor (x + numeral n) = natfloor x + numeral n"
  by (simp add: natfloor_add [symmetric])

lemma natfloor_add_one: "0 <= x ==> natfloor(x + 1) = natfloor x + 1"
  by (simp add: natfloor_add [symmetric] del: One_nat_def)

lemma natfloor_subtract [simp]:
    "natfloor(x - real a) = natfloor x - a"
  unfolding natfloor_def real_of_int_of_nat_eq [symmetric] floor_subtract
  by simp

lemma natfloor_div_nat:
  assumes "1 <= x" and "y > 0"
  shows "natfloor (x / real y) = natfloor x div y"
proof (rule natfloor_eq)
  have "(natfloor x) div y * y \<le> natfloor x"
    by (rule add_leD1 [where k="natfloor x mod y"], simp)
  thus "real (natfloor x div y) \<le> x / real y"
    using assms by (simp add: le_divide_eq le_natfloor_eq)
  have "natfloor x < (natfloor x) div y * y + y"
    apply (subst mod_div_equality [symmetric])
    apply (rule add_strict_left_mono)
    apply (rule mod_less_divisor)
    apply fact
    done
  thus "x / real y < real (natfloor x div y) + 1"
    using assms
    by (simp add: divide_less_eq natfloor_less_iff distrib_right)
qed

lemma le_mult_natfloor:
  shows "natfloor a * natfloor b \<le> natfloor (a * b)"
  by (cases "0 <= a & 0 <= b")
    (auto simp add: le_natfloor_eq mult_mono' real_natfloor_le natfloor_neg)

lemma natceiling_zero [simp]: "natceiling 0 = 0"
  by (unfold natceiling_def, simp)

lemma natceiling_one [simp]: "natceiling 1 = 1"
  by (unfold natceiling_def, simp)

lemma zero_le_natceiling [simp]: "0 <= natceiling x"
  by (unfold natceiling_def, simp)

lemma natceiling_numeral_eq [simp]: "natceiling (numeral n) = numeral n"
  by (unfold natceiling_def, simp)

lemma natceiling_real_of_nat [simp]: "natceiling(real n) = n"
  by (unfold natceiling_def, simp)

lemma real_natceiling_ge: "x <= real(natceiling x)"
  unfolding natceiling_def by (cases "x < 0", simp_all)

lemma natceiling_neg: "x <= 0 ==> natceiling x = 0"
  unfolding natceiling_def by simp

lemma natceiling_mono: "x <= y ==> natceiling x <= natceiling y"
  unfolding natceiling_def by (intro nat_mono ceiling_mono)

lemma natceiling_le: "x <= real a ==> natceiling x <= a"
  unfolding natceiling_def real_of_nat_def
  by (simp add: nat_le_iff ceiling_le_iff)

lemma natceiling_le_eq: "(natceiling x <= a) = (x <= real a)"
  unfolding natceiling_def real_of_nat_def
  by (simp add: nat_le_iff ceiling_le_iff)

lemma natceiling_le_eq_numeral [simp]:
    "~ neg((numeral n)::int) ==>
      (natceiling x <= numeral n) = (x <= numeral n)"
  by (simp add: natceiling_le_eq)

lemma natceiling_le_eq_one: "(natceiling x <= 1) = (x <= 1)"
  unfolding natceiling_def
  by (simp add: nat_le_iff ceiling_le_iff)

lemma natceiling_eq: "real n < x ==> x <= real n + 1 ==> natceiling x = n + 1"
  unfolding natceiling_def
  by (simp add: ceiling_eq2 [where n="int n"])

lemma natceiling_add [simp]: "0 <= x ==>
    natceiling (x + real a) = natceiling x + a"
  unfolding natceiling_def
  unfolding real_of_int_of_nat_eq [symmetric] ceiling_add
  by (simp add: nat_add_distrib)

lemma natceiling_add_numeral [simp]:
    "~ neg ((numeral n)::int) ==> 0 <= x ==>
      natceiling (x + numeral n) = natceiling x + numeral n"
  by (simp add: natceiling_add [symmetric])

lemma natceiling_add_one: "0 <= x ==> natceiling(x + 1) = natceiling x + 1"
  by (simp add: natceiling_add [symmetric] del: One_nat_def)

lemma natceiling_subtract [simp]: "natceiling(x - real a) = natceiling x - a"
  unfolding natceiling_def real_of_int_of_nat_eq [symmetric] ceiling_subtract
  by simp

lemma Rats_no_top_le: "\<exists> q \<in> \<rat>. (x :: real) \<le> q"
  by (auto intro!: bexI[of _ "of_nat (natceiling x)"]) (metis real_natceiling_ge real_of_nat_def)

lemma Rats_no_bot_less: "\<exists> q \<in> \<rat>. q < (x :: real)"
  apply (auto intro!: bexI[of _ "of_int (floor x - 1)"])
  apply (rule less_le_trans[OF _ of_int_floor_le])
  apply simp
  done

subsection {* Exponentiation with floor *}

lemma floor_power:
  assumes "x = real (floor x)"
  shows "floor (x ^ n) = floor x ^ n"
proof -
  have *: "x ^ n = real (floor x ^ n)"
    using assms by (induct n arbitrary: x) simp_all
  show ?thesis unfolding real_of_int_inject[symmetric]
    unfolding * floor_real_of_int ..
qed

lemma natfloor_power:
  assumes "x = real (natfloor x)"
  shows "natfloor (x ^ n) = natfloor x ^ n"
proof -
  from assms have "0 \<le> floor x" by auto
  note assms[unfolded natfloor_def real_nat_eq_real[OF `0 \<le> floor x`]]
  from floor_power[OF this]
  show ?thesis unfolding natfloor_def nat_power_eq[OF `0 \<le> floor x`, symmetric]
    by simp
qed


subsection {* Implementation of rational real numbers *}

text {* Formal constructor *}

definition Ratreal :: "rat \<Rightarrow> real" where
  [code_abbrev, simp]: "Ratreal = of_rat"

code_datatype Ratreal


text {* Numerals *}

lemma [code_abbrev]:
  "(of_rat (of_int a) :: real) = of_int a"
  by simp

lemma [code_abbrev]:
  "(of_rat 0 :: real) = 0"
  by simp

lemma [code_abbrev]:
  "(of_rat 1 :: real) = 1"
  by simp

lemma [code_abbrev]:
  "(of_rat (numeral k) :: real) = numeral k"
  by simp

lemma [code_abbrev]:
  "(of_rat (- numeral k) :: real) = - numeral k"
  by simp

lemma [code_post]:
  "(of_rat (0 / r)  :: real) = 0"
  "(of_rat (r / 0)  :: real) = 0"
  "(of_rat (1 / 1)  :: real) = 1"
  "(of_rat (numeral k / 1) :: real) = numeral k"
  "(of_rat (- numeral k / 1) :: real) = - numeral k"
  "(of_rat (1 / numeral k) :: real) = 1 / numeral k"
  "(of_rat (1 / - numeral k) :: real) = 1 / - numeral k"
  "(of_rat (numeral k / numeral l)  :: real) = numeral k / numeral l"
  "(of_rat (numeral k / - numeral l)  :: real) = numeral k / - numeral l"
  "(of_rat (- numeral k / numeral l)  :: real) = - numeral k / numeral l"
  "(of_rat (- numeral k / - numeral l)  :: real) = - numeral k / - numeral l"
  by (simp_all add: of_rat_divide of_rat_minus)


text {* Operations *}

lemma zero_real_code [code]:
  "0 = Ratreal 0"
by simp

lemma one_real_code [code]:
  "1 = Ratreal 1"
by simp

instantiation real :: equal
begin

definition "HOL.equal (x\<Colon>real) y \<longleftrightarrow> x - y = 0"

instance proof
qed (simp add: equal_real_def)

lemma real_equal_code [code]:
  "HOL.equal (Ratreal x) (Ratreal y) \<longleftrightarrow> HOL.equal x y"
  by (simp add: equal_real_def equal)

lemma [code nbe]:
  "HOL.equal (x::real) x \<longleftrightarrow> True"
  by (rule equal_refl)

end

lemma real_less_eq_code [code]: "Ratreal x \<le> Ratreal y \<longleftrightarrow> x \<le> y"
  by (simp add: of_rat_less_eq)

lemma real_less_code [code]: "Ratreal x < Ratreal y \<longleftrightarrow> x < y"
  by (simp add: of_rat_less)

lemma real_plus_code [code]: "Ratreal x + Ratreal y = Ratreal (x + y)"
  by (simp add: of_rat_add)

lemma real_times_code [code]: "Ratreal x * Ratreal y = Ratreal (x * y)"
  by (simp add: of_rat_mult)

lemma real_uminus_code [code]: "- Ratreal x = Ratreal (- x)"
  by (simp add: of_rat_minus)

lemma real_minus_code [code]: "Ratreal x - Ratreal y = Ratreal (x - y)"
  by (simp add: of_rat_diff)

lemma real_inverse_code [code]: "inverse (Ratreal x) = Ratreal (inverse x)"
  by (simp add: of_rat_inverse)
 
lemma real_divide_code [code]: "Ratreal x / Ratreal y = Ratreal (x / y)"
  by (simp add: of_rat_divide)

lemma real_floor_code [code]: "floor (Ratreal x) = floor x"
  by (metis Ratreal_def floor_le_iff floor_unique le_floor_iff of_int_floor_le of_rat_of_int_eq real_less_eq_code)


text {* Quickcheck *}

definition (in term_syntax)
  valterm_ratreal :: "rat \<times> (unit \<Rightarrow> Code_Evaluation.term) \<Rightarrow> real \<times> (unit \<Rightarrow> Code_Evaluation.term)" where
  [code_unfold]: "valterm_ratreal k = Code_Evaluation.valtermify Ratreal {\<cdot>} k"

notation fcomp (infixl "\<circ>>" 60)
notation scomp (infixl "\<circ>\<rightarrow>" 60)

instantiation real :: random
begin

definition
  "Quickcheck_Random.random i = Quickcheck_Random.random i \<circ>\<rightarrow> (\<lambda>r. Pair (valterm_ratreal r))"

instance ..

end

no_notation fcomp (infixl "\<circ>>" 60)
no_notation scomp (infixl "\<circ>\<rightarrow>" 60)

instantiation real :: exhaustive
begin

definition
  "exhaustive_real f d = Quickcheck_Exhaustive.exhaustive (%r. f (Ratreal r)) d"

instance ..

end

instantiation real :: full_exhaustive
begin

definition
  "full_exhaustive_real f d = Quickcheck_Exhaustive.full_exhaustive (%r. f (valterm_ratreal r)) d"

instance ..

end

instantiation real :: narrowing
begin

definition
  "narrowing = Quickcheck_Narrowing.apply (Quickcheck_Narrowing.cons Ratreal) narrowing"

instance ..

end


subsection {* Setup for Nitpick *}

declaration {*
  Nitpick_HOL.register_frac_type @{type_name real}
   [(@{const_name zero_real_inst.zero_real}, @{const_name Nitpick.zero_frac}),
    (@{const_name one_real_inst.one_real}, @{const_name Nitpick.one_frac}),
    (@{const_name plus_real_inst.plus_real}, @{const_name Nitpick.plus_frac}),
    (@{const_name times_real_inst.times_real}, @{const_name Nitpick.times_frac}),
    (@{const_name uminus_real_inst.uminus_real}, @{const_name Nitpick.uminus_frac}),
    (@{const_name inverse_real_inst.inverse_real}, @{const_name Nitpick.inverse_frac}),
    (@{const_name ord_real_inst.less_real}, @{const_name Nitpick.less_frac}),
    (@{const_name ord_real_inst.less_eq_real}, @{const_name Nitpick.less_eq_frac})]
*}

lemmas [nitpick_unfold] = inverse_real_inst.inverse_real one_real_inst.one_real
    ord_real_inst.less_real ord_real_inst.less_eq_real plus_real_inst.plus_real
    times_real_inst.times_real uminus_real_inst.uminus_real
    zero_real_inst.zero_real


subsection {* Setup for SMT *}

ML_file "Tools/SMT/smt_real.ML"
setup SMT_Real.setup
ML_file "Tools/SMT2/smt2_real.ML"
ML_file "Tools/SMT2/z3_new_real.ML"

lemma [z3_new_rule]:
  "0 + (x::real) = x"
  "x + 0 = x"
  "0 * x = 0"
  "1 * x = x"
  "x + y = y + x"
  by auto

end
