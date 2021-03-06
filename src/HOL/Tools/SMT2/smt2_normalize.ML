(*  Title:      HOL/Tools/SMT2/smt2_normalize.ML
    Author:     Sascha Boehme, TU Muenchen

Normalization steps on theorems required by SMT solvers.
*)

signature SMT2_NORMALIZE =
sig
  val drop_fact_warning: Proof.context -> thm -> unit
  val atomize_conv: Proof.context -> conv

  val special_quant_table: (string * thm) list
  val case_bool_entry: string * thm
  val abs_min_max_table: (string * thm) list

  type extra_norm = Proof.context -> thm list * thm list -> thm list * thm list
  val add_extra_norm: SMT2_Util.class * extra_norm -> Context.generic -> Context.generic
  val normalize: Proof.context -> thm list -> (int * thm) list
end;

structure SMT2_Normalize: SMT2_NORMALIZE =
struct

fun drop_fact_warning ctxt =
  SMT2_Config.verbose_msg ctxt (prefix "Warning: dropping assumption: " o
    Display.string_of_thm ctxt)


(* general theorem normalizations *)

(** instantiate elimination rules **)

local
  val (cpfalse, cfalse) = `SMT2_Util.mk_cprop (Thm.cterm_of @{theory} @{const False})

  fun inst f ct thm =
    let val cv = f (Drule.strip_imp_concl (Thm.cprop_of thm))
    in Thm.instantiate ([], [(cv, ct)]) thm end
in

fun instantiate_elim thm =
  (case Thm.concl_of thm of
    @{const Trueprop} $ Var (_, @{typ bool}) => inst Thm.dest_arg cfalse thm
  | Var _ => inst I cpfalse thm
  | _ => thm)

end


(** normalize definitions **)

fun norm_def thm =
  (case Thm.prop_of thm of
    @{const Trueprop} $ (Const (@{const_name HOL.eq}, _) $ _ $ Abs _) =>
      norm_def (thm RS @{thm fun_cong})
  | Const (@{const_name Pure.eq}, _) $ _ $ Abs _ => norm_def (thm RS @{thm meta_eq_to_obj_eq})
  | _ => thm)


(** atomization **)

fun atomize_conv ctxt ct =
  (case Thm.term_of ct of
    @{const Pure.imp} $ _ $ _ =>
      Conv.binop_conv (atomize_conv ctxt) then_conv Conv.rewr_conv @{thm atomize_imp}
  | Const (@{const_name Pure.eq}, _) $ _ $ _ =>
      Conv.binop_conv (atomize_conv ctxt) then_conv Conv.rewr_conv @{thm atomize_eq}
  | Const (@{const_name Pure.all}, _) $ Abs _ =>
      Conv.binder_conv (atomize_conv o snd) ctxt then_conv Conv.rewr_conv @{thm atomize_all}
  | _ => Conv.all_conv) ct

val setup_atomize =
  fold SMT2_Builtin.add_builtin_fun_ext'' [@{const_name Pure.imp}, @{const_name Pure.eq},
    @{const_name Pure.all}, @{const_name Trueprop}]


(** unfold special quantifiers **)

val special_quant_table = [
  (@{const_name Ex1}, @{thm Ex1_def_raw}),
  (@{const_name Ball}, @{thm Ball_def_raw}),
  (@{const_name Bex}, @{thm Bex_def_raw})]

local
  fun special_quant (Const (n, _)) = AList.lookup (op =) special_quant_table n
    | special_quant _ = NONE

  fun special_quant_conv _ ct =
    (case special_quant (Thm.term_of ct) of
      SOME thm => Conv.rewr_conv thm
    | NONE => Conv.all_conv) ct
in

fun unfold_special_quants_conv ctxt =
  SMT2_Util.if_exists_conv (is_some o special_quant) (Conv.top_conv special_quant_conv ctxt)

val setup_unfolded_quants = fold (SMT2_Builtin.add_builtin_fun_ext'' o fst) special_quant_table

end


(** trigger inference **)

local
  (*** check trigger syntax ***)

  fun dest_trigger (Const (@{const_name pat}, _) $ _) = SOME true
    | dest_trigger (Const (@{const_name nopat}, _) $ _) = SOME false
    | dest_trigger _ = NONE

  fun eq_list [] = false
    | eq_list (b :: bs) = forall (equal b) bs

  fun proper_trigger t =
    t
    |> these o try SMT2_Util.dest_symb_list
    |> map (map_filter dest_trigger o these o try SMT2_Util.dest_symb_list)
    |> (fn [] => false | bss => forall eq_list bss)

  fun proper_quant inside f t =
    (case t of
      Const (@{const_name All}, _) $ Abs (_, _, u) => proper_quant true f u
    | Const (@{const_name Ex}, _) $ Abs (_, _, u) => proper_quant true f u
    | @{const trigger} $ p $ u =>
        (if inside then f p else false) andalso proper_quant false f u
    | Abs (_, _, u) => proper_quant false f u
    | u1 $ u2 => proper_quant false f u1 andalso proper_quant false f u2
    | _ => true)

  fun check_trigger_error ctxt t =
    error ("SMT triggers must only occur under quantifier and multipatterns " ^
      "must have the same kind: " ^ Syntax.string_of_term ctxt t)

  fun check_trigger_conv ctxt ct =
    if proper_quant false proper_trigger (SMT2_Util.term_of ct) then Conv.all_conv ct
    else check_trigger_error ctxt (Thm.term_of ct)


  (*** infer simple triggers ***)

  fun dest_cond_eq ct =
    (case Thm.term_of ct of
      Const (@{const_name HOL.eq}, _) $ _ $ _ => Thm.dest_binop ct
    | @{const HOL.implies} $ _ $ _ => dest_cond_eq (Thm.dest_arg ct)
    | _ => raise CTERM ("no equation", [ct]))

  fun get_constrs thy (Type (n, _)) = these (Datatype.get_constrs thy n)
    | get_constrs _ _ = []

  fun is_constr thy (n, T) =
    let fun match (m, U) = m = n andalso Sign.typ_instance thy (T, U)
    in can (the o find_first match o get_constrs thy o Term.body_type) T end

  fun is_constr_pat thy t =
    (case Term.strip_comb t of
      (Free _, []) => true
    | (Const c, ts) => is_constr thy c andalso forall (is_constr_pat thy) ts
    | _ => false)

  fun is_simp_lhs ctxt t =
    (case Term.strip_comb t of
      (Const c, ts as _ :: _) =>
        not (SMT2_Builtin.is_builtin_fun_ext ctxt c ts) andalso
        forall (is_constr_pat (Proof_Context.theory_of ctxt)) ts
    | _ => false)

  fun has_all_vars vs t =
    subset (op aconv) (vs, map Free (Term.add_frees t []))

  fun minimal_pats vs ct =
    if has_all_vars vs (Thm.term_of ct) then
      (case Thm.term_of ct of
        _ $ _ =>
          (case pairself (minimal_pats vs) (Thm.dest_comb ct) of
            ([], []) => [[ct]]
          | (ctss, ctss') => union (eq_set (op aconvc)) ctss ctss')
      | _ => [])
    else []

  fun proper_mpat _ _ _ [] = false
    | proper_mpat thy gen u cts =
        let
          val tps = (op ~~) (`gen (map Thm.term_of cts))
          fun some_match u = tps |> exists (fn (t', t) =>
            Pattern.matches thy (t', u) andalso not (t aconv u))
        in not (Term.exists_subterm some_match u) end

  val pat = SMT2_Util.mk_const_pat @{theory} @{const_name pat} SMT2_Util.destT1
  fun mk_pat ct = Thm.apply (SMT2_Util.instT' ct pat) ct

  fun mk_clist T =
    pairself (Thm.cterm_of @{theory}) (SMT2_Util.symb_cons_const T, SMT2_Util.symb_nil_const T)
  fun mk_list (ccons, cnil) f cts = fold_rev (Thm.mk_binop ccons o f) cts cnil
  val mk_pat_list = mk_list (mk_clist @{typ pattern})
  val mk_mpat_list = mk_list (mk_clist @{typ "pattern symb_list"})
  fun mk_trigger ctss = mk_mpat_list (mk_pat_list mk_pat) ctss

  val trigger_eq = mk_meta_eq @{lemma "p = trigger t p" by (simp add: trigger_def)}

  fun insert_trigger_conv [] ct = Conv.all_conv ct
    | insert_trigger_conv ctss ct =
        let val (ctr, cp) = Thm.dest_binop (Thm.rhs_of trigger_eq) ||> rpair ct
        in Thm.instantiate ([], [cp, (ctr, mk_trigger ctss)]) trigger_eq end

  fun infer_trigger_eq_conv outer_ctxt (ctxt, cvs) ct =
    let
      val (lhs, rhs) = dest_cond_eq ct

      val vs = map Thm.term_of cvs
      val thy = Proof_Context.theory_of ctxt

      fun get_mpats ct =
        if is_simp_lhs ctxt (Thm.term_of ct) then minimal_pats vs ct
        else []
      val gen = Variable.export_terms ctxt outer_ctxt
      val filter_mpats = filter (proper_mpat thy gen (Thm.term_of rhs))

    in insert_trigger_conv (filter_mpats (get_mpats lhs)) ct end

  fun has_trigger (@{const trigger} $ _ $ _) = true
    | has_trigger _ = false

  fun try_trigger_conv cv ct =
    if SMT2_Util.under_quant has_trigger (SMT2_Util.term_of ct) then Conv.all_conv ct
    else Conv.try_conv cv ct

  fun infer_trigger_conv ctxt =
    if Config.get ctxt SMT2_Config.infer_triggers then
      try_trigger_conv (SMT2_Util.under_quant_conv (infer_trigger_eq_conv ctxt) ctxt)
    else Conv.all_conv
in

fun trigger_conv ctxt =
  SMT2_Util.prop_conv (check_trigger_conv ctxt then_conv infer_trigger_conv ctxt)

val setup_trigger =
  fold SMT2_Builtin.add_builtin_fun_ext''
    [@{const_name pat}, @{const_name nopat}, @{const_name trigger}]

end


(** combined general normalizations **)

fun gen_normalize1_conv ctxt =
  atomize_conv ctxt then_conv
  unfold_special_quants_conv ctxt then_conv
  Thm.beta_conversion true then_conv
  trigger_conv ctxt

fun gen_normalize1 ctxt =
  instantiate_elim #>
  norm_def #>
  Conv.fconv_rule (Thm.beta_conversion true then_conv Thm.eta_conversion) #>
  Drule.forall_intr_vars #>
  Conv.fconv_rule (gen_normalize1_conv ctxt) #>
  (* Z3 4.3.1 silently normalizes "P --> Q --> R" to "P & Q --> R" *)
  Raw_Simplifier.rewrite_rule ctxt @{thms HOL.imp_conjL[symmetric, THEN eq_reflection]}

fun gen_norm1_safe ctxt (i, thm) =
  (case try (gen_normalize1 ctxt) thm of
    SOME thm' => SOME (i, thm')
  | NONE => (drop_fact_warning ctxt thm; NONE))

fun gen_normalize ctxt iwthms = map_filter (gen_norm1_safe ctxt) iwthms


(* unfolding of definitions and theory-specific rewritings *)

fun expand_head_conv cv ct =
  (case Thm.term_of ct of
    _ $ _ =>
      Conv.fun_conv (expand_head_conv cv) then_conv
      Conv.try_conv (Thm.beta_conversion false)
  | _ => cv) ct


(** rewrite bool case expressions as if expressions **)

val case_bool_entry = (@{const_name "bool.case_bool"}, @{thm case_bool_if})

local
  fun is_case_bool (Const (@{const_name "bool.case_bool"}, _)) = true
    | is_case_bool _ = false

  fun unfold_conv _ =
    SMT2_Util.if_true_conv (is_case_bool o Term.head_of)
      (expand_head_conv (Conv.rewr_conv @{thm case_bool_if}))
in

fun rewrite_case_bool_conv ctxt =
  SMT2_Util.if_exists_conv is_case_bool (Conv.top_conv unfold_conv ctxt)

val setup_case_bool = SMT2_Builtin.add_builtin_fun_ext'' @{const_name "bool.case_bool"}

end


(** unfold abs, min and max **)

val abs_min_max_table = [
  (@{const_name min}, @{thm min_def_raw}),
  (@{const_name max}, @{thm max_def_raw}),
  (@{const_name abs}, @{thm abs_if_raw})]

local
  fun abs_min_max ctxt (Const (n, Type (@{type_name fun}, [T, _]))) =
        (case AList.lookup (op =) abs_min_max_table n of
          NONE => NONE
        | SOME thm => if SMT2_Builtin.is_builtin_typ_ext ctxt T then SOME thm else NONE)
    | abs_min_max _ _ = NONE

  fun unfold_amm_conv ctxt ct =
    (case abs_min_max ctxt (Term.head_of (Thm.term_of ct)) of
      SOME thm => expand_head_conv (Conv.rewr_conv thm)
    | NONE => Conv.all_conv) ct
in

fun unfold_abs_min_max_conv ctxt =
  SMT2_Util.if_exists_conv (is_some o abs_min_max ctxt) (Conv.top_conv unfold_amm_conv ctxt)

val setup_abs_min_max = fold (SMT2_Builtin.add_builtin_fun_ext'' o fst) abs_min_max_table

end


(** normalize numerals **)

local
  (*
    rewrite Numeral1 into 1
    rewrite - 0 into 0
  *)

  fun is_irregular_number (Const (@{const_name numeral}, _) $ Const (@{const_name num.One}, _)) =
        true
    | is_irregular_number (Const (@{const_name uminus}, _) $ Const (@{const_name Groups.zero}, _)) =
        true
    | is_irregular_number _ = false

  fun is_strange_number ctxt t = is_irregular_number t andalso SMT2_Builtin.is_builtin_num ctxt t

  val proper_num_ss =
    simpset_of (put_simpset HOL_ss @{context} addsimps @{thms Num.numeral_One minus_zero})

  fun norm_num_conv ctxt =
    SMT2_Util.if_conv (is_strange_number ctxt) (Simplifier.rewrite (put_simpset proper_num_ss ctxt))
      Conv.no_conv
in

fun normalize_numerals_conv ctxt =
  SMT2_Util.if_exists_conv (is_strange_number ctxt) (Conv.top_sweep_conv norm_num_conv ctxt)

end


(** combined unfoldings and rewritings **)

fun unfold_conv ctxt =
  rewrite_case_bool_conv ctxt then_conv
  unfold_abs_min_max_conv ctxt then_conv
  Thm.beta_conversion true

fun unfold_polymorph ctxt = map (apsnd (Conv.fconv_rule (unfold_conv ctxt)))
fun unfold_monomorph ctxt = map (apsnd (Conv.fconv_rule (normalize_numerals_conv ctxt)))


(* overall normalization *)

fun burrow_ids f ithms =
  let
    val (is, thms) = split_list ithms
    val (thms', extra_thms) = f thms
  in (is ~~ thms') @ map (pair ~1) extra_thms end

type extra_norm = Proof.context -> thm list * thm list -> thm list * thm list

structure Extra_Norms = Generic_Data
(
  type T = extra_norm SMT2_Util.dict
  val empty = []
  val extend = I
  fun merge data = SMT2_Util.dict_merge fst data
)

fun add_extra_norm (cs, norm) = Extra_Norms.map (SMT2_Util.dict_update (cs, norm))

fun apply_extra_norms ctxt ithms =
  let
    val cs = SMT2_Config.solver_class_of ctxt
    val es = SMT2_Util.dict_lookup (Extra_Norms.get (Context.Proof ctxt)) cs
  in burrow_ids (fold (fn e => e ctxt) es o rpair []) ithms end

local
  val ignored = member (op =) [@{const_name All}, @{const_name Ex},
    @{const_name Let}, @{const_name If}, @{const_name HOL.eq}]

  val schematic_consts_of =
    let
      fun collect (@{const trigger} $ p $ t) = collect_trigger p #> collect t
        | collect (t $ u) = collect t #> collect u
        | collect (Abs (_, _, t)) = collect t
        | collect (t as Const (n, _)) =
            if not (ignored n) then Monomorph.add_schematic_consts_of t else I
        | collect _ = I
      and collect_trigger t =
        let val dest = these o try SMT2_Util.dest_symb_list
        in fold (fold collect_pat o dest) (dest t) end
      and collect_pat (Const (@{const_name pat}, _) $ t) = collect t
        | collect_pat (Const (@{const_name nopat}, _) $ t) = collect t
        | collect_pat _ = I
    in (fn t => collect t Symtab.empty) end
in

fun monomorph ctxt xthms =
  let val (xs, thms) = split_list xthms
  in
    map (pair 1) thms
    |> Monomorph.monomorph schematic_consts_of ctxt
    |> maps (uncurry (map o pair)) o map2 pair xs o map (map snd)
  end

end

fun normalize ctxt wthms =
  wthms
  |> map_index I
  |> gen_normalize ctxt
  |> unfold_polymorph ctxt
  |> monomorph ctxt
  |> unfold_monomorph ctxt
  |> apply_extra_norms ctxt

val _ = Theory.setup (Context.theory_map (
  setup_atomize #>
  setup_unfolded_quants #>
  setup_trigger #>
  setup_case_bool #>
  setup_abs_min_max))

end;
