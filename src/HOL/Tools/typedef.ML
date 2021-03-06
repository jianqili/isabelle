(*  Title:      HOL/Tools/typedef.ML
    Author:     Markus Wenzel and Stefan Berghofer, TU Muenchen

Gordon/HOL-style type definitions: create a new syntactic type
represented by a non-empty set.
*)

signature TYPEDEF =
sig
  type info =
   {rep_type: typ, abs_type: typ, Rep_name: string, Abs_name: string, axiom_name: string} *
   {inhabited: thm, type_definition: thm, Rep: thm, Rep_inverse: thm, Abs_inverse: thm,
    Rep_inject: thm, Abs_inject: thm, Rep_cases: thm, Abs_cases: thm,
    Rep_induct: thm, Abs_induct: thm}
  val transform_info: morphism -> info -> info
  val get_info: Proof.context -> string -> info list
  val get_info_global: theory -> string -> info list
  val interpretation: (string -> theory -> theory) -> theory -> theory
  val setup: theory -> theory
  val add_typedef: binding * (string * sort) list * mixfix ->
    term -> (binding * binding) option -> tactic -> local_theory -> (string * info) * local_theory
  val add_typedef_global: binding * (string * sort) list * mixfix ->
    term -> (binding * binding) option -> tactic -> theory -> (string * info) * theory
  val typedef: (binding * (string * sort) list * mixfix) * term *
    (binding * binding) option -> local_theory -> Proof.state
  val typedef_cmd: (binding * (string * string option) list * mixfix) * string *
    (binding * binding) option -> local_theory -> Proof.state
end;

structure Typedef: TYPEDEF =
struct

(** type definitions **)

(* theory data *)

type info =
  (*global part*)
  {rep_type: typ, abs_type: typ, Rep_name: string, Abs_name: string, axiom_name: string} *
  (*local part*)
  {inhabited: thm, type_definition: thm, Rep: thm, Rep_inverse: thm, Abs_inverse: thm,
    Rep_inject: thm, Abs_inject: thm, Rep_cases: thm, Abs_cases: thm,
    Rep_induct: thm, Abs_induct: thm};

fun transform_info phi (info: info) =
  let
    val thm = Morphism.thm phi;
    val (global_info, {inhabited, type_definition, Rep, Rep_inverse, Abs_inverse,
      Rep_inject, Abs_inject, Rep_cases, Abs_cases, Rep_induct, Abs_induct}) = info;
  in
    (global_info,
     {inhabited = thm inhabited, type_definition = thm type_definition,
      Rep = thm Rep, Rep_inverse = thm Rep_inverse, Abs_inverse = thm Abs_inverse,
      Rep_inject = thm Rep_inject, Abs_inject = thm Abs_inject,
      Rep_cases = thm Rep_cases, Abs_cases = thm Abs_cases,
      Rep_induct = thm Rep_induct, Abs_induct = thm Abs_induct})
  end;

structure Data = Generic_Data
(
  type T = info list Symtab.table;
  val empty = Symtab.empty;
  val extend = I;
  fun merge data = Symtab.merge_list (K true) data;
);

val get_info = Symtab.lookup_list o Data.get o Context.Proof;
val get_info_global = Symtab.lookup_list o Data.get o Context.Theory;

fun put_info name info = Data.map (Symtab.cons_list (name, info));


(* global interpretation *)

structure Typedef_Interpretation = Interpretation(type T = string val eq = op =);

fun with_repaired_path f name thy =
  thy
  |> Sign.root_path
  |> Sign.add_path (Long_Name.qualifier name)
  |> f name
  |> Sign.restore_naming thy;

fun interpretation f = Typedef_Interpretation.interpretation (with_repaired_path f);

val setup = Typedef_Interpretation.init;


(* primitive typedef axiomatization -- for fresh typedecl *)

fun mk_inhabited A =
  let val T = HOLogic.dest_setT (Term.fastype_of A)
  in HOLogic.mk_Trueprop (HOLogic.exists_const T $ Abs ("x", T, HOLogic.mk_mem (Bound 0, A))) end;

fun mk_typedef newT oldT RepC AbsC A =
  let
    val typedefC =
      Const (@{const_name type_definition},
        (newT --> oldT) --> (oldT --> newT) --> HOLogic.mk_setT oldT --> HOLogic.boolT);
  in Logic.mk_implies (mk_inhabited A, HOLogic.mk_Trueprop (typedefC $ RepC $ AbsC $ A)) end;

fun primitive_typedef typedef_name newT oldT Rep_name Abs_name A lthy =
  let
    (* errors *)

    fun show_names pairs = commas_quote (map fst pairs);

    val lhs_tfrees = Term.add_tfreesT newT [];
    val rhs_tfrees = Term.add_tfreesT oldT [];
    val _ =
      (case fold (remove (op =)) lhs_tfrees rhs_tfrees of [] => ()
      | extras => error ("Extra type variables in representing set: " ^ show_names extras));

    val _ =
      (case Term.add_frees A [] of [] => []
      | xs => error ("Illegal variables in representing set: " ^ show_names xs));


    (* axiomatization *)

    val ((RepC, AbsC), consts_lthy) = lthy
      |> Local_Theory.background_theory_result
        (Sign.declare_const lthy ((Rep_name, newT --> oldT), NoSyn) ##>>
          Sign.declare_const lthy ((Abs_name, oldT --> newT), NoSyn));

    val typedef_deps = Term.add_consts A [];

    val ((axiom_name, axiom), axiom_lthy) = consts_lthy
      |> Local_Theory.background_theory_result
        (Thm.add_axiom consts_lthy (typedef_name, mk_typedef newT oldT RepC AbsC A) ##>
          Theory.add_deps consts_lthy "" (dest_Const RepC) typedef_deps ##>
          Theory.add_deps consts_lthy "" (dest_Const AbsC) typedef_deps);

  in ((RepC, AbsC, axiom_name, axiom), axiom_lthy) end;


(* prepare_typedef *)

fun prepare_typedef prep_term (name, raw_args, mx) raw_set opt_morphs lthy =
  let
    val bname = Binding.name_of name;


    (* rhs *)

    val tmp_ctxt = lthy |> fold (Variable.declare_typ o TFree) raw_args;
    val set = prep_term tmp_ctxt raw_set;
    val tmp_ctxt' = tmp_ctxt |> Variable.declare_term set;

    val setT = Term.fastype_of set;
    val oldT = HOLogic.dest_setT setT handle TYPE _ =>
      error ("Not a set type: " ^ quote (Syntax.string_of_typ lthy setT));

    val goal = mk_inhabited set;
    val goal_pat = mk_inhabited (Var (the_default (bname, 0) (Lexicon.read_variable bname), setT));


    (* lhs *)

    val args = map (Proof_Context.check_tfree tmp_ctxt') raw_args;
    val (newT, typedecl_lthy) = lthy
      |> Typedecl.typedecl (name, args, mx)
      ||> Variable.declare_term set;

    val Type (full_name, _) = newT;


    (* axiomatization *)

    val (Rep_name, Abs_name) =
      (case opt_morphs of
        NONE => (Binding.prefix_name "Rep_" name, Binding.prefix_name "Abs_" name)
      | SOME morphs => morphs);

    val typedef_name = Binding.prefix_name "type_definition_" name;

    val ((RepC, AbsC, axiom_name, typedef), typedef_lthy) = typedecl_lthy
      |> primitive_typedef typedef_name newT oldT Rep_name Abs_name set;

    val alias_lthy = typedef_lthy
      |> Local_Theory.const_alias Rep_name (#1 (Term.dest_Const RepC))
      |> Local_Theory.const_alias Abs_name (#1 (Term.dest_Const AbsC));


    (* result *)

    fun note_qualify ((b, atts), th) =
      Local_Theory.note ((Binding.qualify false bname b, map (Attrib.internal o K) atts), [th])
      #>> (fn (_, [th']) => th');

    fun typedef_result inhabited lthy1 =
      let
        val typedef' = inhabited RS typedef;
        fun make th = Goal.norm_result lthy1 (typedef' RS th);
        val (((((((((((_, [type_definition]), Rep), Rep_inverse), Abs_inverse), Rep_inject),
            Abs_inject), Rep_cases), Abs_cases), Rep_induct), Abs_induct), lthy2) = lthy1
          |> Local_Theory.note ((typedef_name, []), [typedef'])
          ||>> note_qualify ((Rep_name, []), make @{thm type_definition.Rep})
          ||>> note_qualify ((Binding.suffix_name "_inverse" Rep_name, []),
              make @{thm type_definition.Rep_inverse})
          ||>> note_qualify ((Binding.suffix_name "_inverse" Abs_name, []),
              make @{thm type_definition.Abs_inverse})
          ||>> note_qualify ((Binding.suffix_name "_inject" Rep_name, []),
              make @{thm type_definition.Rep_inject})
          ||>> note_qualify ((Binding.suffix_name "_inject" Abs_name, []),
              make @{thm type_definition.Abs_inject})
          ||>> note_qualify ((Binding.suffix_name "_cases" Rep_name,
                [Rule_Cases.case_names [Binding.name_of Rep_name], Induct.cases_pred full_name]),
              make @{thm type_definition.Rep_cases})
          ||>> note_qualify ((Binding.suffix_name "_cases" Abs_name,
                [Rule_Cases.case_names [Binding.name_of Abs_name], Induct.cases_type full_name]),
              make @{thm type_definition.Abs_cases})
          ||>> note_qualify ((Binding.suffix_name "_induct" Rep_name,
                [Rule_Cases.case_names [Binding.name_of Rep_name], Induct.induct_pred full_name]),
              make @{thm type_definition.Rep_induct})
          ||>> note_qualify ((Binding.suffix_name "_induct" Abs_name,
                [Rule_Cases.case_names [Binding.name_of Abs_name], Induct.induct_type full_name]),
              make @{thm type_definition.Abs_induct});

        val info =
          ({rep_type = oldT, abs_type = newT, Rep_name = #1 (Term.dest_Const RepC),
            Abs_name = #1 (Term.dest_Const AbsC), axiom_name = axiom_name},
           {inhabited = inhabited, type_definition = type_definition,
            Rep = Rep, Rep_inverse = Rep_inverse, Abs_inverse = Abs_inverse,
            Rep_inject = Rep_inject, Abs_inject = Abs_inject, Rep_cases = Rep_cases,
          Abs_cases = Abs_cases, Rep_induct = Rep_induct, Abs_induct = Abs_induct});
      in
        lthy2
        |> Local_Theory.declaration {syntax = false, pervasive = true}
          (fn phi => put_info full_name (transform_info phi info))
        |> Local_Theory.background_theory (Typedef_Interpretation.data full_name)
        |> pair (full_name, info)
      end;

  in ((goal, goal_pat, typedef_result), alias_lthy) end
  handle ERROR msg =>
    cat_error msg ("The error(s) above occurred in typedef " ^ Binding.print name);


(* add_typedef: tactic interface *)

fun add_typedef typ set opt_morphs tac lthy =
  let
    val ((goal, _, typedef_result), lthy') =
      prepare_typedef Syntax.check_term typ set opt_morphs lthy;
    val inhabited =
      Goal.prove lthy' [] [] goal (K tac)
      |> Goal.norm_result lthy' |> Thm.close_derivation;
  in typedef_result inhabited lthy' end;

fun add_typedef_global typ set opt_morphs tac =
  Named_Target.theory_init
  #> add_typedef typ set opt_morphs tac
  #> Local_Theory.exit_result_global (apsnd o transform_info);


(* typedef: proof interface *)

local

fun gen_typedef prep_term prep_constraint ((b, raw_args, mx), set, opt_morphs) lthy =
  let
    val args = map (apsnd (prep_constraint lthy)) raw_args;
    val ((goal, goal_pat, typedef_result), lthy') =
      prepare_typedef prep_term (b, args, mx) set opt_morphs lthy;
    fun after_qed [[th]] = snd o typedef_result th;
  in Proof.theorem NONE after_qed [[(goal, [goal_pat])]] lthy' end;

in

val typedef = gen_typedef Syntax.check_term (K I);
val typedef_cmd = gen_typedef Syntax.read_term Typedecl.read_constraint;

end;



(** outer syntax **)

val _ =
  Outer_Syntax.local_theory_to_proof @{command_spec "typedef"}
    "HOL type definition (requires non-emptiness proof)"
    (Parse.type_args_constrained -- Parse.binding -- Parse.opt_mixfix --
      (@{keyword "="} |-- Parse.term) --
      Scan.option (@{keyword "morphisms"} |-- Parse.!!! (Parse.binding -- Parse.binding))
    >> (fn ((((vs, t), mx), A), morphs) => fn lthy => typedef_cmd ((t, vs, mx), A, morphs) lthy));

end;

