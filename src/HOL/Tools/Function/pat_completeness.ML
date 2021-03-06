(*  Title:      HOL/Tools/Function/pat_completeness.ML
    Author:     Alexander Krauss, TU Muenchen

Method "pat_completeness" to prove completeness of datatype patterns.
*)

signature PAT_COMPLETENESS =
sig
  val pat_completeness_tac: Proof.context -> int -> tactic
  val prove_completeness: Proof.context -> term list -> term -> term list list ->
    term list list -> thm
end

structure Pat_Completeness : PAT_COMPLETENESS =
struct

open Function_Lib
open Function_Common


fun mk_argvar i T = Free ("_av" ^ (string_of_int i), T)
fun mk_patvar i T = Free ("_pv" ^ (string_of_int i), T)

fun inst_free var inst = Thm.forall_elim inst o Thm.forall_intr var

fun inst_case_thm thy x P thm =
  let val [Pv, xv] = Term.add_vars (prop_of thm) []
  in
    thm |> cterm_instantiate (map (pairself (cterm_of thy))
      [(Var xv, x), (Var Pv, P)])
  end

fun invent_vars constr i =
  let
    val Ts = binder_types (fastype_of constr)
    val j = i + length Ts
    val is = i upto (j - 1)
    val avs = map2 mk_argvar is Ts
    val pvs = map2 mk_patvar is Ts
 in
   (avs, pvs, j)
 end

fun filter_pats thy cons pvars [] = []
  | filter_pats thy cons pvars (([], thm) :: pts) = raise Match
  | filter_pats thy cons pvars (((pat as Free _) :: pats, thm) :: pts) =
    let val inst = list_comb (cons, pvars)
    in (inst :: pats, inst_free (cterm_of thy pat) (cterm_of thy inst) thm)
       :: (filter_pats thy cons pvars pts)
    end
  | filter_pats thy cons pvars ((pat :: pats, thm) :: pts) =
    if fst (strip_comb pat) = cons
    then (pat :: pats, thm) :: (filter_pats thy cons pvars pts)
    else filter_pats thy cons pvars pts


fun transform_pat _ avars c_assum ([] , thm) = raise Match
  | transform_pat ctxt avars c_assum (pat :: pats, thm) =
  let
    val thy = Proof_Context.theory_of ctxt
    val (_, subps) = strip_comb pat
    val eqs = map (cterm_of thy o HOLogic.mk_Trueprop o HOLogic.mk_eq) (avars ~~ subps)
    val c_eq_pat = simplify (put_simpset HOL_basic_ss ctxt addsimps (map Thm.assume eqs)) c_assum
  in
    (subps @ pats,
     fold_rev Thm.implies_intr eqs (Thm.implies_elim thm c_eq_pat))
  end


exception COMPLETENESS

fun constr_case ctxt P idx (v :: vs) pats cons =
  let
    val thy = Proof_Context.theory_of ctxt
    val (avars, pvars, newidx) = invent_vars cons idx
    val c_hyp = cterm_of thy (HOLogic.mk_Trueprop (HOLogic.mk_eq (v, list_comb (cons, avars))))
    val c_assum = Thm.assume c_hyp
    val newpats = map (transform_pat ctxt avars c_assum) (filter_pats thy cons pvars pats)
  in
    o_alg ctxt P newidx (avars @ vs) newpats
    |> Thm.implies_intr c_hyp
    |> fold_rev (Thm.forall_intr o cterm_of thy) avars
  end
  | constr_case _ _ _ _ _ _ = raise Match
and o_alg _ P idx [] (([], Pthm) :: _)  = Pthm
  | o_alg _ P idx (v :: vs) [] = raise COMPLETENESS
  | o_alg ctxt P idx (v :: vs) pts =
  if forall (is_Free o hd o fst) pts (* Var case *)
  then o_alg ctxt P idx vs
         (map (fn (pv :: pats, thm) =>
           (pats, refl RS
            (inst_free (cterm_of (Proof_Context.theory_of ctxt) pv)
              (cterm_of (Proof_Context.theory_of ctxt) v) thm))) pts)
  else (* Cons case *)
    let
      val thy = Proof_Context.theory_of ctxt
      val T as Type (tname, _) = fastype_of v
      val SOME {exhaust=case_thm, ...} = Ctr_Sugar.ctr_sugar_of ctxt tname
      val constrs = inst_constrs_of ctxt T
      val c_cases = map (constr_case ctxt P idx (v :: vs) pts) constrs
    in
      inst_case_thm thy v P case_thm
      |> fold (curry op COMP) c_cases
    end
  | o_alg _ _ _ _ _ = raise Match

fun prove_completeness ctxt xs P qss patss =
  let
    val thy = Proof_Context.theory_of ctxt
    fun mk_assum qs pats =
      HOLogic.mk_Trueprop P
      |> fold_rev (curry Logic.mk_implies o HOLogic.mk_Trueprop o HOLogic.mk_eq) (xs ~~ pats)
      |> fold_rev Logic.all qs
      |> cterm_of thy

    val hyps = map2 mk_assum qss patss
    fun inst_hyps hyp qs = fold (Thm.forall_elim o cterm_of thy) qs (Thm.assume hyp)
    val assums = map2 inst_hyps hyps qss
    in
      o_alg ctxt P 2 xs (patss ~~ assums)
      |> fold_rev Thm.implies_intr hyps
    end

fun pat_completeness_tac ctxt = SUBGOAL (fn (subgoal, i) =>
  let
    val thy = Proof_Context.theory_of ctxt
    val (vs, subgf) = dest_all_all subgoal
    val (cases, _ $ thesis) = Logic.strip_horn subgf
      handle Bind => raise COMPLETENESS

    fun pat_of assum =
      let
        val (qs, imp) = dest_all_all assum
        val prems = Logic.strip_imp_prems imp
      in
        (qs, map (HOLogic.dest_eq o HOLogic.dest_Trueprop) prems)
      end

    val (qss, x_pats) = split_list (map pat_of cases)
    val xs = map fst (hd x_pats)
      handle List.Empty => raise COMPLETENESS

    val patss = map (map snd) x_pats
    val complete_thm = prove_completeness ctxt xs thesis qss patss
      |> fold_rev (Thm.forall_intr o cterm_of thy) vs
    in
      PRIMITIVE (fn st => Drule.compose (complete_thm, i, st))
  end
  handle COMPLETENESS => no_tac)

end
