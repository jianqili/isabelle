(*  Title:      HOL/Tools/BNF/bnf_fp_n2m_sugar.ML
    Author:     Jasmin Blanchette, TU Muenchen
    Copyright   2013

Suggared flattening of nested to mutual (co)recursion.
*)

signature BNF_FP_N2M_SUGAR =
sig
  val unfold_lets_splits: term -> term
  val dest_map: Proof.context -> string -> term -> term * term list

  val mutualize_fp_sugars: BNF_Util.fp_kind -> int list -> binding list -> typ list -> term list ->
    term list list list list -> BNF_FP_Util.fp_sugar list -> local_theory ->
    (BNF_FP_Util.fp_sugar list
     * (BNF_FP_Def_Sugar.lfp_sugar_thms option * BNF_FP_Def_Sugar.gfp_sugar_thms option))
    * local_theory
  val nested_to_mutual_fps: BNF_Util.fp_kind -> binding list -> typ list -> term list ->
    (term * term list list) list list -> local_theory ->
    (typ list * int list * BNF_FP_Util.fp_sugar list
     * (BNF_FP_Def_Sugar.lfp_sugar_thms option * BNF_FP_Def_Sugar.gfp_sugar_thms option))
    * local_theory
end;

structure BNF_FP_N2M_Sugar : BNF_FP_N2M_SUGAR =
struct

open Ctr_Sugar
open BNF_Util
open BNF_Def
open BNF_FP_Util
open BNF_FP_Def_Sugar
open BNF_FP_N2M

val n2mN = "n2m_"

type n2m_sugar = fp_sugar list * (lfp_sugar_thms option * gfp_sugar_thms option);

structure Data = Generic_Data
(
  type T = n2m_sugar Typtab.table;
  val empty = Typtab.empty;
  val extend = I;
  fun merge data : T = Typtab.merge (K true) data;
);

fun morph_n2m_sugar phi (fp_sugars, (lfp_sugar_thms_opt, gfp_sugar_thms_opt)) =
  (map (morph_fp_sugar phi) fp_sugars,
   (Option.map (morph_lfp_sugar_thms phi) lfp_sugar_thms_opt,
    Option.map (morph_gfp_sugar_thms phi) gfp_sugar_thms_opt));

val transfer_n2m_sugar =
  morph_n2m_sugar o Morphism.transfer_morphism o Proof_Context.theory_of;

fun n2m_sugar_of ctxt =
  Typtab.lookup (Data.get (Context.Proof ctxt))
  #> Option.map (transfer_n2m_sugar ctxt);

fun register_n2m_sugar key n2m_sugar =
  Local_Theory.declaration {syntax = false, pervasive = false}
    (fn phi => Data.map (Typtab.update (key, morph_n2m_sugar phi n2m_sugar)));

fun unfold_lets_splits (Const (@{const_name Let}, _) $ arg1 $ arg2) =
    unfold_lets_splits (betapply (arg2, arg1))
  | unfold_lets_splits (t as Const (@{const_name case_prod}, _) $ u) =
    (case unfold_lets_splits u of
      u' as Abs (s1, T1, Abs (s2, T2, _)) =>
      let val v = Var ((s1 ^ s2, Term.maxidx_of_term u' + 1), HOLogic.mk_prodT (T1, T2)) in
        lambda v (incr_boundvars 1 (betapplys (u', [HOLogic.mk_fst v, HOLogic.mk_snd v])))
      end
    | _ => t)
  | unfold_lets_splits (t $ u) = betapply (pairself unfold_lets_splits (t, u))
  | unfold_lets_splits (Abs (s, T, t)) = Abs (s, T, unfold_lets_splits t)
  | unfold_lets_splits t = t;

fun mk_map_pattern ctxt s =
  let
    val bnf = the (bnf_of ctxt s);
    val mapx = map_of_bnf bnf;
    val live = live_of_bnf bnf;
    val (f_Ts, _) = strip_typeN live (fastype_of mapx);
    val fs = map_index (fn (i, T) => Var (("?f", i), T)) f_Ts;
  in
    (mapx, betapplys (mapx, fs))
  end;

fun dest_map ctxt s call =
  let
    val (map0, pat) = mk_map_pattern ctxt s;
    val (_, tenv) = fo_match ctxt call pat;
  in
    (map0, Vartab.fold_rev (fn (_, (_, f)) => cons f) tenv [])
  end;

fun dest_abs_or_applied_map _ _ (Abs (_, _, t)) = (Term.dummy, [t])
  | dest_abs_or_applied_map ctxt s (t1 $ _) = dest_map ctxt s t1;

fun map_partition f xs =
  fold_rev (fn x => fn (ys, (good, bad)) =>
      case f x of SOME y => (y :: ys, (x :: good, bad)) | NONE => (ys, (good, x :: bad)))
    xs ([], ([], []));

fun key_of_fp_eqs fp fpTs fp_eqs =
  Type (case_fp fp "l" "g", fpTs @ maps (fn (x, T) => [TFree x, T]) fp_eqs);

fun get_indices callers t =
  callers
  |> map_index (fn (i, v) => if exists_subterm (equal v) t then SOME i else NONE)
  |> map_filter I;

(* TODO: test with sort constraints on As *)
fun mutualize_fp_sugars fp cliques bs fpTs callers callssss fp_sugars0 no_defs_lthy0 =
  let
    val thy = Proof_Context.theory_of no_defs_lthy0;

    val qsotm = quote o Syntax.string_of_term no_defs_lthy0;

    fun incompatible_calls ts =
      error ("Incompatible " ^ co_prefix fp ^ "recursive calls: " ^ commas (map qsotm ts));
    fun mutual_self_call caller t =
      error ("Unsupported mutual self-call " ^ qsotm t ^ " from " ^ qsotm caller);
    fun nested_self_call t =
      error ("Unsupported nested self-call " ^ qsotm t);

    val b_names = map Binding.name_of bs;
    val fp_b_names = map base_name_of_typ fpTs;

    val nn = length fpTs;
    val kks = 0 upto nn - 1;

    fun target_ctr_sugar_of_fp_sugar fpT ({T, ctr_sugar, ...} : fp_sugar) =
      let
        val rho = Vartab.fold (cons o apsnd snd) (Sign.typ_match thy (T, fpT) Vartab.empty) [];
        val phi = Morphism.term_morphism "BNF" (Term.subst_TVars rho);
      in
        morph_ctr_sugar phi ctr_sugar
      end;

    val ctr_defss = map #ctr_defs fp_sugars0;
    val mapss = map #maps fp_sugars0;
    val ctr_sugars = map2 target_ctr_sugar_of_fp_sugar fpTs fp_sugars0;

    val ctrss = map #ctrs ctr_sugars;
    val ctr_Tss = map (map fastype_of) ctrss;

    val As' = fold (fold Term.add_tfreesT) ctr_Tss [];
    val As = map TFree As';

    val ((Cs, Xs), no_defs_lthy) =
      no_defs_lthy0
      |> fold Variable.declare_typ As
      |> mk_TFrees nn
      ||>> variant_tfrees fp_b_names;

    fun check_call_dead live_call call =
      if null (get_indices callers call) then () else incompatible_calls [live_call, call];

    fun freeze_fpTs_type_based_default (T as Type (s, Ts)) =
        (case filter (curry (op =) T o snd) (map_index I fpTs) of
          [(kk, _)] => nth Xs kk
        | _ => Type (s, map freeze_fpTs_type_based_default Ts))
      | freeze_fpTs_type_based_default T = T;

    fun freeze_fpTs_mutual_call kk fpT calls T =
      (case fold (union (op =)) (map (get_indices callers) calls) [] of
        [] => if T = fpT then nth Xs kk else freeze_fpTs_type_based_default T
      | [kk'] =>
        if T = fpT andalso kk' <> kk then
          mutual_self_call (nth callers kk)
            (the (find_first (not o null o get_indices callers) calls))
        else
          nth Xs kk'
      | _ => incompatible_calls calls);

    fun freeze_fpTs_map kk (fpT as Type (_, Ts')) (callss, (live_call :: _, dead_calls))
        (Type (s, Ts)) =
      if Ts' = Ts then
        nested_self_call live_call
      else
        (List.app (check_call_dead live_call) dead_calls;
         Type (s, map2 (freeze_fpTs_call kk fpT)
           (flatten_type_args_of_bnf (the (bnf_of no_defs_lthy s)) [] (transpose callss)) Ts))
    and freeze_fpTs_call kk fpT calls (T as Type (s, _)) =
        (case map_partition (try (snd o dest_map no_defs_lthy s)) calls of
          ([], _) =>
          (case map_partition (try (snd o dest_abs_or_applied_map no_defs_lthy s)) calls of
            ([], _) => freeze_fpTs_mutual_call kk fpT calls T
          | callsp => freeze_fpTs_map kk fpT callsp T)
        | callsp => freeze_fpTs_map kk fpT callsp T)
      | freeze_fpTs_call _ _ _ T = T;

    val ctr_Tsss = map (map binder_types) ctr_Tss;
    val ctrXs_Tsss = map4 (map2 o map2 oo freeze_fpTs_call) kks fpTs callssss ctr_Tsss;
    val ctrXs_repTs = map mk_sumprodT_balanced ctrXs_Tsss;

    val ns = map length ctr_Tsss;
    val kss = map (fn n => 1 upto n) ns;
    val mss = map (map length) ctr_Tsss;

    val fp_eqs = map dest_TFree Xs ~~ ctrXs_repTs;
    val key = key_of_fp_eqs fp fpTs fp_eqs;
  in
    (case n2m_sugar_of no_defs_lthy key of
      SOME n2m_sugar => (n2m_sugar, no_defs_lthy)
    | NONE =>
      let
        val base_fp_names = Name.variant_list [] fp_b_names;
        val fp_bs = map2 (fn b_name => fn base_fp_name =>
            Binding.qualify true b_name (Binding.name (n2mN ^ base_fp_name)))
          b_names base_fp_names;

        val Type (s, Us) :: _ = fpTs;
        val killed_As' =
          (case bnf_of no_defs_lthy s of
            NONE => As'
          | SOME bnf =>
            let
              val Type (_, Ts) = T_of_bnf bnf;
              val deads = deads_of_bnf bnf;
              val dead_Us =
                map_filter (fn (T, U) => if member (op =) deads T then SOME U else NONE) (Ts ~~ Us);
            in fold Term.add_tfreesT dead_Us [] end);

        val fp_absT_infos = map #absT_info fp_sugars0;

        val ((pre_bnfs, absT_infos), (fp_res as {xtor_co_recs = xtor_co_recs0, xtor_co_induct,
               dtor_injects, dtor_ctors, xtor_co_rec_thms, ...}, lthy)) =
          fp_bnf (construct_mutualized_fp fp cliques fpTs fp_sugars0) fp_bs As' killed_As' fp_eqs
            no_defs_lthy0;

        val fp_abs_inverses = map #abs_inverse fp_absT_infos;
        val fp_type_definitions = map #type_definition fp_absT_infos;

        val abss = map #abs absT_infos;
        val reps = map #rep absT_infos;
        val absTs = map #absT absT_infos;
        val repTs = map #repT absT_infos;
        val abs_inverses = map #abs_inverse absT_infos;

        val fp_nesting_bnfs = nesting_bnfs lthy ctrXs_Tsss Xs;
        val live_nesting_bnfs = nesting_bnfs lthy ctrXs_Tsss As;

        val ((xtor_co_recs, recs_args_types, corecs_args_types), _) =
          mk_co_recs_prelims fp ctr_Tsss fpTs Cs absTs repTs ns mss xtor_co_recs0 lthy;

        fun mk_binding b suf = Binding.suffix_name ("_" ^ suf) b;

        val ((co_recs, co_rec_defs), lthy) =
          fold_map2 (fn b =>
              if fp = Least_FP then define_rec (the recs_args_types) (mk_binding b) fpTs Cs reps
              else define_corec (the corecs_args_types) (mk_binding b) fpTs Cs abss)
            fp_bs xtor_co_recs lthy
          |>> split_list;

        val ((common_co_inducts, co_inductss, co_rec_thmss, disc_corec_thmss, sel_corec_thmsss),
             fp_sugar_thms) =
          if fp = Least_FP then
            derive_induct_recs_thms_for_types pre_bnfs recs_args_types xtor_co_induct
              xtor_co_rec_thms live_nesting_bnfs fp_nesting_bnfs fpTs Cs Xs ctrXs_Tsss
              fp_abs_inverses fp_type_definitions abs_inverses ctrss ctr_defss co_recs co_rec_defs
              lthy
            |> `(fn ((inducts, induct, _), (rec_thmss, _)) =>
              ([induct], [inducts], rec_thmss, replicate nn [], replicate nn []))
            ||> (fn info => (SOME info, NONE))
          else
            derive_coinduct_corecs_thms_for_types pre_bnfs (the corecs_args_types) xtor_co_induct
              dtor_injects dtor_ctors xtor_co_rec_thms live_nesting_bnfs fpTs Cs Xs ctrXs_Tsss kss
              mss ns fp_abs_inverses abs_inverses (fn thm => thm RS @{thm vimage2p_refl}) ctr_defss
              ctr_sugars co_recs co_rec_defs (Proof_Context.export lthy no_defs_lthy) lthy
            |> `(fn ((coinduct_thms_pairs, _), corec_thmss, disc_corec_thmss, _,
                     (sel_corec_thmsss, _)) =>
              (map snd coinduct_thms_pairs, map fst coinduct_thms_pairs, corec_thmss,
               disc_corec_thmss, sel_corec_thmsss))
            ||> (fn info => (NONE, SOME info));

        val phi = Proof_Context.export_morphism no_defs_lthy no_defs_lthy0;

        fun mk_target_fp_sugar T X kk pre_bnf absT_info ctrXs_Tss ctr_defs ctr_sugar co_rec
            co_rec_def maps co_inducts co_rec_thms disc_corec_thms sel_corec_thmss
            ({rel_injects, rel_distincts, ...} : fp_sugar) =
          {T = T, BT = Term.dummyT (*wrong but harmless*), X = X, fp = fp, fp_res = fp_res,
           fp_res_index = kk, pre_bnf = pre_bnf, absT_info = absT_info,
           fp_nesting_bnfs = fp_nesting_bnfs, live_nesting_bnfs = live_nesting_bnfs,
           ctrXs_Tss = ctrXs_Tss, ctr_defs = ctr_defs, ctr_sugar = ctr_sugar, co_rec = co_rec,
           co_rec_def = co_rec_def, maps = maps, common_co_inducts = common_co_inducts,
           co_inducts = co_inducts, co_rec_thms = co_rec_thms, disc_co_recs = disc_corec_thms,
           sel_co_recss = sel_corec_thmss, rel_injects = rel_injects, rel_distincts = rel_distincts}
          |> morph_fp_sugar phi;

        val target_fp_sugars =
          map16 mk_target_fp_sugar fpTs Xs kks pre_bnfs absT_infos ctrXs_Tsss ctr_defss ctr_sugars
            co_recs co_rec_defs mapss (transpose co_inductss) co_rec_thmss disc_corec_thmss
            sel_corec_thmsss fp_sugars0;

        val n2m_sugar = (target_fp_sugars, fp_sugar_thms);
      in
        (n2m_sugar, lthy |> register_n2m_sugar key n2m_sugar)
      end)
  end;

fun indexify_callsss ctrs callsss =
  let
    fun indexify_ctr ctr =
      (case AList.lookup Term.aconv_untyped callsss ctr of
        NONE => replicate (num_binder_types (fastype_of ctr)) []
      | SOME callss => map (map (Envir.beta_eta_contract o unfold_lets_splits)) callss);
  in
    map indexify_ctr ctrs
  end;

fun retypargs tyargs (Type (s, _)) = Type (s, tyargs);

fun fold_subtype_pairs f (T as Type (s, Ts), U as Type (s', Us)) =
    f (T, U) #> (if s = s' then fold (fold_subtype_pairs f) (Ts ~~ Us) else I)
  | fold_subtype_pairs f TU = f TU;

val impossible_caller = Bound ~1;

fun nested_to_mutual_fps fp actual_bs actual_Ts actual_callers actual_callssss0 lthy =
  let
    val qsoty = quote o Syntax.string_of_typ lthy;
    val qsotys = space_implode " or " o map qsoty;

    fun not_co_datatype0 T = error (qsoty T ^ " is not a " ^ co_prefix fp ^ "datatype");
    fun not_co_datatype (T as Type (s, _)) =
        if fp = Least_FP andalso
           is_some (Datatype_Data.get_info (Proof_Context.theory_of lthy) s) then
          error (qsoty T ^ " is not a new-style datatype (cf. \"datatype_new\")")
        else
          not_co_datatype0 T
      | not_co_datatype T = not_co_datatype0 T;
    fun not_mutually_nested_rec Ts1 Ts2 =
      error (qsotys Ts1 ^ " is neither mutually recursive with " ^ qsotys Ts2 ^
        " nor nested recursive through " ^
        (if Ts1 = Ts2 andalso can the_single Ts1 then "itself" else qsotys Ts2));

    val sorted_actual_Ts =
      sort (prod_ord int_ord Term_Ord.typ_ord o pairself (`Term.size_of_typ)) actual_Ts;

    fun the_ctrs_of (Type (s, Ts)) = map (mk_ctr Ts) (#ctrs (the (ctr_sugar_of lthy s)));

    fun the_fp_sugar_of (T as Type (T_name, _)) =
      (case fp_sugar_of lthy T_name of
        SOME (fp_sugar as {fp = fp', ...}) => if fp = fp' then fp_sugar else not_co_datatype T
      | NONE => not_co_datatype T);

    fun gen_rhss_in gen_Ts rho subTs =
      let
        fun maybe_insert (T, Type (_, gen_tyargs)) =
            if member (op =) subTs T then insert (op =) gen_tyargs else I
          | maybe_insert _ = I;

        val ctrs = maps the_ctrs_of gen_Ts;
        val gen_ctr_Ts = maps (binder_types o fastype_of) ctrs;
        val ctr_Ts = map (Term.typ_subst_atomic rho) gen_ctr_Ts;
      in
        fold (fold_subtype_pairs maybe_insert) (ctr_Ts ~~ gen_ctr_Ts) []
      end;

    fun gather_types _ _ rev_seens gen_seen [] = (rev rev_seens, gen_seen)
      | gather_types lthy rho rev_seens gen_seen ((T as Type (_, tyargs)) :: Ts) =
        let
          val {fp_res = {Ts = mutual_Ts0, ...}, ...} = the_fp_sugar_of T;
          val mutual_Ts = map (retypargs tyargs) mutual_Ts0;

          val rev_seen = flat rev_seens;
          val _ = null rev_seens orelse exists (exists_strict_subtype_in rev_seen) mutual_Ts orelse
            not_mutually_nested_rec mutual_Ts rev_seen;

          fun fresh_tyargs () =
            let
              (* The name "'zy" is unlikely to clash with the context, yielding more cache hits. *)
              val (gen_tyargs, lthy') =
                variant_tfrees (replicate (length tyargs) "zy") lthy
                |>> map Logic.varifyT_global;
              val rho' = (gen_tyargs ~~ tyargs) @ rho;
            in
              (rho', gen_tyargs, gen_seen, lthy')
            end;

          val (rho', gen_tyargs, gen_seen', lthy') =
            if exists (exists_subtype_in rev_seen) mutual_Ts then
              (case gen_rhss_in gen_seen rho mutual_Ts of
                [] => fresh_tyargs ()
              | gen_tyargs :: gen_tyargss_tl =>
                let
                  val unify_pairs = split_list (maps (curry (op ~~) gen_tyargs) gen_tyargss_tl);
                  val mgu = Type.raw_unifys unify_pairs Vartab.empty;
                  val gen_tyargs' = map (Envir.subst_type mgu) gen_tyargs;
                  val gen_seen' = map (Envir.subst_type mgu) gen_seen;
                in
                  (rho, gen_tyargs', gen_seen', lthy)
                end)
            else
              fresh_tyargs ();

          val gen_mutual_Ts = map (retypargs gen_tyargs) mutual_Ts0;
          val other_mutual_Ts = remove1 (op =) T mutual_Ts;
          val Ts' = fold (remove1 (op =)) other_mutual_Ts Ts;
        in
          gather_types lthy' rho' (mutual_Ts :: rev_seens) (gen_seen' @ gen_mutual_Ts) Ts'
        end
      | gather_types _ _ _ _ (T :: _) = not_co_datatype T;

    val (perm_Tss, perm_gen_Ts) = gather_types lthy [] [] [] sorted_actual_Ts;
    val (perm_cliques, perm_Ts) =
      split_list (flat (map_index (fn (i, perm_Ts) => map (pair i) perm_Ts) perm_Tss));

    val perm_frozen_gen_Ts = map Logic.unvarifyT_global perm_gen_Ts;

    val missing_Ts = fold (remove1 (op =)) actual_Ts perm_Ts;
    val Ts = actual_Ts @ missing_Ts;

    val nn = length Ts;
    val kks = 0 upto nn - 1;

    val callssss0 = pad_list [] nn actual_callssss0;

    val common_name = mk_common_name (map Binding.name_of actual_bs);
    val bs = pad_list (Binding.name common_name) nn actual_bs;
    val callers = pad_list impossible_caller nn actual_callers;

    fun permute xs = permute_like (op =) Ts perm_Ts xs;
    fun unpermute perm_xs = permute_like (op =) perm_Ts Ts perm_xs;

    (* The assignment of callers to cliques is incorrect in general. This code would need to inspect
       the actual calls to discover the correct cliques in the presence of type duplicates. However,
       the naive scheme implemented here supports "prim(co)rec" specifications following reasonable
       ordering of the duplicates (e.g., keeping the cliques together). *)
    val perm_bs = permute bs;
    val perm_callers = permute callers;
    val perm_kks = permute kks;
    val perm_callssss0 = permute callssss0;
    val perm_fp_sugars0 = map (the o fp_sugar_of lthy o fst o dest_Type) perm_Ts;

    val perm_callssss = map2 (indexify_callsss o #ctrs o #ctr_sugar) perm_fp_sugars0 perm_callssss0;

    val ((perm_fp_sugars, fp_sugar_thms), lthy) =
      if can the_single perm_Tss then
        ((perm_fp_sugars0, (NONE, NONE)), lthy)
      else
        mutualize_fp_sugars fp perm_cliques perm_bs perm_frozen_gen_Ts perm_callers perm_callssss
          perm_fp_sugars0 lthy;

    val fp_sugars = unpermute perm_fp_sugars;
  in
    ((missing_Ts, perm_kks, fp_sugars, fp_sugar_thms), lthy)
  end;

end;
