(*  Title:      HOL/Orderings.thy
    Author:     Tobias Nipkow, Markus Wenzel, and Larry Paulson
*)

header {* Abstract orderings *}

theory Orderings
imports HOL
keywords "print_orders" :: diag
begin

ML_file "~~/src/Provers/order.ML"
ML_file "~~/src/Provers/quasi.ML"  (* FIXME unused? *)

subsection {* Abstract ordering *}

locale ordering =
  fixes less_eq :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infix "\<preceq>" 50)
   and less :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infix "\<prec>" 50)
  assumes strict_iff_order: "a \<prec> b \<longleftrightarrow> a \<preceq> b \<and> a \<noteq> b"
  assumes refl: "a \<preceq> a" -- {* not @{text iff}: makes problems due to multiple (dual) interpretations *}
    and antisym: "a \<preceq> b \<Longrightarrow> b \<preceq> a \<Longrightarrow> a = b"
    and trans: "a \<preceq> b \<Longrightarrow> b \<preceq> c \<Longrightarrow> a \<preceq> c"
begin

lemma strict_implies_order:
  "a \<prec> b \<Longrightarrow> a \<preceq> b"
  by (simp add: strict_iff_order)

lemma strict_implies_not_eq:
  "a \<prec> b \<Longrightarrow> a \<noteq> b"
  by (simp add: strict_iff_order)

lemma not_eq_order_implies_strict:
  "a \<noteq> b \<Longrightarrow> a \<preceq> b \<Longrightarrow> a \<prec> b"
  by (simp add: strict_iff_order)

lemma order_iff_strict:
  "a \<preceq> b \<longleftrightarrow> a \<prec> b \<or> a = b"
  by (auto simp add: strict_iff_order refl)

lemma irrefl: -- {* not @{text iff}: makes problems due to multiple (dual) interpretations *}
  "\<not> a \<prec> a"
  by (simp add: strict_iff_order)

lemma asym:
  "a \<prec> b \<Longrightarrow> b \<prec> a \<Longrightarrow> False"
  by (auto simp add: strict_iff_order intro: antisym)

lemma strict_trans1:
  "a \<preceq> b \<Longrightarrow> b \<prec> c \<Longrightarrow> a \<prec> c"
  by (auto simp add: strict_iff_order intro: trans antisym)

lemma strict_trans2:
  "a \<prec> b \<Longrightarrow> b \<preceq> c \<Longrightarrow> a \<prec> c"
  by (auto simp add: strict_iff_order intro: trans antisym)

lemma strict_trans:
  "a \<prec> b \<Longrightarrow> b \<prec> c \<Longrightarrow> a \<prec> c"
  by (auto intro: strict_trans1 strict_implies_order)

end

locale ordering_top = ordering +
  fixes top :: "'a"
  assumes extremum [simp]: "a \<preceq> top"
begin

lemma extremum_uniqueI:
  "top \<preceq> a \<Longrightarrow> a = top"
  by (rule antisym) auto

lemma extremum_unique:
  "top \<preceq> a \<longleftrightarrow> a = top"
  by (auto intro: antisym)

lemma extremum_strict [simp]:
  "\<not> (top \<prec> a)"
  using extremum [of a] by (auto simp add: order_iff_strict intro: asym irrefl)

lemma not_eq_extremum:
  "a \<noteq> top \<longleftrightarrow> a \<prec> top"
  by (auto simp add: order_iff_strict intro: not_eq_order_implies_strict extremum)

end  


subsection {* Syntactic orders *}

class ord =
  fixes less_eq :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
    and less :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
begin

notation
  less_eq  ("op <=") and
  less_eq  ("(_/ <= _)" [51, 51] 50) and
  less  ("op <") and
  less  ("(_/ < _)"  [51, 51] 50)
  
notation (xsymbols)
  less_eq  ("op \<le>") and
  less_eq  ("(_/ \<le> _)"  [51, 51] 50)

notation (HTML output)
  less_eq  ("op \<le>") and
  less_eq  ("(_/ \<le> _)"  [51, 51] 50)

abbreviation (input)
  greater_eq  (infix ">=" 50) where
  "x >= y \<equiv> y <= x"

notation (input)
  greater_eq  (infix "\<ge>" 50)

abbreviation (input)
  greater  (infix ">" 50) where
  "x > y \<equiv> y < x"

end


subsection {* Quasi orders *}

class preorder = ord +
  assumes less_le_not_le: "x < y \<longleftrightarrow> x \<le> y \<and> \<not> (y \<le> x)"
  and order_refl [iff]: "x \<le> x"
  and order_trans: "x \<le> y \<Longrightarrow> y \<le> z \<Longrightarrow> x \<le> z"
begin

text {* Reflexivity. *}

lemma eq_refl: "x = y \<Longrightarrow> x \<le> y"
    -- {* This form is useful with the classical reasoner. *}
by (erule ssubst) (rule order_refl)

lemma less_irrefl [iff]: "\<not> x < x"
by (simp add: less_le_not_le)

lemma less_imp_le: "x < y \<Longrightarrow> x \<le> y"
unfolding less_le_not_le by blast


text {* Asymmetry. *}

lemma less_not_sym: "x < y \<Longrightarrow> \<not> (y < x)"
by (simp add: less_le_not_le)

lemma less_asym: "x < y \<Longrightarrow> (\<not> P \<Longrightarrow> y < x) \<Longrightarrow> P"
by (drule less_not_sym, erule contrapos_np) simp


text {* Transitivity. *}

lemma less_trans: "x < y \<Longrightarrow> y < z \<Longrightarrow> x < z"
by (auto simp add: less_le_not_le intro: order_trans) 

lemma le_less_trans: "x \<le> y \<Longrightarrow> y < z \<Longrightarrow> x < z"
by (auto simp add: less_le_not_le intro: order_trans) 

lemma less_le_trans: "x < y \<Longrightarrow> y \<le> z \<Longrightarrow> x < z"
by (auto simp add: less_le_not_le intro: order_trans) 


text {* Useful for simplification, but too risky to include by default. *}

lemma less_imp_not_less: "x < y \<Longrightarrow> (\<not> y < x) \<longleftrightarrow> True"
by (blast elim: less_asym)

lemma less_imp_triv: "x < y \<Longrightarrow> (y < x \<longrightarrow> P) \<longleftrightarrow> True"
by (blast elim: less_asym)


text {* Transitivity rules for calculational reasoning *}

lemma less_asym': "a < b \<Longrightarrow> b < a \<Longrightarrow> P"
by (rule less_asym)


text {* Dual order *}

lemma dual_preorder:
  "class.preorder (op \<ge>) (op >)"
proof qed (auto simp add: less_le_not_le intro: order_trans)

end


subsection {* Partial orders *}

class order = preorder +
  assumes antisym: "x \<le> y \<Longrightarrow> y \<le> x \<Longrightarrow> x = y"
begin

lemma less_le: "x < y \<longleftrightarrow> x \<le> y \<and> x \<noteq> y"
  by (auto simp add: less_le_not_le intro: antisym)

sublocale order!: ordering less_eq less +  dual_order!: ordering greater_eq greater
  by default (auto intro: antisym order_trans simp add: less_le)


text {* Reflexivity. *}

lemma le_less: "x \<le> y \<longleftrightarrow> x < y \<or> x = y"
    -- {* NOT suitable for iff, since it can cause PROOF FAILED. *}
by (fact order.order_iff_strict)

lemma le_imp_less_or_eq: "x \<le> y \<Longrightarrow> x < y \<or> x = y"
unfolding less_le by blast


text {* Useful for simplification, but too risky to include by default. *}

lemma less_imp_not_eq: "x < y \<Longrightarrow> (x = y) \<longleftrightarrow> False"
by auto

lemma less_imp_not_eq2: "x < y \<Longrightarrow> (y = x) \<longleftrightarrow> False"
by auto


text {* Transitivity rules for calculational reasoning *}

lemma neq_le_trans: "a \<noteq> b \<Longrightarrow> a \<le> b \<Longrightarrow> a < b"
by (fact order.not_eq_order_implies_strict)

lemma le_neq_trans: "a \<le> b \<Longrightarrow> a \<noteq> b \<Longrightarrow> a < b"
by (rule order.not_eq_order_implies_strict)


text {* Asymmetry. *}

lemma eq_iff: "x = y \<longleftrightarrow> x \<le> y \<and> y \<le> x"
by (blast intro: antisym)

lemma antisym_conv: "y \<le> x \<Longrightarrow> x \<le> y \<longleftrightarrow> x = y"
by (blast intro: antisym)

lemma less_imp_neq: "x < y \<Longrightarrow> x \<noteq> y"
by (fact order.strict_implies_not_eq)


text {* Least value operator *}

definition (in ord)
  Least :: "('a \<Rightarrow> bool) \<Rightarrow> 'a" (binder "LEAST " 10) where
  "Least P = (THE x. P x \<and> (\<forall>y. P y \<longrightarrow> x \<le> y))"

lemma Least_equality:
  assumes "P x"
    and "\<And>y. P y \<Longrightarrow> x \<le> y"
  shows "Least P = x"
unfolding Least_def by (rule the_equality)
  (blast intro: assms antisym)+

lemma LeastI2_order:
  assumes "P x"
    and "\<And>y. P y \<Longrightarrow> x \<le> y"
    and "\<And>x. P x \<Longrightarrow> \<forall>y. P y \<longrightarrow> x \<le> y \<Longrightarrow> Q x"
  shows "Q (Least P)"
unfolding Least_def by (rule theI2)
  (blast intro: assms antisym)+


text {* Dual order *}

lemma dual_order:
  "class.order (op \<ge>) (op >)"
by (intro_locales, rule dual_preorder) (unfold_locales, rule antisym)

end


text {* Alternative introduction rule with bias towards strict order *}

lemma order_strictI:
  fixes less (infix "\<sqsubset>" 50)
    and less_eq (infix "\<sqsubseteq>" 50)
  assumes less_eq_less: "\<And>a b. a \<sqsubseteq> b \<longleftrightarrow> a \<sqsubset> b \<or> a = b"
    assumes asym: "\<And>a b. a \<sqsubset> b \<Longrightarrow> \<not> b \<sqsubset> a"
  assumes irrefl: "\<And>a. \<not> a \<sqsubset> a"
  assumes trans: "\<And>a b c. a \<sqsubset> b \<Longrightarrow> b \<sqsubset> c \<Longrightarrow> a \<sqsubset> c"
  shows "class.order less_eq less"
proof
  fix a b
  show "a \<sqsubset> b \<longleftrightarrow> a \<sqsubseteq> b \<and> \<not> b \<sqsubseteq> a"
    by (auto simp add: less_eq_less asym irrefl)
next
  fix a
  show "a \<sqsubseteq> a"
    by (auto simp add: less_eq_less)
next
  fix a b c
  assume "a \<sqsubseteq> b" and "b \<sqsubseteq> c" then show "a \<sqsubseteq> c"
    by (auto simp add: less_eq_less intro: trans)
next
  fix a b
  assume "a \<sqsubseteq> b" and "b \<sqsubseteq> a" then show "a = b"
    by (auto simp add: less_eq_less asym)
qed


subsection {* Linear (total) orders *}

class linorder = order +
  assumes linear: "x \<le> y \<or> y \<le> x"
begin

lemma less_linear: "x < y \<or> x = y \<or> y < x"
unfolding less_le using less_le linear by blast

lemma le_less_linear: "x \<le> y \<or> y < x"
by (simp add: le_less less_linear)

lemma le_cases [case_names le ge]:
  "(x \<le> y \<Longrightarrow> P) \<Longrightarrow> (y \<le> x \<Longrightarrow> P) \<Longrightarrow> P"
using linear by blast

lemma linorder_cases [case_names less equal greater]:
  "(x < y \<Longrightarrow> P) \<Longrightarrow> (x = y \<Longrightarrow> P) \<Longrightarrow> (y < x \<Longrightarrow> P) \<Longrightarrow> P"
using less_linear by blast

lemma linorder_wlog[case_names le sym]:
  "(\<And>a b. a \<le> b \<Longrightarrow> P a b) \<Longrightarrow> (\<And>a b. P b a \<Longrightarrow> P a b) \<Longrightarrow> P a b"
  by (cases rule: le_cases[of a b]) blast+

lemma not_less: "\<not> x < y \<longleftrightarrow> y \<le> x"
apply (simp add: less_le)
using linear apply (blast intro: antisym)
done

lemma not_less_iff_gr_or_eq:
 "\<not>(x < y) \<longleftrightarrow> (x > y | x = y)"
apply(simp add:not_less le_less)
apply blast
done

lemma not_le: "\<not> x \<le> y \<longleftrightarrow> y < x"
apply (simp add: less_le)
using linear apply (blast intro: antisym)
done

lemma neq_iff: "x \<noteq> y \<longleftrightarrow> x < y \<or> y < x"
by (cut_tac x = x and y = y in less_linear, auto)

lemma neqE: "x \<noteq> y \<Longrightarrow> (x < y \<Longrightarrow> R) \<Longrightarrow> (y < x \<Longrightarrow> R) \<Longrightarrow> R"
by (simp add: neq_iff) blast

lemma antisym_conv1: "\<not> x < y \<Longrightarrow> x \<le> y \<longleftrightarrow> x = y"
by (blast intro: antisym dest: not_less [THEN iffD1])

lemma antisym_conv2: "x \<le> y \<Longrightarrow> \<not> x < y \<longleftrightarrow> x = y"
by (blast intro: antisym dest: not_less [THEN iffD1])

lemma antisym_conv3: "\<not> y < x \<Longrightarrow> \<not> x < y \<longleftrightarrow> x = y"
by (blast intro: antisym dest: not_less [THEN iffD1])

lemma leI: "\<not> x < y \<Longrightarrow> y \<le> x"
unfolding not_less .

lemma leD: "y \<le> x \<Longrightarrow> \<not> x < y"
unfolding not_less .

(*FIXME inappropriate name (or delete altogether)*)
lemma not_leE: "\<not> y \<le> x \<Longrightarrow> x < y"
unfolding not_le .

text {* Dual order *}

lemma dual_linorder:
  "class.linorder (op \<ge>) (op >)"
by (rule class.linorder.intro, rule dual_order) (unfold_locales, rule linear)

end


text {* Alternative introduction rule with bias towards strict order *}

lemma linorder_strictI:
  fixes less (infix "\<sqsubset>" 50)
    and less_eq (infix "\<sqsubseteq>" 50)
  assumes "class.order less_eq less"
  assumes trichotomy: "\<And>a b. a \<sqsubset> b \<or> a = b \<or> b \<sqsubset> a"
  shows "class.linorder less_eq less"
proof -
  interpret order less_eq less
    by (fact `class.order less_eq less`)
  show ?thesis
  proof
    fix a b
    show "a \<sqsubseteq> b \<or> b \<sqsubseteq> a"
      using trichotomy by (auto simp add: le_less)
  qed
qed


subsection {* Reasoning tools setup *}

ML {*
signature ORDERS =
sig
  val print_structures: Proof.context -> unit
  val order_tac: Proof.context -> thm list -> int -> tactic
end;

structure Orders: ORDERS =
struct

(* context data *)

fun struct_eq ((s1: string, ts1), (s2, ts2)) =
  s1 = s2 andalso eq_list (op aconv) (ts1, ts2);

structure Data = Generic_Data
(
  type T = ((string * term list) * Order_Tac.less_arith) list;
    (* Order structures:
       identifier of the structure, list of operations and record of theorems
       needed to set up the transitivity reasoner,
       identifier and operations identify the structure uniquely. *)
  val empty = [];
  val extend = I;
  fun merge data = AList.join struct_eq (K fst) data;
);

fun print_structures ctxt =
  let
    val structs = Data.get (Context.Proof ctxt);
    fun pretty_term t = Pretty.block
      [Pretty.quote (Syntax.pretty_term ctxt t), Pretty.brk 1,
        Pretty.str "::", Pretty.brk 1,
        Pretty.quote (Syntax.pretty_typ ctxt (type_of t))];
    fun pretty_struct ((s, ts), _) = Pretty.block
      [Pretty.str s, Pretty.str ":", Pretty.brk 1,
       Pretty.enclose "(" ")" (Pretty.breaks (map pretty_term ts))];
  in
    Pretty.writeln (Pretty.big_list "order structures:" (map pretty_struct structs))
  end;

val _ =
  Outer_Syntax.improper_command @{command_spec "print_orders"}
    "print order structures available to transitivity reasoner"
    (Scan.succeed (Toplevel.unknown_context o
      Toplevel.keep (print_structures o Toplevel.context_of)));


(* tactics *)

fun struct_tac ((s, ops), thms) ctxt facts =
  let
    val [eq, le, less] = ops;
    fun decomp thy (@{const Trueprop} $ t) =
          let
            fun excluded t =
              (* exclude numeric types: linear arithmetic subsumes transitivity *)
              let val T = type_of t
              in
                T = HOLogic.natT orelse T = HOLogic.intT orelse T = HOLogic.realT
              end;
            fun rel (bin_op $ t1 $ t2) =
                  if excluded t1 then NONE
                  else if Pattern.matches thy (eq, bin_op) then SOME (t1, "=", t2)
                  else if Pattern.matches thy (le, bin_op) then SOME (t1, "<=", t2)
                  else if Pattern.matches thy (less, bin_op) then SOME (t1, "<", t2)
                  else NONE
              | rel _ = NONE;
            fun dec (Const (@{const_name Not}, _) $ t) =
                  (case rel t of NONE =>
                    NONE
                  | SOME (t1, rel, t2) => SOME (t1, "~" ^ rel, t2))
              | dec x = rel x;
          in dec t end
      | decomp _ _ = NONE;
  in
    (case s of
      "order" => Order_Tac.partial_tac decomp thms ctxt facts
    | "linorder" => Order_Tac.linear_tac decomp thms ctxt facts
    | _ => error ("Unknown order kind " ^ quote s ^ " encountered in transitivity reasoner"))
  end

fun order_tac ctxt facts =
  FIRST' (map (fn s => CHANGED o struct_tac s ctxt facts) (Data.get (Context.Proof ctxt)));


(* attributes *)

fun add_struct_thm s tag =
  Thm.declaration_attribute
    (fn thm => Data.map (AList.map_default struct_eq (s, Order_Tac.empty TrueI) (Order_Tac.update tag thm)));
fun del_struct s =
  Thm.declaration_attribute
    (fn _ => Data.map (AList.delete struct_eq s));

val _ =
  Theory.setup
    (Attrib.setup @{binding order}
      (Scan.lift ((Args.add -- Args.name >> (fn (_, s) => SOME s) || Args.del >> K NONE) --|
        Args.colon (* FIXME || Scan.succeed true *) ) -- Scan.lift Args.name --
        Scan.repeat Args.term
        >> (fn ((SOME tag, n), ts) => add_struct_thm (n, ts) tag
             | ((NONE, n), ts) => del_struct (n, ts)))
      "theorems controlling transitivity reasoner");

end;
*}

method_setup order = {*
  Scan.succeed (fn ctxt => SIMPLE_METHOD' (Orders.order_tac ctxt []))
*} "transitivity reasoner"


text {* Declarations to set up transitivity reasoner of partial and linear orders. *}

context order
begin

(* The type constraint on @{term op =} below is necessary since the operation
   is not a parameter of the locale. *)

declare less_irrefl [THEN notE, order add less_reflE: order "op = :: 'a \<Rightarrow> 'a \<Rightarrow> bool" "op <=" "op <"]
  
declare order_refl  [order add le_refl: order "op = :: 'a => 'a => bool" "op <=" "op <"]
  
declare less_imp_le [order add less_imp_le: order "op = :: 'a => 'a => bool" "op <=" "op <"]
  
declare antisym [order add eqI: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare eq_refl [order add eqD1: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare sym [THEN eq_refl, order add eqD2: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare less_trans [order add less_trans: order "op = :: 'a => 'a => bool" "op <=" "op <"]
  
declare less_le_trans [order add less_le_trans: order "op = :: 'a => 'a => bool" "op <=" "op <"]
  
declare le_less_trans [order add le_less_trans: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare order_trans [order add le_trans: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare le_neq_trans [order add le_neq_trans: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare neq_le_trans [order add neq_le_trans: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare less_imp_neq [order add less_imp_neq: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare eq_neq_eq_imp_neq [order add eq_neq_eq_imp_neq: order "op = :: 'a => 'a => bool" "op <=" "op <"]

declare not_sym [order add not_sym: order "op = :: 'a => 'a => bool" "op <=" "op <"]

end

context linorder
begin

declare [[order del: order "op = :: 'a => 'a => bool" "op <=" "op <"]]

declare less_irrefl [THEN notE, order add less_reflE: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare order_refl [order add le_refl: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare less_imp_le [order add less_imp_le: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare not_less [THEN iffD2, order add not_lessI: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare not_le [THEN iffD2, order add not_leI: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare not_less [THEN iffD1, order add not_lessD: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare not_le [THEN iffD1, order add not_leD: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare antisym [order add eqI: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare eq_refl [order add eqD1: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare sym [THEN eq_refl, order add eqD2: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare less_trans [order add less_trans: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare less_le_trans [order add less_le_trans: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare le_less_trans [order add le_less_trans: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare order_trans [order add le_trans: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare le_neq_trans [order add le_neq_trans: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare neq_le_trans [order add neq_le_trans: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare less_imp_neq [order add less_imp_neq: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare eq_neq_eq_imp_neq [order add eq_neq_eq_imp_neq: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

declare not_sym [order add not_sym: linorder "op = :: 'a => 'a => bool" "op <=" "op <"]

end

setup {*
  map_theory_simpset (fn ctxt0 => ctxt0 addSolver
    mk_solver "Transitivity" (fn ctxt => Orders.order_tac ctxt (Simplifier.prems_of ctxt)))
  (*Adding the transitivity reasoners also as safe solvers showed a slight
    speed up, but the reasoning strength appears to be not higher (at least
    no breaking of additional proofs in the entire HOL distribution, as
    of 5 March 2004, was observed).*)
*}

ML {*
local
  fun prp t thm = Thm.prop_of thm = t;  (* FIXME proper aconv!? *)
in

fun antisym_le_simproc ctxt ct =
  (case term_of ct of
    (le as Const (_, T)) $ r $ s =>
     (let
        val prems = Simplifier.prems_of ctxt;
        val less = Const (@{const_name less}, T);
        val t = HOLogic.mk_Trueprop(le $ s $ r);
      in
        (case find_first (prp t) prems of
          NONE =>
            let val t = HOLogic.mk_Trueprop(HOLogic.Not $ (less $ r $ s)) in
              (case find_first (prp t) prems of
                NONE => NONE
              | SOME thm => SOME(mk_meta_eq(thm RS @{thm linorder_class.antisym_conv1})))
             end
         | SOME thm => SOME (mk_meta_eq (thm RS @{thm order_class.antisym_conv})))
      end handle THM _ => NONE)
  | _ => NONE);

fun antisym_less_simproc ctxt ct =
  (case term_of ct of
    NotC $ ((less as Const(_,T)) $ r $ s) =>
     (let
       val prems = Simplifier.prems_of ctxt;
       val le = Const (@{const_name less_eq}, T);
       val t = HOLogic.mk_Trueprop(le $ r $ s);
      in
        (case find_first (prp t) prems of
          NONE =>
            let val t = HOLogic.mk_Trueprop (NotC $ (less $ s $ r)) in
              (case find_first (prp t) prems of
                NONE => NONE
              | SOME thm => SOME (mk_meta_eq(thm RS @{thm linorder_class.antisym_conv3})))
            end
        | SOME thm => SOME (mk_meta_eq (thm RS @{thm linorder_class.antisym_conv2})))
      end handle THM _ => NONE)
  | _ => NONE);

end;
*}

simproc_setup antisym_le ("(x::'a::order) \<le> y") = "K antisym_le_simproc"
simproc_setup antisym_less ("\<not> (x::'a::linorder) < y") = "K antisym_less_simproc"


subsection {* Bounded quantifiers *}

syntax
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3ALL _<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3EX _<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3ALL _<=_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3EX _<=_./ _)" [0, 0, 10] 10)

  "_All_greater" :: "[idt, 'a, bool] => bool"    ("(3ALL _>_./ _)"  [0, 0, 10] 10)
  "_Ex_greater" :: "[idt, 'a, bool] => bool"    ("(3EX _>_./ _)"  [0, 0, 10] 10)
  "_All_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3ALL _>=_./ _)" [0, 0, 10] 10)
  "_Ex_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3EX _>=_./ _)" [0, 0, 10] 10)

syntax (xsymbols)
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<le>_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<le>_./ _)" [0, 0, 10] 10)

  "_All_greater" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_>_./ _)"  [0, 0, 10] 10)
  "_Ex_greater" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_>_./ _)"  [0, 0, 10] 10)
  "_All_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<ge>_./ _)" [0, 0, 10] 10)
  "_Ex_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<ge>_./ _)" [0, 0, 10] 10)

syntax (HOL)
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3! _<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3? _<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3! _<=_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3? _<=_./ _)" [0, 0, 10] 10)

syntax (HTML output)
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<le>_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<le>_./ _)" [0, 0, 10] 10)

  "_All_greater" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_>_./ _)"  [0, 0, 10] 10)
  "_Ex_greater" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_>_./ _)"  [0, 0, 10] 10)
  "_All_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<ge>_./ _)" [0, 0, 10] 10)
  "_Ex_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<ge>_./ _)" [0, 0, 10] 10)

translations
  "ALL x<y. P"   =>  "ALL x. x < y \<longrightarrow> P"
  "EX x<y. P"    =>  "EX x. x < y \<and> P"
  "ALL x<=y. P"  =>  "ALL x. x <= y \<longrightarrow> P"
  "EX x<=y. P"   =>  "EX x. x <= y \<and> P"
  "ALL x>y. P"   =>  "ALL x. x > y \<longrightarrow> P"
  "EX x>y. P"    =>  "EX x. x > y \<and> P"
  "ALL x>=y. P"  =>  "ALL x. x >= y \<longrightarrow> P"
  "EX x>=y. P"   =>  "EX x. x >= y \<and> P"

print_translation {*
let
  val All_binder = Mixfix.binder_name @{const_syntax All};
  val Ex_binder = Mixfix.binder_name @{const_syntax Ex};
  val impl = @{const_syntax HOL.implies};
  val conj = @{const_syntax HOL.conj};
  val less = @{const_syntax less};
  val less_eq = @{const_syntax less_eq};

  val trans =
   [((All_binder, impl, less),
    (@{syntax_const "_All_less"}, @{syntax_const "_All_greater"})),
    ((All_binder, impl, less_eq),
    (@{syntax_const "_All_less_eq"}, @{syntax_const "_All_greater_eq"})),
    ((Ex_binder, conj, less),
    (@{syntax_const "_Ex_less"}, @{syntax_const "_Ex_greater"})),
    ((Ex_binder, conj, less_eq),
    (@{syntax_const "_Ex_less_eq"}, @{syntax_const "_Ex_greater_eq"}))];

  fun matches_bound v t =
    (case t of
      Const (@{syntax_const "_bound"}, _) $ Free (v', _) => v = v'
    | _ => false);
  fun contains_var v = Term.exists_subterm (fn Free (x, _) => x = v | _ => false);
  fun mk x c n P = Syntax.const c $ Syntax_Trans.mark_bound_body x $ n $ P;

  fun tr' q = (q, fn _ =>
    (fn [Const (@{syntax_const "_bound"}, _) $ Free (v, T),
        Const (c, _) $ (Const (d, _) $ t $ u) $ P] =>
        (case AList.lookup (op =) trans (q, c, d) of
          NONE => raise Match
        | SOME (l, g) =>
            if matches_bound v t andalso not (contains_var v u) then mk (v, T) l u P
            else if matches_bound v u andalso not (contains_var v t) then mk (v, T) g t P
            else raise Match)
      | _ => raise Match));
in [tr' All_binder, tr' Ex_binder] end
*}


subsection {* Transitivity reasoning *}

context ord
begin

lemma ord_le_eq_trans: "a \<le> b \<Longrightarrow> b = c \<Longrightarrow> a \<le> c"
  by (rule subst)

lemma ord_eq_le_trans: "a = b \<Longrightarrow> b \<le> c \<Longrightarrow> a \<le> c"
  by (rule ssubst)

lemma ord_less_eq_trans: "a < b \<Longrightarrow> b = c \<Longrightarrow> a < c"
  by (rule subst)

lemma ord_eq_less_trans: "a = b \<Longrightarrow> b < c \<Longrightarrow> a < c"
  by (rule ssubst)

end

lemma order_less_subst2: "(a::'a::order) < b ==> f b < (c::'c::order) ==>
  (!!x y. x < y ==> f x < f y) ==> f a < c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < b" hence "f a < f b" by (rule r)
  also assume "f b < c"
  finally (less_trans) show ?thesis .
qed

lemma order_less_subst1: "(a::'a::order) < f b ==> (b::'b::order) < c ==>
  (!!x y. x < y ==> f x < f y) ==> a < f c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < f b"
  also assume "b < c" hence "f b < f c" by (rule r)
  finally (less_trans) show ?thesis .
qed

lemma order_le_less_subst2: "(a::'a::order) <= b ==> f b < (c::'c::order) ==>
  (!!x y. x <= y ==> f x <= f y) ==> f a < c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= b" hence "f a <= f b" by (rule r)
  also assume "f b < c"
  finally (le_less_trans) show ?thesis .
qed

lemma order_le_less_subst1: "(a::'a::order) <= f b ==> (b::'b::order) < c ==>
  (!!x y. x < y ==> f x < f y) ==> a < f c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a <= f b"
  also assume "b < c" hence "f b < f c" by (rule r)
  finally (le_less_trans) show ?thesis .
qed

lemma order_less_le_subst2: "(a::'a::order) < b ==> f b <= (c::'c::order) ==>
  (!!x y. x < y ==> f x < f y) ==> f a < c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < b" hence "f a < f b" by (rule r)
  also assume "f b <= c"
  finally (less_le_trans) show ?thesis .
qed

lemma order_less_le_subst1: "(a::'a::order) < f b ==> (b::'b::order) <= c ==>
  (!!x y. x <= y ==> f x <= f y) ==> a < f c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a < f b"
  also assume "b <= c" hence "f b <= f c" by (rule r)
  finally (less_le_trans) show ?thesis .
qed

lemma order_subst1: "(a::'a::order) <= f b ==> (b::'b::order) <= c ==>
  (!!x y. x <= y ==> f x <= f y) ==> a <= f c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= f b"
  also assume "b <= c" hence "f b <= f c" by (rule r)
  finally (order_trans) show ?thesis .
qed

lemma order_subst2: "(a::'a::order) <= b ==> f b <= (c::'c::order) ==>
  (!!x y. x <= y ==> f x <= f y) ==> f a <= c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= b" hence "f a <= f b" by (rule r)
  also assume "f b <= c"
  finally (order_trans) show ?thesis .
qed

lemma ord_le_eq_subst: "a <= b ==> f b = c ==>
  (!!x y. x <= y ==> f x <= f y) ==> f a <= c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= b" hence "f a <= f b" by (rule r)
  also assume "f b = c"
  finally (ord_le_eq_trans) show ?thesis .
qed

lemma ord_eq_le_subst: "a = f b ==> b <= c ==>
  (!!x y. x <= y ==> f x <= f y) ==> a <= f c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a = f b"
  also assume "b <= c" hence "f b <= f c" by (rule r)
  finally (ord_eq_le_trans) show ?thesis .
qed

lemma ord_less_eq_subst: "a < b ==> f b = c ==>
  (!!x y. x < y ==> f x < f y) ==> f a < c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < b" hence "f a < f b" by (rule r)
  also assume "f b = c"
  finally (ord_less_eq_trans) show ?thesis .
qed

lemma ord_eq_less_subst: "a = f b ==> b < c ==>
  (!!x y. x < y ==> f x < f y) ==> a < f c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a = f b"
  also assume "b < c" hence "f b < f c" by (rule r)
  finally (ord_eq_less_trans) show ?thesis .
qed

text {*
  Note that this list of rules is in reverse order of priorities.
*}

lemmas [trans] =
  order_less_subst2
  order_less_subst1
  order_le_less_subst2
  order_le_less_subst1
  order_less_le_subst2
  order_less_le_subst1
  order_subst2
  order_subst1
  ord_le_eq_subst
  ord_eq_le_subst
  ord_less_eq_subst
  ord_eq_less_subst
  forw_subst
  back_subst
  rev_mp
  mp

lemmas (in order) [trans] =
  neq_le_trans
  le_neq_trans

lemmas (in preorder) [trans] =
  less_trans
  less_asym'
  le_less_trans
  less_le_trans
  order_trans

lemmas (in order) [trans] =
  antisym

lemmas (in ord) [trans] =
  ord_le_eq_trans
  ord_eq_le_trans
  ord_less_eq_trans
  ord_eq_less_trans

lemmas [trans] =
  trans

lemmas order_trans_rules =
  order_less_subst2
  order_less_subst1
  order_le_less_subst2
  order_le_less_subst1
  order_less_le_subst2
  order_less_le_subst1
  order_subst2
  order_subst1
  ord_le_eq_subst
  ord_eq_le_subst
  ord_less_eq_subst
  ord_eq_less_subst
  forw_subst
  back_subst
  rev_mp
  mp
  neq_le_trans
  le_neq_trans
  less_trans
  less_asym'
  le_less_trans
  less_le_trans
  order_trans
  antisym
  ord_le_eq_trans
  ord_eq_le_trans
  ord_less_eq_trans
  ord_eq_less_trans
  trans

text {* These support proving chains of decreasing inequalities
    a >= b >= c ... in Isar proofs. *}

lemma xt1 [no_atp]:
  "a = b ==> b > c ==> a > c"
  "a > b ==> b = c ==> a > c"
  "a = b ==> b >= c ==> a >= c"
  "a >= b ==> b = c ==> a >= c"
  "(x::'a::order) >= y ==> y >= x ==> x = y"
  "(x::'a::order) >= y ==> y >= z ==> x >= z"
  "(x::'a::order) > y ==> y >= z ==> x > z"
  "(x::'a::order) >= y ==> y > z ==> x > z"
  "(a::'a::order) > b ==> b > a ==> P"
  "(x::'a::order) > y ==> y > z ==> x > z"
  "(a::'a::order) >= b ==> a ~= b ==> a > b"
  "(a::'a::order) ~= b ==> a >= b ==> a > b"
  "a = f b ==> b > c ==> (!!x y. x > y ==> f x > f y) ==> a > f c" 
  "a > b ==> f b = c ==> (!!x y. x > y ==> f x > f y) ==> f a > c"
  "a = f b ==> b >= c ==> (!!x y. x >= y ==> f x >= f y) ==> a >= f c"
  "a >= b ==> f b = c ==> (!! x y. x >= y ==> f x >= f y) ==> f a >= c"
  by auto

lemma xt2 [no_atp]:
  "(a::'a::order) >= f b ==> b >= c ==> (!!x y. x >= y ==> f x >= f y) ==> a >= f c"
by (subgoal_tac "f b >= f c", force, force)

lemma xt3 [no_atp]: "(a::'a::order) >= b ==> (f b::'b::order) >= c ==>
    (!!x y. x >= y ==> f x >= f y) ==> f a >= c"
by (subgoal_tac "f a >= f b", force, force)

lemma xt4 [no_atp]: "(a::'a::order) > f b ==> (b::'b::order) >= c ==>
  (!!x y. x >= y ==> f x >= f y) ==> a > f c"
by (subgoal_tac "f b >= f c", force, force)

lemma xt5 [no_atp]: "(a::'a::order) > b ==> (f b::'b::order) >= c==>
    (!!x y. x > y ==> f x > f y) ==> f a > c"
by (subgoal_tac "f a > f b", force, force)

lemma xt6 [no_atp]: "(a::'a::order) >= f b ==> b > c ==>
    (!!x y. x > y ==> f x > f y) ==> a > f c"
by (subgoal_tac "f b > f c", force, force)

lemma xt7 [no_atp]: "(a::'a::order) >= b ==> (f b::'b::order) > c ==>
    (!!x y. x >= y ==> f x >= f y) ==> f a > c"
by (subgoal_tac "f a >= f b", force, force)

lemma xt8 [no_atp]: "(a::'a::order) > f b ==> (b::'b::order) > c ==>
    (!!x y. x > y ==> f x > f y) ==> a > f c"
by (subgoal_tac "f b > f c", force, force)

lemma xt9 [no_atp]: "(a::'a::order) > b ==> (f b::'b::order) > c ==>
    (!!x y. x > y ==> f x > f y) ==> f a > c"
by (subgoal_tac "f a > f b", force, force)

lemmas xtrans = xt1 xt2 xt3 xt4 xt5 xt6 xt7 xt8 xt9

(* 
  Since "a >= b" abbreviates "b <= a", the abbreviation "..." stands
  for the wrong thing in an Isar proof.

  The extra transitivity rules can be used as follows: 

lemma "(a::'a::order) > z"
proof -
  have "a >= b" (is "_ >= ?rhs")
    sorry
  also have "?rhs >= c" (is "_ >= ?rhs")
    sorry
  also (xtrans) have "?rhs = d" (is "_ = ?rhs")
    sorry
  also (xtrans) have "?rhs >= e" (is "_ >= ?rhs")
    sorry
  also (xtrans) have "?rhs > f" (is "_ > ?rhs")
    sorry
  also (xtrans) have "?rhs > z"
    sorry
  finally (xtrans) show ?thesis .
qed

  Alternatively, one can use "declare xtrans [trans]" and then
  leave out the "(xtrans)" above.
*)


subsection {* Monotonicity *}

context order
begin

definition mono :: "('a \<Rightarrow> 'b\<Colon>order) \<Rightarrow> bool" where
  "mono f \<longleftrightarrow> (\<forall>x y. x \<le> y \<longrightarrow> f x \<le> f y)"

lemma monoI [intro?]:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  shows "(\<And>x y. x \<le> y \<Longrightarrow> f x \<le> f y) \<Longrightarrow> mono f"
  unfolding mono_def by iprover

lemma monoD [dest?]:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  shows "mono f \<Longrightarrow> x \<le> y \<Longrightarrow> f x \<le> f y"
  unfolding mono_def by iprover

lemma monoE:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  assumes "mono f"
  assumes "x \<le> y"
  obtains "f x \<le> f y"
proof
  from assms show "f x \<le> f y" by (simp add: mono_def)
qed

definition antimono :: "('a \<Rightarrow> 'b\<Colon>order) \<Rightarrow> bool" where
  "antimono f \<longleftrightarrow> (\<forall>x y. x \<le> y \<longrightarrow> f x \<ge> f y)"

lemma antimonoI [intro?]:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  shows "(\<And>x y. x \<le> y \<Longrightarrow> f x \<ge> f y) \<Longrightarrow> antimono f"
  unfolding antimono_def by iprover

lemma antimonoD [dest?]:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  shows "antimono f \<Longrightarrow> x \<le> y \<Longrightarrow> f x \<ge> f y"
  unfolding antimono_def by iprover

lemma antimonoE:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  assumes "antimono f"
  assumes "x \<le> y"
  obtains "f x \<ge> f y"
proof
  from assms show "f x \<ge> f y" by (simp add: antimono_def)
qed

definition strict_mono :: "('a \<Rightarrow> 'b\<Colon>order) \<Rightarrow> bool" where
  "strict_mono f \<longleftrightarrow> (\<forall>x y. x < y \<longrightarrow> f x < f y)"

lemma strict_monoI [intro?]:
  assumes "\<And>x y. x < y \<Longrightarrow> f x < f y"
  shows "strict_mono f"
  using assms unfolding strict_mono_def by auto

lemma strict_monoD [dest?]:
  "strict_mono f \<Longrightarrow> x < y \<Longrightarrow> f x < f y"
  unfolding strict_mono_def by auto

lemma strict_mono_mono [dest?]:
  assumes "strict_mono f"
  shows "mono f"
proof (rule monoI)
  fix x y
  assume "x \<le> y"
  show "f x \<le> f y"
  proof (cases "x = y")
    case True then show ?thesis by simp
  next
    case False with `x \<le> y` have "x < y" by simp
    with assms strict_monoD have "f x < f y" by auto
    then show ?thesis by simp
  qed
qed

end

context linorder
begin

lemma mono_invE:
  fixes f :: "'a \<Rightarrow> 'b\<Colon>order"
  assumes "mono f"
  assumes "f x < f y"
  obtains "x \<le> y"
proof
  show "x \<le> y"
  proof (rule ccontr)
    assume "\<not> x \<le> y"
    then have "y \<le> x" by simp
    with `mono f` obtain "f y \<le> f x" by (rule monoE)
    with `f x < f y` show False by simp
  qed
qed

lemma strict_mono_eq:
  assumes "strict_mono f"
  shows "f x = f y \<longleftrightarrow> x = y"
proof
  assume "f x = f y"
  show "x = y" proof (cases x y rule: linorder_cases)
    case less with assms strict_monoD have "f x < f y" by auto
    with `f x = f y` show ?thesis by simp
  next
    case equal then show ?thesis .
  next
    case greater with assms strict_monoD have "f y < f x" by auto
    with `f x = f y` show ?thesis by simp
  qed
qed simp

lemma strict_mono_less_eq:
  assumes "strict_mono f"
  shows "f x \<le> f y \<longleftrightarrow> x \<le> y"
proof
  assume "x \<le> y"
  with assms strict_mono_mono monoD show "f x \<le> f y" by auto
next
  assume "f x \<le> f y"
  show "x \<le> y" proof (rule ccontr)
    assume "\<not> x \<le> y" then have "y < x" by simp
    with assms strict_monoD have "f y < f x" by auto
    with `f x \<le> f y` show False by simp
  qed
qed
  
lemma strict_mono_less:
  assumes "strict_mono f"
  shows "f x < f y \<longleftrightarrow> x < y"
  using assms
    by (auto simp add: less_le Orderings.less_le strict_mono_eq strict_mono_less_eq)

end


subsection {* min and max -- fundamental *}

definition (in ord) min :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" where
  "min a b = (if a \<le> b then a else b)"

definition (in ord) max :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" where
  "max a b = (if a \<le> b then b else a)"

lemma min_absorb1: "x \<le> y \<Longrightarrow> min x y = x"
  by (simp add: min_def)

lemma max_absorb2: "x \<le> y \<Longrightarrow> max x y = y"
  by (simp add: max_def)

lemma min_absorb2: "(y\<Colon>'a\<Colon>order) \<le> x \<Longrightarrow> min x y = y"
  by (simp add:min_def)

lemma max_absorb1: "(y\<Colon>'a\<Colon>order) \<le> x \<Longrightarrow> max x y = x"
  by (simp add: max_def)


subsection {* (Unique) top and bottom elements *}

class bot =
  fixes bot :: 'a ("\<bottom>")

class order_bot = order + bot +
  assumes bot_least: "\<bottom> \<le> a"
begin

sublocale bot!: ordering_top greater_eq greater bot
  by default (fact bot_least)

lemma le_bot:
  "a \<le> \<bottom> \<Longrightarrow> a = \<bottom>"
  by (fact bot.extremum_uniqueI)

lemma bot_unique:
  "a \<le> \<bottom> \<longleftrightarrow> a = \<bottom>"
  by (fact bot.extremum_unique)

lemma not_less_bot:
  "\<not> a < \<bottom>"
  by (fact bot.extremum_strict)

lemma bot_less:
  "a \<noteq> \<bottom> \<longleftrightarrow> \<bottom> < a"
  by (fact bot.not_eq_extremum)

end

class top =
  fixes top :: 'a ("\<top>")

class order_top = order + top +
  assumes top_greatest: "a \<le> \<top>"
begin

sublocale top!: ordering_top less_eq less top
  by default (fact top_greatest)

lemma top_le:
  "\<top> \<le> a \<Longrightarrow> a = \<top>"
  by (fact top.extremum_uniqueI)

lemma top_unique:
  "\<top> \<le> a \<longleftrightarrow> a = \<top>"
  by (fact top.extremum_unique)

lemma not_top_less:
  "\<not> \<top> < a"
  by (fact top.extremum_strict)

lemma less_top:
  "a \<noteq> \<top> \<longleftrightarrow> a < \<top>"
  by (fact top.not_eq_extremum)

end


subsection {* Dense orders *}

class dense_order = order +
  assumes dense: "x < y \<Longrightarrow> (\<exists>z. x < z \<and> z < y)"

class dense_linorder = linorder + dense_order
begin

lemma dense_le:
  fixes y z :: 'a
  assumes "\<And>x. x < y \<Longrightarrow> x \<le> z"
  shows "y \<le> z"
proof (rule ccontr)
  assume "\<not> ?thesis"
  hence "z < y" by simp
  from dense[OF this]
  obtain x where "x < y" and "z < x" by safe
  moreover have "x \<le> z" using assms[OF `x < y`] .
  ultimately show False by auto
qed

lemma dense_le_bounded:
  fixes x y z :: 'a
  assumes "x < y"
  assumes *: "\<And>w. \<lbrakk> x < w ; w < y \<rbrakk> \<Longrightarrow> w \<le> z"
  shows "y \<le> z"
proof (rule dense_le)
  fix w assume "w < y"
  from dense[OF `x < y`] obtain u where "x < u" "u < y" by safe
  from linear[of u w]
  show "w \<le> z"
  proof (rule disjE)
    assume "u \<le> w"
    from less_le_trans[OF `x < u` `u \<le> w`] `w < y`
    show "w \<le> z" by (rule *)
  next
    assume "w \<le> u"
    from `w \<le> u` *[OF `x < u` `u < y`]
    show "w \<le> z" by (rule order_trans)
  qed
qed

lemma dense_ge:
  fixes y z :: 'a
  assumes "\<And>x. z < x \<Longrightarrow> y \<le> x"
  shows "y \<le> z"
proof (rule ccontr)
  assume "\<not> ?thesis"
  hence "z < y" by simp
  from dense[OF this]
  obtain x where "x < y" and "z < x" by safe
  moreover have "y \<le> x" using assms[OF `z < x`] .
  ultimately show False by auto
qed

lemma dense_ge_bounded:
  fixes x y z :: 'a
  assumes "z < x"
  assumes *: "\<And>w. \<lbrakk> z < w ; w < x \<rbrakk> \<Longrightarrow> y \<le> w"
  shows "y \<le> z"
proof (rule dense_ge)
  fix w assume "z < w"
  from dense[OF `z < x`] obtain u where "z < u" "u < x" by safe
  from linear[of u w]
  show "y \<le> w"
  proof (rule disjE)
    assume "w \<le> u"
    from `z < w` le_less_trans[OF `w \<le> u` `u < x`]
    show "y \<le> w" by (rule *)
  next
    assume "u \<le> w"
    from *[OF `z < u` `u < x`] `u \<le> w`
    show "y \<le> w" by (rule order_trans)
  qed
qed

end

class no_top = order + 
  assumes gt_ex: "\<exists>y. x < y"

class no_bot = order + 
  assumes lt_ex: "\<exists>y. y < x"

class unbounded_dense_linorder = dense_linorder + no_top + no_bot


subsection {* Wellorders *}

class wellorder = linorder +
  assumes less_induct [case_names less]: "(\<And>x. (\<And>y. y < x \<Longrightarrow> P y) \<Longrightarrow> P x) \<Longrightarrow> P a"
begin

lemma wellorder_Least_lemma:
  fixes k :: 'a
  assumes "P k"
  shows LeastI: "P (LEAST x. P x)" and Least_le: "(LEAST x. P x) \<le> k"
proof -
  have "P (LEAST x. P x) \<and> (LEAST x. P x) \<le> k"
  using assms proof (induct k rule: less_induct)
    case (less x) then have "P x" by simp
    show ?case proof (rule classical)
      assume assm: "\<not> (P (LEAST a. P a) \<and> (LEAST a. P a) \<le> x)"
      have "\<And>y. P y \<Longrightarrow> x \<le> y"
      proof (rule classical)
        fix y
        assume "P y" and "\<not> x \<le> y"
        with less have "P (LEAST a. P a)" and "(LEAST a. P a) \<le> y"
          by (auto simp add: not_le)
        with assm have "x < (LEAST a. P a)" and "(LEAST a. P a) \<le> y"
          by auto
        then show "x \<le> y" by auto
      qed
      with `P x` have Least: "(LEAST a. P a) = x"
        by (rule Least_equality)
      with `P x` show ?thesis by simp
    qed
  qed
  then show "P (LEAST x. P x)" and "(LEAST x. P x) \<le> k" by auto
qed

-- "The following 3 lemmas are due to Brian Huffman"
lemma LeastI_ex: "\<exists>x. P x \<Longrightarrow> P (Least P)"
  by (erule exE) (erule LeastI)

lemma LeastI2:
  "P a \<Longrightarrow> (\<And>x. P x \<Longrightarrow> Q x) \<Longrightarrow> Q (Least P)"
  by (blast intro: LeastI)

lemma LeastI2_ex:
  "\<exists>a. P a \<Longrightarrow> (\<And>x. P x \<Longrightarrow> Q x) \<Longrightarrow> Q (Least P)"
  by (blast intro: LeastI_ex)

lemma LeastI2_wellorder:
  assumes "P a"
  and "\<And>a. \<lbrakk> P a; \<forall>b. P b \<longrightarrow> a \<le> b \<rbrakk> \<Longrightarrow> Q a"
  shows "Q (Least P)"
proof (rule LeastI2_order)
  show "P (Least P)" using `P a` by (rule LeastI)
next
  fix y assume "P y" thus "Least P \<le> y" by (rule Least_le)
next
  fix x assume "P x" "\<forall>y. P y \<longrightarrow> x \<le> y" thus "Q x" by (rule assms(2))
qed

lemma not_less_Least: "k < (LEAST x. P x) \<Longrightarrow> \<not> P k"
apply (simp (no_asm_use) add: not_le [symmetric])
apply (erule contrapos_nn)
apply (erule Least_le)
done

end


subsection {* Order on @{typ bool} *}

instantiation bool :: "{order_bot, order_top, linorder}"
begin

definition
  le_bool_def [simp]: "P \<le> Q \<longleftrightarrow> P \<longrightarrow> Q"

definition
  [simp]: "(P\<Colon>bool) < Q \<longleftrightarrow> \<not> P \<and> Q"

definition
  [simp]: "\<bottom> \<longleftrightarrow> False"

definition
  [simp]: "\<top> \<longleftrightarrow> True"

instance proof
qed auto

end

lemma le_boolI: "(P \<Longrightarrow> Q) \<Longrightarrow> P \<le> Q"
  by simp

lemma le_boolI': "P \<longrightarrow> Q \<Longrightarrow> P \<le> Q"
  by simp

lemma le_boolE: "P \<le> Q \<Longrightarrow> P \<Longrightarrow> (Q \<Longrightarrow> R) \<Longrightarrow> R"
  by simp

lemma le_boolD: "P \<le> Q \<Longrightarrow> P \<longrightarrow> Q"
  by simp

lemma bot_boolE: "\<bottom> \<Longrightarrow> P"
  by simp

lemma top_boolI: \<top>
  by simp

lemma [code]:
  "False \<le> b \<longleftrightarrow> True"
  "True \<le> b \<longleftrightarrow> b"
  "False < b \<longleftrightarrow> b"
  "True < b \<longleftrightarrow> False"
  by simp_all


subsection {* Order on @{typ "_ \<Rightarrow> _"} *}

instantiation "fun" :: (type, ord) ord
begin

definition
  le_fun_def: "f \<le> g \<longleftrightarrow> (\<forall>x. f x \<le> g x)"

definition
  "(f\<Colon>'a \<Rightarrow> 'b) < g \<longleftrightarrow> f \<le> g \<and> \<not> (g \<le> f)"

instance ..

end

instance "fun" :: (type, preorder) preorder proof
qed (auto simp add: le_fun_def less_fun_def
  intro: order_trans antisym)

instance "fun" :: (type, order) order proof
qed (auto simp add: le_fun_def intro: antisym)

instantiation "fun" :: (type, bot) bot
begin

definition
  "\<bottom> = (\<lambda>x. \<bottom>)"

instance ..

end

instantiation "fun" :: (type, order_bot) order_bot
begin

lemma bot_apply [simp, code]:
  "\<bottom> x = \<bottom>"
  by (simp add: bot_fun_def)

instance proof
qed (simp add: le_fun_def)

end

instantiation "fun" :: (type, top) top
begin

definition
  [no_atp]: "\<top> = (\<lambda>x. \<top>)"

instance ..

end

instantiation "fun" :: (type, order_top) order_top
begin

lemma top_apply [simp, code]:
  "\<top> x = \<top>"
  by (simp add: top_fun_def)

instance proof
qed (simp add: le_fun_def)

end

lemma le_funI: "(\<And>x. f x \<le> g x) \<Longrightarrow> f \<le> g"
  unfolding le_fun_def by simp

lemma le_funE: "f \<le> g \<Longrightarrow> (f x \<le> g x \<Longrightarrow> P) \<Longrightarrow> P"
  unfolding le_fun_def by simp

lemma le_funD: "f \<le> g \<Longrightarrow> f x \<le> g x"
  by (rule le_funE)


subsection {* Order on unary and binary predicates *}

lemma predicate1I:
  assumes PQ: "\<And>x. P x \<Longrightarrow> Q x"
  shows "P \<le> Q"
  apply (rule le_funI)
  apply (rule le_boolI)
  apply (rule PQ)
  apply assumption
  done

lemma predicate1D:
  "P \<le> Q \<Longrightarrow> P x \<Longrightarrow> Q x"
  apply (erule le_funE)
  apply (erule le_boolE)
  apply assumption+
  done

lemma rev_predicate1D:
  "P x \<Longrightarrow> P \<le> Q \<Longrightarrow> Q x"
  by (rule predicate1D)

lemma predicate2I:
  assumes PQ: "\<And>x y. P x y \<Longrightarrow> Q x y"
  shows "P \<le> Q"
  apply (rule le_funI)+
  apply (rule le_boolI)
  apply (rule PQ)
  apply assumption
  done

lemma predicate2D:
  "P \<le> Q \<Longrightarrow> P x y \<Longrightarrow> Q x y"
  apply (erule le_funE)+
  apply (erule le_boolE)
  apply assumption+
  done

lemma rev_predicate2D:
  "P x y \<Longrightarrow> P \<le> Q \<Longrightarrow> Q x y"
  by (rule predicate2D)

lemma bot1E [no_atp]: "\<bottom> x \<Longrightarrow> P"
  by (simp add: bot_fun_def)

lemma bot2E: "\<bottom> x y \<Longrightarrow> P"
  by (simp add: bot_fun_def)

lemma top1I: "\<top> x"
  by (simp add: top_fun_def)

lemma top2I: "\<top> x y"
  by (simp add: top_fun_def)


subsection {* Name duplicates *}

lemmas order_eq_refl = preorder_class.eq_refl
lemmas order_less_irrefl = preorder_class.less_irrefl
lemmas order_less_imp_le = preorder_class.less_imp_le
lemmas order_less_not_sym = preorder_class.less_not_sym
lemmas order_less_asym = preorder_class.less_asym
lemmas order_less_trans = preorder_class.less_trans
lemmas order_le_less_trans = preorder_class.le_less_trans
lemmas order_less_le_trans = preorder_class.less_le_trans
lemmas order_less_imp_not_less = preorder_class.less_imp_not_less
lemmas order_less_imp_triv = preorder_class.less_imp_triv
lemmas order_less_asym' = preorder_class.less_asym'

lemmas order_less_le = order_class.less_le
lemmas order_le_less = order_class.le_less
lemmas order_le_imp_less_or_eq = order_class.le_imp_less_or_eq
lemmas order_less_imp_not_eq = order_class.less_imp_not_eq
lemmas order_less_imp_not_eq2 = order_class.less_imp_not_eq2
lemmas order_neq_le_trans = order_class.neq_le_trans
lemmas order_le_neq_trans = order_class.le_neq_trans
lemmas order_antisym = order_class.antisym
lemmas order_eq_iff = order_class.eq_iff
lemmas order_antisym_conv = order_class.antisym_conv

lemmas linorder_linear = linorder_class.linear
lemmas linorder_less_linear = linorder_class.less_linear
lemmas linorder_le_less_linear = linorder_class.le_less_linear
lemmas linorder_le_cases = linorder_class.le_cases
lemmas linorder_not_less = linorder_class.not_less
lemmas linorder_not_le = linorder_class.not_le
lemmas linorder_neq_iff = linorder_class.neq_iff
lemmas linorder_neqE = linorder_class.neqE
lemmas linorder_antisym_conv1 = linorder_class.antisym_conv1
lemmas linorder_antisym_conv2 = linorder_class.antisym_conv2
lemmas linorder_antisym_conv3 = linorder_class.antisym_conv3

end

