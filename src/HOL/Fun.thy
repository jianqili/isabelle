(*  Title:      HOL/Fun.thy
    Author:     Tobias Nipkow, Cambridge University Computer Laboratory
    Author:     Andrei Popescu, TU Muenchen
    Copyright   1994, 2012
*)

header {* Notions about functions *}

theory Fun
imports Set
keywords "functor" :: thy_goal
begin

lemma apply_inverse:
  "f x = u \<Longrightarrow> (\<And>x. P x \<Longrightarrow> g (f x) = x) \<Longrightarrow> P x \<Longrightarrow> x = g u"
  by auto


subsection {* The Identity Function @{text id} *}

definition id :: "'a \<Rightarrow> 'a" where
  "id = (\<lambda>x. x)"

lemma id_apply [simp]: "id x = x"
  by (simp add: id_def)

lemma image_id [simp]: "image id = id"
  by (simp add: id_def fun_eq_iff)

lemma vimage_id [simp]: "vimage id = id"
  by (simp add: id_def fun_eq_iff)

code_printing
  constant id \<rightharpoonup> (Haskell) "id"


subsection {* The Composition Operator @{text "f \<circ> g"} *}

definition comp :: "('b \<Rightarrow> 'c) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'c" (infixl "o" 55) where
  "f o g = (\<lambda>x. f (g x))"

notation (xsymbols)
  comp  (infixl "\<circ>" 55)

notation (HTML output)
  comp  (infixl "\<circ>" 55)

lemma comp_apply [simp]: "(f o g) x = f (g x)"
  by (simp add: comp_def)

lemma comp_assoc: "(f o g) o h = f o (g o h)"
  by (simp add: fun_eq_iff)

lemma id_comp [simp]: "id o g = g"
  by (simp add: fun_eq_iff)

lemma comp_id [simp]: "f o id = f"
  by (simp add: fun_eq_iff)

lemma comp_eq_dest:
  "a o b = c o d \<Longrightarrow> a (b v) = c (d v)"
  by (simp add: fun_eq_iff)

lemma comp_eq_elim:
  "a o b = c o d \<Longrightarrow> ((\<And>v. a (b v) = c (d v)) \<Longrightarrow> R) \<Longrightarrow> R"
  by (simp add: fun_eq_iff) 

lemma comp_eq_dest_lhs: "a o b = c \<Longrightarrow> a (b v) = c v"
  by clarsimp

lemma comp_eq_id_dest: "a o b = id o c \<Longrightarrow> a (b v) = c v"
  by clarsimp

lemma image_comp:
  "f ` (g ` r) = (f o g) ` r"
  by auto

lemma vimage_comp:
  "f -` (g -` x) = (g \<circ> f) -` x"
  by auto

code_printing
  constant comp \<rightharpoonup> (SML) infixl 5 "o" and (Haskell) infixr 9 "."


subsection {* The Forward Composition Operator @{text fcomp} *}

definition fcomp :: "('a \<Rightarrow> 'b) \<Rightarrow> ('b \<Rightarrow> 'c) \<Rightarrow> 'a \<Rightarrow> 'c" (infixl "\<circ>>" 60) where
  "f \<circ>> g = (\<lambda>x. g (f x))"

lemma fcomp_apply [simp]:  "(f \<circ>> g) x = g (f x)"
  by (simp add: fcomp_def)

lemma fcomp_assoc: "(f \<circ>> g) \<circ>> h = f \<circ>> (g \<circ>> h)"
  by (simp add: fcomp_def)

lemma id_fcomp [simp]: "id \<circ>> g = g"
  by (simp add: fcomp_def)

lemma fcomp_id [simp]: "f \<circ>> id = f"
  by (simp add: fcomp_def)

code_printing
  constant fcomp \<rightharpoonup> (Eval) infixl 1 "#>"

no_notation fcomp (infixl "\<circ>>" 60)


subsection {* Mapping functions *}

definition map_fun :: "('c \<Rightarrow> 'a) \<Rightarrow> ('b \<Rightarrow> 'd) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'c \<Rightarrow> 'd" where
  "map_fun f g h = g \<circ> h \<circ> f"

lemma map_fun_apply [simp]:
  "map_fun f g h x = g (h (f x))"
  by (simp add: map_fun_def)


subsection {* Injectivity and Bijectivity *}

definition inj_on :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a set \<Rightarrow> bool" where -- "injective"
  "inj_on f A \<longleftrightarrow> (\<forall>x\<in>A. \<forall>y\<in>A. f x = f y \<longrightarrow> x = y)"

definition bij_betw :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a set \<Rightarrow> 'b set \<Rightarrow> bool" where -- "bijective"
  "bij_betw f A B \<longleftrightarrow> inj_on f A \<and> f ` A = B"

text{*A common special case: functions injective, surjective or bijective over
the entire domain type.*}

abbreviation
  "inj f \<equiv> inj_on f UNIV"

abbreviation surj :: "('a \<Rightarrow> 'b) \<Rightarrow> bool" where -- "surjective"
  "surj f \<equiv> (range f = UNIV)"

abbreviation
  "bij f \<equiv> bij_betw f UNIV UNIV"

text{* The negated case: *}
translations
"\<not> CONST surj f" <= "CONST range f \<noteq> CONST UNIV"

lemma injI:
  assumes "\<And>x y. f x = f y \<Longrightarrow> x = y"
  shows "inj f"
  using assms unfolding inj_on_def by auto

theorem range_ex1_eq: "inj f \<Longrightarrow> b : range f = (EX! x. b = f x)"
  by (unfold inj_on_def, blast)

lemma injD: "[| inj(f); f(x) = f(y) |] ==> x=y"
by (simp add: inj_on_def)

lemma inj_on_eq_iff: "inj_on f A ==> x:A ==> y:A ==> (f(x) = f(y)) = (x=y)"
by (force simp add: inj_on_def)

lemma inj_on_cong:
  "(\<And> a. a : A \<Longrightarrow> f a = g a) \<Longrightarrow> inj_on f A = inj_on g A"
unfolding inj_on_def by auto

lemma inj_on_strict_subset:
  "inj_on f B \<Longrightarrow> A \<subset> B \<Longrightarrow> f ` A \<subset> f ` B"
  unfolding inj_on_def by blast

lemma inj_comp:
  "inj f \<Longrightarrow> inj g \<Longrightarrow> inj (f \<circ> g)"
  by (simp add: inj_on_def)

lemma inj_fun: "inj f \<Longrightarrow> inj (\<lambda>x y. f x)"
  by (simp add: inj_on_def fun_eq_iff)

lemma inj_eq: "inj f ==> (f(x) = f(y)) = (x=y)"
by (simp add: inj_on_eq_iff)

lemma inj_on_id[simp]: "inj_on id A"
  by (simp add: inj_on_def)

lemma inj_on_id2[simp]: "inj_on (%x. x) A"
by (simp add: inj_on_def)

lemma inj_on_Int: "inj_on f A \<or> inj_on f B \<Longrightarrow> inj_on f (A \<inter> B)"
unfolding inj_on_def by blast

lemma surj_id: "surj id"
by simp

lemma bij_id[simp]: "bij id"
by (simp add: bij_betw_def)

lemma inj_onI:
    "(!! x y. [|  x:A;  y:A;  f(x) = f(y) |] ==> x=y) ==> inj_on f A"
by (simp add: inj_on_def)

lemma inj_on_inverseI: "(!!x. x:A ==> g(f(x)) = x) ==> inj_on f A"
by (auto dest:  arg_cong [of concl: g] simp add: inj_on_def)

lemma inj_onD: "[| inj_on f A;  f(x)=f(y);  x:A;  y:A |] ==> x=y"
by (unfold inj_on_def, blast)

lemma inj_on_iff: "[| inj_on f A;  x:A;  y:A |] ==> (f(x)=f(y)) = (x=y)"
  by (fact inj_on_eq_iff)

lemma comp_inj_on:
     "[| inj_on f A;  inj_on g (f`A) |] ==> inj_on (g o f) A"
by (simp add: comp_def inj_on_def)

lemma inj_on_imageI: "inj_on (g o f) A \<Longrightarrow> inj_on g (f ` A)"
  by (simp add: inj_on_def) blast

lemma inj_on_image_iff: "\<lbrakk> ALL x:A. ALL y:A. (g(f x) = g(f y)) = (g x = g y);
  inj_on f A \<rbrakk> \<Longrightarrow> inj_on g (f ` A) = inj_on g A"
apply(unfold inj_on_def)
apply blast
done

lemma inj_on_contraD: "[| inj_on f A;  ~x=y;  x:A;  y:A |] ==> ~ f(x)=f(y)"
by (unfold inj_on_def, blast)

lemma inj_singleton: "inj (%s. {s})"
by (simp add: inj_on_def)

lemma inj_on_empty[iff]: "inj_on f {}"
by(simp add: inj_on_def)

lemma subset_inj_on: "[| inj_on f B; A <= B |] ==> inj_on f A"
by (unfold inj_on_def, blast)

lemma inj_on_Un:
 "inj_on f (A Un B) =
  (inj_on f A & inj_on f B & f`(A-B) Int f`(B-A) = {})"
apply(unfold inj_on_def)
apply (blast intro:sym)
done

lemma inj_on_insert[iff]:
  "inj_on f (insert a A) = (inj_on f A & f a ~: f`(A-{a}))"
apply(unfold inj_on_def)
apply (blast intro:sym)
done

lemma inj_on_diff: "inj_on f A ==> inj_on f (A-B)"
apply(unfold inj_on_def)
apply (blast)
done

lemma comp_inj_on_iff:
  "inj_on f A \<Longrightarrow> inj_on f' (f ` A) \<longleftrightarrow> inj_on (f' o f) A"
by(auto simp add: comp_inj_on inj_on_def)

lemma inj_on_imageI2:
  "inj_on (f' o f) A \<Longrightarrow> inj_on f A"
by(auto simp add: comp_inj_on inj_on_def)

lemma inj_img_insertE:
  assumes "inj_on f A"
  assumes "x \<notin> B" and "insert x B = f ` A"
  obtains x' A' where "x' \<notin> A'" and "A = insert x' A'"
    and "x = f x'" and "B = f ` A'"
proof -
  from assms have "x \<in> f ` A" by auto
  then obtain x' where *: "x' \<in> A" "x = f x'" by auto
  then have "A = insert x' (A - {x'})" by auto
  with assms * have "B = f ` (A - {x'})"
    by (auto dest: inj_on_contraD)
  have "x' \<notin> A - {x'}" by simp
  from `x' \<notin> A - {x'}` `A = insert x' (A - {x'})` `x = f x'` `B = image f (A - {x'})`
  show ?thesis ..
qed

lemma linorder_injI:
  assumes hyp: "\<And>x y. x < (y::'a::linorder) \<Longrightarrow> f x \<noteq> f y"
  shows "inj f"
  -- {* Courtesy of Stephan Merz *}
proof (rule inj_onI)
  fix x y
  assume f_eq: "f x = f y"
  show "x = y" by (rule linorder_cases) (auto dest: hyp simp: f_eq)
qed

lemma surj_def: "surj f \<longleftrightarrow> (\<forall>y. \<exists>x. y = f x)"
  by auto

lemma surjI: assumes *: "\<And> x. g (f x) = x" shows "surj g"
  using *[symmetric] by auto

lemma surjD: "surj f \<Longrightarrow> \<exists>x. y = f x"
  by (simp add: surj_def)

lemma surjE: "surj f \<Longrightarrow> (\<And>x. y = f x \<Longrightarrow> C) \<Longrightarrow> C"
  by (simp add: surj_def, blast)

lemma comp_surj: "[| surj f;  surj g |] ==> surj (g o f)"
apply (simp add: comp_def surj_def, clarify)
apply (drule_tac x = y in spec, clarify)
apply (drule_tac x = x in spec, blast)
done

lemma bij_betw_imageI:
  "\<lbrakk> inj_on f A; f ` A = B \<rbrakk> \<Longrightarrow> bij_betw f A B"
unfolding bij_betw_def by clarify

lemma bij_betw_imp_surj_on: "bij_betw f A B \<Longrightarrow> f ` A = B"
  unfolding bij_betw_def by clarify

lemma bij_betw_imp_surj: "bij_betw f A UNIV \<Longrightarrow> surj f"
  unfolding bij_betw_def by auto

lemma bij_betw_empty1:
  assumes "bij_betw f {} A"
  shows "A = {}"
using assms unfolding bij_betw_def by blast

lemma bij_betw_empty2:
  assumes "bij_betw f A {}"
  shows "A = {}"
using assms unfolding bij_betw_def by blast

lemma inj_on_imp_bij_betw:
  "inj_on f A \<Longrightarrow> bij_betw f A (f ` A)"
unfolding bij_betw_def by simp

lemma bij_def: "bij f \<longleftrightarrow> inj f \<and> surj f"
  unfolding bij_betw_def ..

lemma bijI: "[| inj f; surj f |] ==> bij f"
by (simp add: bij_def)

lemma bij_is_inj: "bij f ==> inj f"
by (simp add: bij_def)

lemma bij_is_surj: "bij f ==> surj f"
by (simp add: bij_def)

lemma bij_betw_imp_inj_on: "bij_betw f A B \<Longrightarrow> inj_on f A"
by (simp add: bij_betw_def)

lemma bij_betw_trans:
  "bij_betw f A B \<Longrightarrow> bij_betw g B C \<Longrightarrow> bij_betw (g o f) A C"
by(auto simp add:bij_betw_def comp_inj_on)

lemma bij_comp: "bij f \<Longrightarrow> bij g \<Longrightarrow> bij (g o f)"
  by (rule bij_betw_trans)

lemma bij_betw_comp_iff:
  "bij_betw f A A' \<Longrightarrow> bij_betw f' A' A'' \<longleftrightarrow> bij_betw (f' o f) A A''"
by(auto simp add: bij_betw_def inj_on_def)

lemma bij_betw_comp_iff2:
  assumes BIJ: "bij_betw f' A' A''" and IM: "f ` A \<le> A'"
  shows "bij_betw f A A' \<longleftrightarrow> bij_betw (f' o f) A A''"
using assms
proof(auto simp add: bij_betw_comp_iff)
  assume *: "bij_betw (f' \<circ> f) A A''"
  thus "bij_betw f A A'"
  using IM
  proof(auto simp add: bij_betw_def)
    assume "inj_on (f' \<circ> f) A"
    thus "inj_on f A" using inj_on_imageI2 by blast
  next
    fix a' assume **: "a' \<in> A'"
    hence "f' a' \<in> A''" using BIJ unfolding bij_betw_def by auto
    then obtain a where 1: "a \<in> A \<and> f'(f a) = f' a'" using *
    unfolding bij_betw_def by force
    hence "f a \<in> A'" using IM by auto
    hence "f a = a'" using BIJ ** 1 unfolding bij_betw_def inj_on_def by auto
    thus "a' \<in> f ` A" using 1 by auto
  qed
qed

lemma bij_betw_inv: assumes "bij_betw f A B" shows "EX g. bij_betw g B A"
proof -
  have i: "inj_on f A" and s: "f ` A = B"
    using assms by(auto simp:bij_betw_def)
  let ?P = "%b a. a:A \<and> f a = b" let ?g = "%b. The (?P b)"
  { fix a b assume P: "?P b a"
    hence ex1: "\<exists>a. ?P b a" using s by blast
    hence uex1: "\<exists>!a. ?P b a" by(blast dest:inj_onD[OF i])
    hence " ?g b = a" using the1_equality[OF uex1, OF P] P by simp
  } note g = this
  have "inj_on ?g B"
  proof(rule inj_onI)
    fix x y assume "x:B" "y:B" "?g x = ?g y"
    from s `x:B` obtain a1 where a1: "?P x a1" by blast
    from s `y:B` obtain a2 where a2: "?P y a2" by blast
    from g[OF a1] a1 g[OF a2] a2 `?g x = ?g y` show "x=y" by simp
  qed
  moreover have "?g ` B = A"
  proof(auto simp: image_def)
    fix b assume "b:B"
    with s obtain a where P: "?P b a" by blast
    thus "?g b \<in> A" using g[OF P] by auto
  next
    fix a assume "a:A"
    then obtain b where P: "?P b a" using s by blast
    then have "b:B" using s by blast
    with g[OF P] show "\<exists>b\<in>B. a = ?g b" by blast
  qed
  ultimately show ?thesis by(auto simp:bij_betw_def)
qed

lemma bij_betw_cong:
  "(\<And> a. a \<in> A \<Longrightarrow> f a = g a) \<Longrightarrow> bij_betw f A A' = bij_betw g A A'"
unfolding bij_betw_def inj_on_def by force

lemma bij_betw_id[intro, simp]:
  "bij_betw id A A"
unfolding bij_betw_def id_def by auto

lemma bij_betw_id_iff:
  "bij_betw id A B \<longleftrightarrow> A = B"
by(auto simp add: bij_betw_def)

lemma bij_betw_combine:
  assumes "bij_betw f A B" "bij_betw f C D" "B \<inter> D = {}"
  shows "bij_betw f (A \<union> C) (B \<union> D)"
  using assms unfolding bij_betw_def inj_on_Un image_Un by auto

lemma bij_betw_subset:
  assumes BIJ: "bij_betw f A A'" and
          SUB: "B \<le> A" and IM: "f ` B = B'"
  shows "bij_betw f B B'"
using assms
by(unfold bij_betw_def inj_on_def, auto simp add: inj_on_def)

lemma surj_image_vimage_eq: "surj f ==> f ` (f -` A) = A"
by simp

lemma surj_vimage_empty:
  assumes "surj f" shows "f -` A = {} \<longleftrightarrow> A = {}"
  using surj_image_vimage_eq[OF `surj f`, of A]
  by (intro iffI) fastforce+

lemma inj_vimage_image_eq: "inj f ==> f -` (f ` A) = A"
by (simp add: inj_on_def, blast)

lemma vimage_subsetD: "surj f ==> f -` B <= A ==> B <= f ` A"
by (blast intro: sym)

lemma vimage_subsetI: "inj f ==> B <= f ` A ==> f -` B <= A"
by (unfold inj_on_def, blast)

lemma vimage_subset_eq: "bij f ==> (f -` B <= A) = (B <= f ` A)"
apply (unfold bij_def)
apply (blast del: subsetI intro: vimage_subsetI vimage_subsetD)
done

lemma inj_on_image_eq_iff: "\<lbrakk> inj_on f C; A \<subseteq> C; B \<subseteq> C \<rbrakk> \<Longrightarrow> f ` A = f ` B \<longleftrightarrow> A = B"
by(fastforce simp add: inj_on_def)

lemma inj_on_Un_image_eq_iff: "inj_on f (A \<union> B) \<Longrightarrow> f ` A = f ` B \<longleftrightarrow> A = B"
by(erule inj_on_image_eq_iff) simp_all

lemma inj_on_image_Int:
   "[| inj_on f C;  A<=C;  B<=C |] ==> f`(A Int B) = f`A Int f`B"
apply (simp add: inj_on_def, blast)
done

lemma inj_on_image_set_diff:
   "[| inj_on f C;  A<=C;  B<=C |] ==> f`(A-B) = f`A - f`B"
apply (simp add: inj_on_def, blast)
done

lemma image_Int: "inj f ==> f`(A Int B) = f`A Int f`B"
by (simp add: inj_on_def, blast)

lemma image_set_diff: "inj f ==> f`(A-B) = f`A - f`B"
by (simp add: inj_on_def, blast)

lemma inj_image_mem_iff: "inj f ==> (f a : f`A) = (a : A)"
by (blast dest: injD)

lemma inj_image_subset_iff: "inj f ==> (f`A <= f`B) = (A<=B)"
by (simp add: inj_on_def, blast)

lemma inj_image_eq_iff: "inj f ==> (f`A = f`B) = (A = B)"
by (blast dest: injD)

lemma surj_Compl_image_subset: "surj f ==> -(f`A) <= f`(-A)"
by auto

lemma inj_image_Compl_subset: "inj f ==> f`(-A) <= -(f`A)"
by (auto simp add: inj_on_def)

lemma bij_image_Compl_eq: "bij f ==> f`(-A) = -(f`A)"
apply (simp add: bij_def)
apply (rule equalityI)
apply (simp_all (no_asm_simp) add: inj_image_Compl_subset surj_Compl_image_subset)
done

lemma inj_vimage_singleton: "inj f \<Longrightarrow> f -` {a} \<subseteq> {THE x. f x = a}"
  -- {* The inverse image of a singleton under an injective function
         is included in a singleton. *}
  apply (auto simp add: inj_on_def)
  apply (blast intro: the_equality [symmetric])
  done

lemma inj_on_vimage_singleton:
  "inj_on f A \<Longrightarrow> f -` {a} \<inter> A \<subseteq> {THE x. x \<in> A \<and> f x = a}"
  by (auto simp add: inj_on_def intro: the_equality [symmetric])

lemma (in ordered_ab_group_add) inj_uminus[simp, intro]: "inj_on uminus A"
  by (auto intro!: inj_onI)

lemma (in linorder) strict_mono_imp_inj_on: "strict_mono f \<Longrightarrow> inj_on f A"
  by (auto intro!: inj_onI dest: strict_mono_eq)

lemma bij_betw_byWitness:
assumes LEFT: "\<forall>a \<in> A. f'(f a) = a" and
        RIGHT: "\<forall>a' \<in> A'. f(f' a') = a'" and
        IM1: "f ` A \<le> A'" and IM2: "f' ` A' \<le> A"
shows "bij_betw f A A'"
using assms
proof(unfold bij_betw_def inj_on_def, safe)
  fix a b assume *: "a \<in> A" "b \<in> A" and **: "f a = f b"
  have "a = f'(f a) \<and> b = f'(f b)" using * LEFT by simp
  with ** show "a = b" by simp
next
  fix a' assume *: "a' \<in> A'"
  hence "f' a' \<in> A" using IM2 by blast
  moreover
  have "a' = f(f' a')" using * RIGHT by simp
  ultimately show "a' \<in> f ` A" by blast
qed

corollary notIn_Un_bij_betw:
assumes NIN: "b \<notin> A" and NIN': "f b \<notin> A'" and
       BIJ: "bij_betw f A A'"
shows "bij_betw f (A \<union> {b}) (A' \<union> {f b})"
proof-
  have "bij_betw f {b} {f b}"
  unfolding bij_betw_def inj_on_def by simp
  with assms show ?thesis
  using bij_betw_combine[of f A A' "{b}" "{f b}"] by blast
qed

lemma notIn_Un_bij_betw3:
assumes NIN: "b \<notin> A" and NIN': "f b \<notin> A'"
shows "bij_betw f A A' = bij_betw f (A \<union> {b}) (A' \<union> {f b})"
proof
  assume "bij_betw f A A'"
  thus "bij_betw f (A \<union> {b}) (A' \<union> {f b})"
  using assms notIn_Un_bij_betw[of b A f A'] by blast
next
  assume *: "bij_betw f (A \<union> {b}) (A' \<union> {f b})"
  have "f ` A = A'"
  proof(auto)
    fix a assume **: "a \<in> A"
    hence "f a \<in> A' \<union> {f b}" using * unfolding bij_betw_def by blast
    moreover
    {assume "f a = f b"
     hence "a = b" using * ** unfolding bij_betw_def inj_on_def by blast
     with NIN ** have False by blast
    }
    ultimately show "f a \<in> A'" by blast
  next
    fix a' assume **: "a' \<in> A'"
    hence "a' \<in> f`(A \<union> {b})"
    using * by (auto simp add: bij_betw_def)
    then obtain a where 1: "a \<in> A \<union> {b} \<and> f a = a'" by blast
    moreover
    {assume "a = b" with 1 ** NIN' have False by blast
    }
    ultimately have "a \<in> A" by blast
    with 1 show "a' \<in> f ` A" by blast
  qed
  thus "bij_betw f A A'" using * bij_betw_subset[of f "A \<union> {b}" _ A] by blast
qed


subsection{*Function Updating*}

definition fun_upd :: "('a => 'b) => 'a => 'b => ('a => 'b)" where
  "fun_upd f a b == % x. if x=a then b else f x"

nonterminal updbinds and updbind

syntax
  "_updbind" :: "['a, 'a] => updbind"             ("(2_ :=/ _)")
  ""         :: "updbind => updbinds"             ("_")
  "_updbinds":: "[updbind, updbinds] => updbinds" ("_,/ _")
  "_Update"  :: "['a, updbinds] => 'a"            ("_/'((_)')" [1000, 0] 900)

translations
  "_Update f (_updbinds b bs)" == "_Update (_Update f b) bs"
  "f(x:=y)" == "CONST fun_upd f x y"

(* Hint: to define the sum of two functions (or maps), use case_sum.
         A nice infix syntax could be defined (in Datatype.thy or below) by
notation
  case_sum  (infixr "'(+')"80)
*)

lemma fun_upd_idem_iff: "(f(x:=y) = f) = (f x = y)"
apply (simp add: fun_upd_def, safe)
apply (erule subst)
apply (rule_tac [2] ext, auto)
done

lemma fun_upd_idem: "f x = y ==> f(x:=y) = f"
  by (simp only: fun_upd_idem_iff)

lemma fun_upd_triv [iff]: "f(x := f x) = f"
  by (simp only: fun_upd_idem)

lemma fun_upd_apply [simp]: "(f(x:=y))z = (if z=x then y else f z)"
by (simp add: fun_upd_def)

(* fun_upd_apply supersedes these two,   but they are useful
   if fun_upd_apply is intentionally removed from the simpset *)
lemma fun_upd_same: "(f(x:=y)) x = y"
by simp

lemma fun_upd_other: "z~=x ==> (f(x:=y)) z = f z"
by simp

lemma fun_upd_upd [simp]: "f(x:=y,x:=z) = f(x:=z)"
by (simp add: fun_eq_iff)

lemma fun_upd_twist: "a ~= c ==> (m(a:=b))(c:=d) = (m(c:=d))(a:=b)"
by (rule ext, auto)

lemma inj_on_fun_updI:
  "inj_on f A \<Longrightarrow> y \<notin> f ` A \<Longrightarrow> inj_on (f(x := y)) A"
  by (fastforce simp: inj_on_def)

lemma fun_upd_image:
     "f(x:=y) ` A = (if x \<in> A then insert y (f ` (A-{x})) else f ` A)"
by auto

lemma fun_upd_comp: "f \<circ> (g(x := y)) = (f \<circ> g)(x := f y)"
  by auto


subsection {* @{text override_on} *}

definition override_on :: "('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'a set \<Rightarrow> 'a \<Rightarrow> 'b" where
  "override_on f g A = (\<lambda>a. if a \<in> A then g a else f a)"

lemma override_on_emptyset[simp]: "override_on f g {} = f"
by(simp add:override_on_def)

lemma override_on_apply_notin[simp]: "a ~: A ==> (override_on f g A) a = f a"
by(simp add:override_on_def)

lemma override_on_apply_in[simp]: "a : A ==> (override_on f g A) a = g a"
by(simp add:override_on_def)


subsection {* @{text swap} *}

definition swap :: "'a \<Rightarrow> 'a \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b)"
where
  "swap a b f = f (a := f b, b:= f a)"

lemma swap_apply [simp]:
  "swap a b f a = f b"
  "swap a b f b = f a"
  "c \<noteq> a \<Longrightarrow> c \<noteq> b \<Longrightarrow> swap a b f c = f c"
  by (simp_all add: swap_def)

lemma swap_self [simp]:
  "swap a a f = f"
  by (simp add: swap_def)

lemma swap_commute:
  "swap a b f = swap b a f"
  by (simp add: fun_upd_def swap_def fun_eq_iff)

lemma swap_nilpotent [simp]:
  "swap a b (swap a b f) = f"
  by (rule ext, simp add: fun_upd_def swap_def)

lemma swap_comp_involutory [simp]:
  "swap a b \<circ> swap a b = id"
  by (rule ext) simp

lemma swap_triple:
  assumes "a \<noteq> c" and "b \<noteq> c"
  shows "swap a b (swap b c (swap a b f)) = swap a c f"
  using assms by (simp add: fun_eq_iff swap_def)

lemma comp_swap: "f \<circ> swap a b g = swap a b (f \<circ> g)"
  by (rule ext, simp add: fun_upd_def swap_def)

lemma swap_image_eq [simp]:
  assumes "a \<in> A" "b \<in> A" shows "swap a b f ` A = f ` A"
proof -
  have subset: "\<And>f. swap a b f ` A \<subseteq> f ` A"
    using assms by (auto simp: image_iff swap_def)
  then have "swap a b (swap a b f) ` A \<subseteq> (swap a b f) ` A" .
  with subset[of f] show ?thesis by auto
qed

lemma inj_on_imp_inj_on_swap:
  "\<lbrakk>inj_on f A; a \<in> A; b \<in> A\<rbrakk> \<Longrightarrow> inj_on (swap a b f) A"
  by (simp add: inj_on_def swap_def, blast)

lemma inj_on_swap_iff [simp]:
  assumes A: "a \<in> A" "b \<in> A" shows "inj_on (swap a b f) A \<longleftrightarrow> inj_on f A"
proof
  assume "inj_on (swap a b f) A"
  with A have "inj_on (swap a b (swap a b f)) A"
    by (iprover intro: inj_on_imp_inj_on_swap)
  thus "inj_on f A" by simp
next
  assume "inj_on f A"
  with A show "inj_on (swap a b f) A" by (iprover intro: inj_on_imp_inj_on_swap)
qed

lemma surj_imp_surj_swap: "surj f \<Longrightarrow> surj (swap a b f)"
  by simp

lemma surj_swap_iff [simp]: "surj (swap a b f) \<longleftrightarrow> surj f"
  by simp

lemma bij_betw_swap_iff [simp]:
  "\<lbrakk> x \<in> A; y \<in> A \<rbrakk> \<Longrightarrow> bij_betw (swap x y f) A B \<longleftrightarrow> bij_betw f A B"
  by (auto simp: bij_betw_def)

lemma bij_swap_iff [simp]: "bij (swap a b f) \<longleftrightarrow> bij f"
  by simp

hide_const (open) swap


subsection {* Inversion of injective functions *}

definition the_inv_into :: "'a set => ('a => 'b) => ('b => 'a)" where
  "the_inv_into A f == %x. THE y. y : A & f y = x"

lemma the_inv_into_f_f:
  "[| inj_on f A;  x : A |] ==> the_inv_into A f (f x) = x"
apply (simp add: the_inv_into_def inj_on_def)
apply blast
done

lemma f_the_inv_into_f:
  "inj_on f A ==> y : f`A  ==> f (the_inv_into A f y) = y"
apply (simp add: the_inv_into_def)
apply (rule the1I2)
 apply(blast dest: inj_onD)
apply blast
done

lemma the_inv_into_into:
  "[| inj_on f A; x : f ` A; A <= B |] ==> the_inv_into A f x : B"
apply (simp add: the_inv_into_def)
apply (rule the1I2)
 apply(blast dest: inj_onD)
apply blast
done

lemma the_inv_into_onto[simp]:
  "inj_on f A ==> the_inv_into A f ` (f ` A) = A"
by (fast intro:the_inv_into_into the_inv_into_f_f[symmetric])

lemma the_inv_into_f_eq:
  "[| inj_on f A; f x = y; x : A |] ==> the_inv_into A f y = x"
  apply (erule subst)
  apply (erule the_inv_into_f_f, assumption)
  done

lemma the_inv_into_comp:
  "[| inj_on f (g ` A); inj_on g A; x : f ` g ` A |] ==>
  the_inv_into A (f o g) x = (the_inv_into A g o the_inv_into (g ` A) f) x"
apply (rule the_inv_into_f_eq)
  apply (fast intro: comp_inj_on)
 apply (simp add: f_the_inv_into_f the_inv_into_into)
apply (simp add: the_inv_into_into)
done

lemma inj_on_the_inv_into:
  "inj_on f A \<Longrightarrow> inj_on (the_inv_into A f) (f ` A)"
by (auto intro: inj_onI simp: the_inv_into_f_f)

lemma bij_betw_the_inv_into:
  "bij_betw f A B \<Longrightarrow> bij_betw (the_inv_into A f) B A"
by (auto simp add: bij_betw_def inj_on_the_inv_into the_inv_into_into)

abbreviation the_inv :: "('a \<Rightarrow> 'b) \<Rightarrow> ('b \<Rightarrow> 'a)" where
  "the_inv f \<equiv> the_inv_into UNIV f"

lemma the_inv_f_f:
  assumes "inj f"
  shows "the_inv f (f x) = x" using assms UNIV_I
  by (rule the_inv_into_f_f)


subsection {* Cantor's Paradox *}

lemma Cantors_paradox:
  "\<not>(\<exists>f. f ` A = Pow A)"
proof clarify
  fix f assume "f ` A = Pow A" hence *: "Pow A \<le> f ` A" by blast
  let ?X = "{a \<in> A. a \<notin> f a}"
  have "?X \<in> Pow A" unfolding Pow_def by auto
  with * obtain x where "x \<in> A \<and> f x = ?X" by blast
  thus False by best
qed

subsection {* Setup *} 

subsubsection {* Proof tools *}

text {* simplifies terms of the form
  f(...,x:=y,...,x:=z,...) to f(...,x:=z,...) *}

simproc_setup fun_upd2 ("f(v := w, x := y)") = {* fn _ =>
let
  fun gen_fun_upd NONE T _ _ = NONE
    | gen_fun_upd (SOME f) T x y = SOME (Const (@{const_name fun_upd}, T) $ f $ x $ y)
  fun dest_fun_T1 (Type (_, T :: Ts)) = T
  fun find_double (t as Const (@{const_name fun_upd},T) $ f $ x $ y) =
    let
      fun find (Const (@{const_name fun_upd},T) $ g $ v $ w) =
            if v aconv x then SOME g else gen_fun_upd (find g) T v w
        | find t = NONE
    in (dest_fun_T1 T, gen_fun_upd (find f) T x y) end

  val ss = simpset_of @{context}

  fun proc ctxt ct =
    let
      val t = Thm.term_of ct
    in
      case find_double t of
        (T, NONE) => NONE
      | (T, SOME rhs) =>
          SOME (Goal.prove ctxt [] [] (Logic.mk_equals (t, rhs))
            (fn _ =>
              rtac eq_reflection 1 THEN
              rtac @{thm ext} 1 THEN
              simp_tac (put_simpset ss ctxt) 1))
    end
in proc end
*}


subsubsection {* Functorial structure of types *}

ML_file "Tools/functor.ML"

functor map_fun: map_fun
  by (simp_all add: fun_eq_iff)

functor vimage
  by (simp_all add: fun_eq_iff vimage_comp)

text {* Legacy theorem names *}

lemmas o_def = comp_def
lemmas o_apply = comp_apply
lemmas o_assoc = comp_assoc [symmetric]
lemmas id_o = id_comp
lemmas o_id = comp_id
lemmas o_eq_dest = comp_eq_dest
lemmas o_eq_elim = comp_eq_elim
lemmas o_eq_dest_lhs = comp_eq_dest_lhs
lemmas o_eq_id_dest = comp_eq_id_dest

end

