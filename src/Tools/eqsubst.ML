(*  Title:      Tools/eqsubst.ML
    Author:     Lucas Dixon, University of Edinburgh

Perform a substitution using an equation.
*)

signature EQSUBST =
sig
  type match =
    ((indexname * (sort * typ)) list (* type instantiations *)
      * (indexname * (typ * term)) list) (* term instantiations *)
    * (string * typ) list (* fake named type abs env *)
    * (string * typ) list (* type abs env *)
    * term (* outer term *)

  type searchinfo =
    theory
    * int (* maxidx *)
    * Zipper.T (* focusterm to search under *)

  datatype 'a skipseq = SkipMore of int | SkipSeq of 'a Seq.seq Seq.seq

  val skip_first_asm_occs_search: ('a -> 'b -> 'c Seq.seq Seq.seq) -> 'a -> int -> 'b -> 'c skipseq
  val skip_first_occs_search: int -> ('a -> 'b -> 'c Seq.seq Seq.seq) -> 'a -> 'b -> 'c Seq.seq
  val skipto_skipseq: int -> 'a Seq.seq Seq.seq -> 'a skipseq

  (* tactics *)
  val eqsubst_asm_tac: Proof.context -> int list -> thm list -> int -> tactic
  val eqsubst_asm_tac': Proof.context ->
    (searchinfo -> int -> term -> match skipseq) -> int -> thm -> int -> tactic
  val eqsubst_tac: Proof.context ->
    int list -> (* list of occurences to rewrite, use [0] for any *)
    thm list -> int -> tactic
  val eqsubst_tac': Proof.context ->
    (searchinfo -> term -> match Seq.seq) (* search function *)
    -> thm (* equation theorem to rewrite with *)
    -> int (* subgoal number in goal theorem *)
    -> thm (* goal theorem *)
    -> thm Seq.seq (* rewritten goal theorem *)

  (* search for substitutions *)
  val valid_match_start: Zipper.T -> bool
  val search_lr_all: Zipper.T -> Zipper.T Seq.seq
  val search_lr_valid: (Zipper.T -> bool) -> Zipper.T -> Zipper.T Seq.seq
  val searchf_lr_unify_all: searchinfo -> term -> match Seq.seq Seq.seq
  val searchf_lr_unify_valid: searchinfo -> term -> match Seq.seq Seq.seq
  val searchf_bt_unify_valid: searchinfo -> term -> match Seq.seq Seq.seq

  val setup : theory -> theory
end;

structure EqSubst: EQSUBST =
struct

(* changes object "=" to meta "==" which prepares a given rewrite rule *)
fun prep_meta_eq ctxt =
  Simplifier.mksimps ctxt #> map Drule.zero_var_indexes;

(* make free vars into schematic vars with index zero *)
fun unfix_frees frees =
   fold (K (Thm.forall_elim_var 0)) frees o Drule.forall_intr_list frees;


type match =
  ((indexname * (sort * typ)) list (* type instantiations *)
   * (indexname * (typ * term)) list) (* term instantiations *)
  * (string * typ) list (* fake named type abs env *)
  * (string * typ) list (* type abs env *)
  * term; (* outer term *)

type searchinfo =
  theory
  * int (* maxidx *)
  * Zipper.T; (* focusterm to search under *)


(* skipping non-empty sub-sequences but when we reach the end
   of the seq, remembering how much we have left to skip. *)
datatype 'a skipseq =
  SkipMore of int |
  SkipSeq of 'a Seq.seq Seq.seq;

(* given a seqseq, skip the first m non-empty seq's, note deficit *)
fun skipto_skipseq m s =
  let
    fun skip_occs n sq =
      (case Seq.pull sq of
        NONE => SkipMore n
      | SOME (h, t) =>
        (case Seq.pull h of
          NONE => skip_occs n t
        | SOME _ => if n <= 1 then SkipSeq (Seq.cons h t) else skip_occs (n - 1) t))
  in skip_occs m s end;

(* note: outerterm is the taget with the match replaced by a bound
   variable : ie: "P lhs" beocmes "%x. P x"
   insts is the types of instantiations of vars in lhs
   and typinsts is the type instantiations of types in the lhs
   Note: Final rule is the rule lifted into the ontext of the
   taget thm. *)
fun mk_foo_match mkuptermfunc Ts t =
  let
    val ty = Term.type_of t
    val bigtype = rev (map snd Ts) ---> ty
    fun mk_foo 0 t = t
      | mk_foo i t = mk_foo (i - 1) (t $ (Bound (i - 1)))
    val num_of_bnds = length Ts
    (* foo_term = "fooabs y0 ... yn" where y's are local bounds *)
    val foo_term = mk_foo num_of_bnds (Bound num_of_bnds)
  in Abs ("fooabs", bigtype, mkuptermfunc foo_term) end;

(* T is outer bound vars, n is number of locally bound vars *)
(* THINK: is order of Ts correct...? or reversed? *)
fun mk_fake_bound_name n = ":b_" ^ n;
fun fakefree_badbounds Ts t =
  let val (FakeTs, Ts, newnames) =
    fold_rev (fn (n, ty) => fn (FakeTs, Ts, usednames) =>
      let
        val newname = singleton (Name.variant_list usednames) n
      in
        ((mk_fake_bound_name newname, ty) :: FakeTs,
          (newname, ty) :: Ts,
          newname :: usednames)
      end) Ts ([], [], [])
  in (FakeTs, Ts, Term.subst_bounds (map Free FakeTs, t)) end;

(* before matching we need to fake the bound vars that are missing an
   abstraction. In this function we additionally construct the
   abstraction environment, and an outer context term (with the focus
   abstracted out) for use in rewriting with RW_Inst.rw *)
fun prep_zipper_match z =
  let
    val t = Zipper.trm z
    val c = Zipper.ctxt z
    val Ts = Zipper.C.nty_ctxt c
    val (FakeTs', Ts', t') = fakefree_badbounds Ts t
    val absterm = mk_foo_match (Zipper.C.apply c) Ts' t'
  in
    (t', (FakeTs', Ts', absterm))
  end;

(* Unification with exception handled *)
(* given theory, max var index, pat, tgt; returns Seq of instantiations *)
fun clean_unify thy ix (a as (pat, tgt)) =
  let
    (* type info will be re-derived, maybe this can be cached
       for efficiency? *)
    val pat_ty = Term.type_of pat;
    val tgt_ty = Term.type_of tgt;
    (* FIXME is it OK to ignore the type instantiation info?
       or should I be using it? *)
    val typs_unify =
      SOME (Sign.typ_unify thy (pat_ty, tgt_ty) (Vartab.empty, ix))
        handle Type.TUNIFY => NONE;
  in
    (case typs_unify of
      SOME (typinsttab, ix2) =>
        let
          (* FIXME is it right to throw away the flexes?
             or should I be using them somehow? *)
          fun mk_insts env =
            (Vartab.dest (Envir.type_env env),
             Vartab.dest (Envir.term_env env));
          val initenv =
            Envir.Envir {maxidx = ix2, tenv = Vartab.empty, tyenv = typinsttab};
          val useq = Unify.smash_unifiers thy [a] initenv
            handle ListPair.UnequalLengths => Seq.empty
              | Term.TERM _ => Seq.empty;
          fun clean_unify' useq () =
            (case (Seq.pull useq) of
               NONE => NONE
             | SOME (h, t) => SOME (mk_insts h, Seq.make (clean_unify' t)))
            handle ListPair.UnequalLengths => NONE
              | Term.TERM _ => NONE;
        in
          (Seq.make (clean_unify' useq))
        end
    | NONE => Seq.empty)
  end;

(* Unification for zippers *)
(* Note: Ts is a modified version of the original names of the outer
   bound variables. New names have been introduced to make sure they are
   unique w.r.t all names in the term and each other. usednames' is
   oldnames + new names. *)
fun clean_unify_z thy maxidx pat z =
  let val (t, (FakeTs, Ts, absterm)) = prep_zipper_match z in
    Seq.map (fn insts => (insts, FakeTs, Ts, absterm))
      (clean_unify thy maxidx (t, pat))
  end;


fun bot_left_leaf_of (l $ _) = bot_left_leaf_of l
  | bot_left_leaf_of (Abs (_, _, t)) = bot_left_leaf_of t
  | bot_left_leaf_of x = x;

(* Avoid considering replacing terms which have a var at the head as
   they always succeed trivially, and uninterestingly. *)
fun valid_match_start z =
  (case bot_left_leaf_of (Zipper.trm z) of
    Var _ => false
  | _ => true);

(* search from top, left to right, then down *)
val search_lr_all = ZipperSearch.all_bl_ur;

(* search from top, left to right, then down *)
fun search_lr_valid validf =
  let
    fun sf_valid_td_lr z =
      let val here = if validf z then [Zipper.Here z] else [] in
        (case Zipper.trm z of
          _ $ _ =>
            [Zipper.LookIn (Zipper.move_down_left z)] @ here @
            [Zipper.LookIn (Zipper.move_down_right z)]
        | Abs _ => here @ [Zipper.LookIn (Zipper.move_down_abs z)]
        | _ => here)
      end;
  in Zipper.lzy_search sf_valid_td_lr end;

(* search from bottom to top, left to right *)
fun search_bt_valid validf =
  let
    fun sf_valid_td_lr z =
      let val here = if validf z then [Zipper.Here z] else [] in
        (case Zipper.trm z of
          _ $ _ =>
            [Zipper.LookIn (Zipper.move_down_left z),
             Zipper.LookIn (Zipper.move_down_right z)] @ here
        | Abs _ => [Zipper.LookIn (Zipper.move_down_abs z)] @ here
        | _ => here)
      end;
  in Zipper.lzy_search sf_valid_td_lr end;

fun searchf_unify_gen f (thy, maxidx, z) lhs =
  Seq.map (clean_unify_z thy maxidx lhs) (Zipper.limit_apply f z);

(* search all unifications *)
val searchf_lr_unify_all = searchf_unify_gen search_lr_all;

(* search only for 'valid' unifiers (non abs subterms and non vars) *)
val searchf_lr_unify_valid = searchf_unify_gen (search_lr_valid valid_match_start);

val searchf_bt_unify_valid = searchf_unify_gen (search_bt_valid valid_match_start);

(* apply a substitution in the conclusion of the theorem *)
(* cfvs are certified free var placeholders for goal params *)
(* conclthm is a theorem of for just the conclusion *)
(* m is instantiation/match information *)
(* rule is the equation for substitution *)
fun apply_subst_in_concl ctxt i st (cfvs, conclthm) rule m =
  RW_Inst.rw ctxt m rule conclthm
  |> unfix_frees cfvs
  |> Conv.fconv_rule Drule.beta_eta_conversion
  |> (fn r => rtac r i st);

(* substitute within the conclusion of goal i of gth, using a meta
equation rule. Note that we assume rule has var indicies zero'd *)
fun prep_concl_subst ctxt i gth =
  let
    val th = Thm.incr_indexes 1 gth;
    val tgt_term = Thm.prop_of th;

    val thy = Thm.theory_of_thm th;
    val cert = Thm.cterm_of thy;

    val (fixedbody, fvs) = IsaND.fix_alls_term ctxt i tgt_term;
    val cfvs = rev (map cert fvs);

    val conclterm = Logic.strip_imp_concl fixedbody;
    val conclthm = Thm.trivial (cert conclterm);
    val maxidx = Thm.maxidx_of th;
    val ft =
      (Zipper.move_down_right (* ==> *)
       o Zipper.move_down_left (* Trueprop *)
       o Zipper.mktop
       o Thm.prop_of) conclthm
  in
    ((cfvs, conclthm), (thy, maxidx, ft))
  end;

(* substitute using an object or meta level equality *)
fun eqsubst_tac' ctxt searchf instepthm i st =
  let
    val (cvfsconclthm, searchinfo) = prep_concl_subst ctxt i st;
    val stepthms = Seq.of_list (prep_meta_eq ctxt instepthm);
    fun rewrite_with_thm r =
      let val (lhs,_) = Logic.dest_equals (Thm.concl_of r) in
        searchf searchinfo lhs
        |> Seq.maps (apply_subst_in_concl ctxt i st cvfsconclthm r)
      end;
  in stepthms |> Seq.maps rewrite_with_thm end;


(* General substitution of multiple occurances using one of
   the given theorems *)

fun skip_first_occs_search occ srchf sinfo lhs =
  (case skipto_skipseq occ (srchf sinfo lhs) of
    SkipMore _ => Seq.empty
  | SkipSeq ss => Seq.flat ss);

(* The "occs" argument is a list of integers indicating which occurence
w.r.t. the search order, to rewrite. Backtracking will also find later
occurences, but all earlier ones are skipped. Thus you can use [0] to
just find all rewrites. *)

fun eqsubst_tac ctxt occs thms i st =
  let val nprems = Thm.nprems_of st in
    if nprems < i then Seq.empty else
    let
      val thmseq = Seq.of_list thms;
      fun apply_occ occ st =
        thmseq |> Seq.maps (fn r =>
          eqsubst_tac' ctxt
            (skip_first_occs_search occ searchf_lr_unify_valid) r
            (i + (Thm.nprems_of st - nprems)) st);
      val sorted_occs = Library.sort (rev_order o int_ord) occs;
    in
      Seq.maps distinct_subgoals_tac (Seq.EVERY (map apply_occ sorted_occs) st)
    end
  end;


(* apply a substitution inside assumption j, keeps asm in the same place *)
fun apply_subst_in_asm ctxt i st rule ((cfvs, j, _, pth),m) =
  let
    val st2 = Thm.rotate_rule (j - 1) i st; (* put premice first *)
    val preelimrule =
      RW_Inst.rw ctxt m rule pth
      |> (Seq.hd o prune_params_tac ctxt)
      |> Thm.permute_prems 0 ~1 (* put old asm first *)
      |> unfix_frees cfvs (* unfix any global params *)
      |> Conv.fconv_rule Drule.beta_eta_conversion; (* normal form *)
  in
    (* ~j because new asm starts at back, thus we subtract 1 *)
    Seq.map (Thm.rotate_rule (~ j) (Thm.nprems_of rule + i)) (dtac preelimrule i st2)
  end;


(* prepare to substitute within the j'th premise of subgoal i of gth,
using a meta-level equation. Note that we assume rule has var indicies
zero'd. Note that we also assume that premt is the j'th premice of
subgoal i of gth. Note the repetition of work done for each
assumption, i.e. this can be made more efficient for search over
multiple assumptions.  *)
fun prep_subst_in_asm ctxt i gth j =
  let
    val th = Thm.incr_indexes 1 gth;
    val tgt_term = Thm.prop_of th;

    val thy = Thm.theory_of_thm th;
    val cert = Thm.cterm_of thy;

    val (fixedbody, fvs) = IsaND.fix_alls_term ctxt i tgt_term;
    val cfvs = rev (map cert fvs);

    val asmt = nth (Logic.strip_imp_prems fixedbody) (j - 1);
    val asm_nprems = length (Logic.strip_imp_prems asmt);

    val pth = Thm.trivial (cert asmt);
    val maxidx = Thm.maxidx_of th;

    val ft =
      (Zipper.move_down_right (* trueprop *)
         o Zipper.mktop
         o Thm.prop_of) pth
  in ((cfvs, j, asm_nprems, pth), (thy, maxidx, ft)) end;

(* prepare subst in every possible assumption *)
fun prep_subst_in_asms ctxt i gth =
  map (prep_subst_in_asm ctxt i gth)
    ((fn l => Library.upto (1, length l))
      (Logic.prems_of_goal (Thm.prop_of gth) i));


(* substitute in an assumption using an object or meta level equality *)
fun eqsubst_asm_tac' ctxt searchf skipocc instepthm i st =
  let
    val asmpreps = prep_subst_in_asms ctxt i st;
    val stepthms = Seq.of_list (prep_meta_eq ctxt instepthm);
    fun rewrite_with_thm r =
      let
        val (lhs,_) = Logic.dest_equals (Thm.concl_of r);
        fun occ_search occ [] = Seq.empty
          | occ_search occ ((asminfo, searchinfo)::moreasms) =
              (case searchf searchinfo occ lhs of
                SkipMore i => occ_search i moreasms
              | SkipSeq ss =>
                  Seq.append (Seq.map (Library.pair asminfo) (Seq.flat ss))
                    (occ_search 1 moreasms)) (* find later substs also *)
      in
        occ_search skipocc asmpreps |> Seq.maps (apply_subst_in_asm ctxt i st r)
      end;
  in stepthms |> Seq.maps rewrite_with_thm end;


fun skip_first_asm_occs_search searchf sinfo occ lhs =
  skipto_skipseq occ (searchf sinfo lhs);

fun eqsubst_asm_tac ctxt occs thms i st =
  let val nprems = Thm.nprems_of st in
    if nprems < i then Seq.empty
    else
      let
        val thmseq = Seq.of_list thms;
        fun apply_occ occ st =
          thmseq |> Seq.maps (fn r =>
            eqsubst_asm_tac' ctxt
              (skip_first_asm_occs_search searchf_lr_unify_valid) occ r
              (i + (Thm.nprems_of st - nprems)) st);
        val sorted_occs = Library.sort (rev_order o int_ord) occs;
      in
        Seq.maps distinct_subgoals_tac (Seq.EVERY (map apply_occ sorted_occs) st)
      end
  end;

(* combination method that takes a flag (true indicates that subst
   should be done to an assumption, false = apply to the conclusion of
   the goal) as well as the theorems to use *)
val setup =
  Method.setup @{binding subst}
    (Scan.lift (Args.mode "asm" -- Scan.optional (Args.parens (Scan.repeat Parse.nat)) [0]) --
        Attrib.thms >>
      (fn ((asm, occs), inthms) => fn ctxt =>
        SIMPLE_METHOD' ((if asm then eqsubst_asm_tac else eqsubst_tac) ctxt occs inthms)))
    "single-step substitution";

end;
