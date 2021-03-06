(*  Title:      HOL/Metis.thy
    Author:     Lawrence C. Paulson, Cambridge University Computer Laboratory
    Author:     Jia Meng, Cambridge University Computer Laboratory and NICTA
    Author:     Jasmin Blanchette, TU Muenchen
*)

header {* Metis Proof Method *}

theory Metis
imports ATP
begin

declare [[ML_print_depth = 0]]
ML_file "~~/src/Tools/Metis/metis.ML"
declare [[ML_print_depth = 10]]


subsection {* Literal selection and lambda-lifting helpers *}

definition select :: "'a \<Rightarrow> 'a" where
"select = (\<lambda>x. x)"

lemma not_atomize: "(\<not> A \<Longrightarrow> False) \<equiv> Trueprop A"
by (cut_tac atomize_not [of "\<not> A"]) simp

lemma atomize_not_select: "(A \<Longrightarrow> select False) \<equiv> Trueprop (\<not> A)"
unfolding select_def by (rule atomize_not)

lemma not_atomize_select: "(\<not> A \<Longrightarrow> select False) \<equiv> Trueprop A"
unfolding select_def by (rule not_atomize)

lemma select_FalseI: "False \<Longrightarrow> select False" by simp

definition lambda :: "'a \<Rightarrow> 'a" where
"lambda = (\<lambda>x. x)"

lemma eq_lambdaI: "x \<equiv> y \<Longrightarrow> x \<equiv> lambda y"
unfolding lambda_def by assumption


subsection {* Metis package *}

ML_file "Tools/Metis/metis_generate.ML"
ML_file "Tools/Metis/metis_reconstruct.ML"
ML_file "Tools/Metis/metis_tactic.ML"

setup {* Metis_Tactic.setup *}

hide_const (open) select fFalse fTrue fNot fComp fconj fdisj fimplies fAll fEx fequal lambda
hide_fact (open) select_def not_atomize atomize_not_select not_atomize_select select_FalseI
  fFalse_def fTrue_def fNot_def fconj_def fdisj_def fimplies_def fAll_def fEx_def fequal_def
  fTrue_ne_fFalse fNot_table fconj_table fdisj_table fimplies_table fAll_table fEx_table
  fequal_table fAll_table fEx_table fNot_law fComp_law fconj_laws fdisj_laws fimplies_laws
  fequal_laws fAll_law fEx_law lambda_def eq_lambdaI

end
