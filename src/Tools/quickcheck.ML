(*  Title:      Tools/quickcheck.ML
    Author:     Stefan Berghofer, Florian Haftmann, Lukas Bulwahn, TU Muenchen

Generic counterexample search engine.
*)

signature QUICKCHECK =
sig
  val quickcheckN: string
  val genuineN: string
  val noneN: string
  val unknownN: string
  (*configuration*)
  val batch_tester : string Config.T
  val size : int Config.T
  val iterations : int Config.T
  val depth : int Config.T
  val no_assms : bool Config.T
  val report : bool Config.T
  val timeout : real Config.T
  val timing : bool Config.T
  val genuine_only : bool Config.T
  val abort_potential : bool Config.T
  val quiet : bool Config.T
  val verbose : bool Config.T
  val use_subtype : bool Config.T
  val allow_function_inversion : bool Config.T
  val finite_types : bool Config.T
  val finite_type_size : int Config.T
  val tag : string Config.T
  val locale : string Config.T
  val set_active_testers: string list -> Context.generic -> Context.generic
  datatype expectation = No_Expectation | No_Counterexample | Counterexample;
  datatype test_params = Test_Params of {default_type: typ list, expect : expectation};
  val test_params_of : Proof.context -> test_params
  val map_test_params : (typ list * expectation -> typ list * expectation)
    -> Context.generic -> Context.generic
  val default_type : Proof.context -> typ list
  datatype report = Report of
    { iterations : int, raised_match_errors : int,
      satisfied_assms : int list, positive_concl_tests : int }
  (*quickcheck's result*)
  datatype result =
    Result of
     {counterexample : (bool * (string * term) list) option,
      evaluation_terms : (term * term) list option,
      timings : (string * int) list,
      reports : (int * report) list}
  val empty_result : result
  val found_counterexample : result -> bool
  val add_timing : (string * int) -> result Unsynchronized.ref -> unit
  val add_response : string list -> term list -> (bool * term list) option ->
    result Unsynchronized.ref -> unit
  val add_report : int -> report option -> result Unsynchronized.ref -> unit
  val counterexample_of : result -> (bool * (string * term) list) option
  val timings_of : result -> (string * int) list
  (*registering testers & generators*)
  type tester =
    Proof.context -> bool -> (string * typ) list -> (term * term list) list -> result list
  val add_tester : string * (bool Config.T * tester) -> Context.generic -> Context.generic
  val add_batch_generator :
    string * (Proof.context -> term list -> (int -> term list option) list)
      -> Context.generic -> Context.generic
  val add_batch_validator :
    string * (Proof.context -> term list -> (int -> bool) list)
      -> Context.generic -> Context.generic
  (*basic operations*)
  val message : Proof.context -> string -> unit
  val verbose_message : Proof.context -> string -> unit
  val limit : Time.time -> (bool * bool) -> (unit -> 'a) -> (unit -> 'a) -> unit -> 'a
  val pretty_counterex : Proof.context -> bool ->
    ((bool * (string * term) list) * (term * term) list) option -> Pretty.T
  (*testing terms and proof states*)
  val mk_batch_validator : Proof.context -> term list -> (int -> bool) list option
  val mk_batch_tester : Proof.context -> term list -> (int -> term list option) list option
  val active_testers : Proof.context -> tester list
  val test_terms : Proof.context -> bool * bool -> (string * typ) list ->
    (term * term list) list -> result list option
  val quickcheck: (string * string list) list -> int -> Proof.state ->
    (bool * (string * term) list) option
end;

structure Quickcheck : QUICKCHECK =
struct

val quickcheckN = "quickcheck";

val genuineN = "genuine";
val noneN = "none";
val unknownN = "unknown";


(* preferences *)

val _ =
  ProofGeneral.preference_option ProofGeneral.category_tracing
    NONE
    @{system_option auto_quickcheck}
    "auto-quickcheck"
    "Run Quickcheck automatically";


(* quickcheck report *)

datatype report = Report of
 {iterations : int,
  raised_match_errors : int,
  satisfied_assms : int list,
  positive_concl_tests : int};


(* Quickcheck Result *)

datatype result = Result of
 {counterexample : (bool * (string * term) list) option,
  evaluation_terms : (term * term) list option,
  timings : (string * int) list,
  reports : (int * report) list};

val empty_result =
  Result {counterexample = NONE, evaluation_terms = NONE, timings = [], reports = []};

fun counterexample_of (Result r) = #counterexample r;

fun found_counterexample (Result r) = is_some (#counterexample r);

fun response_of (Result r) =
  (case (#counterexample r, #evaluation_terms r) of
    (SOME ts, SOME evals) => SOME (ts, evals)
  | (NONE, NONE) => NONE);

fun timings_of (Result r) = #timings r;

fun set_response names eval_terms (SOME (genuine, ts)) (Result r) =
      let
        val (ts1, ts2) = chop (length names) ts
        val (eval_terms', _) = chop (length ts2) eval_terms
      in
        Result {counterexample = SOME (genuine, (names ~~ ts1)),
          evaluation_terms = SOME (eval_terms' ~~ ts2),
          timings = #timings r, reports = #reports r}
      end
  | set_response _ _ NONE result = result;


fun cons_timing timing (Result r) =
  Result {counterexample = #counterexample r, evaluation_terms = #evaluation_terms r,
    timings = cons timing (#timings r), reports = #reports r};

fun cons_report size (SOME report) (Result r) =
      Result {counterexample = #counterexample r, evaluation_terms = #evaluation_terms r,
        timings = #timings r, reports = cons (size, report) (#reports r)}
  | cons_report _ NONE result = result;

fun add_timing timing result_ref =
  Unsynchronized.change result_ref (cons_timing timing);

fun add_report size report result_ref =
  Unsynchronized.change result_ref (cons_report size report);

fun add_response names eval_terms response result_ref =
  Unsynchronized.change result_ref (set_response names eval_terms response);


(* expectation *)

datatype expectation = No_Expectation | No_Counterexample | Counterexample;

fun merge_expectation (expect1, expect2) =
  if expect1 = expect2 then expect1 else No_Expectation;

(*quickcheck configuration -- default parameters, test generators*)
val batch_tester = Attrib.setup_config_string @{binding quickcheck_batch_tester} (K "");
val size = Attrib.setup_config_int @{binding quickcheck_size} (K 10);
val iterations = Attrib.setup_config_int @{binding quickcheck_iterations} (K 100);
val depth = Attrib.setup_config_int @{binding quickcheck_depth} (K 10);

val no_assms = Attrib.setup_config_bool @{binding quickcheck_no_assms} (K false);
val locale = Attrib.setup_config_string @{binding quickcheck_locale} (K "interpret expand");
val report = Attrib.setup_config_bool @{binding quickcheck_report} (K true);
val timing = Attrib.setup_config_bool @{binding quickcheck_timing} (K false);
val timeout = Attrib.setup_config_real @{binding quickcheck_timeout} (K 30.0);

val genuine_only = Attrib.setup_config_bool @{binding quickcheck_genuine_only} (K false);
val abort_potential = Attrib.setup_config_bool @{binding quickcheck_abort_potential} (K false);

val quiet = Attrib.setup_config_bool @{binding quickcheck_quiet} (K false);
val verbose = Attrib.setup_config_bool @{binding quickcheck_verbose} (K false);
val tag = Attrib.setup_config_string @{binding quickcheck_tag} (K "");

val use_subtype = Attrib.setup_config_bool @{binding quickcheck_use_subtype} (K false);

val allow_function_inversion =
  Attrib.setup_config_bool @{binding quickcheck_allow_function_inversion} (K false);
val finite_types = Attrib.setup_config_bool @{binding quickcheck_finite_types} (K true);
val finite_type_size = Attrib.setup_config_int @{binding quickcheck_finite_type_size} (K 3);

datatype test_params = Test_Params of
  {default_type: typ list, expect : expectation};

fun dest_test_params (Test_Params {default_type, expect}) = (default_type, expect);

fun make_test_params (default_type, expect) =
  Test_Params {default_type = default_type, expect = expect};

fun map_test_params' f (Test_Params {default_type, expect}) =
  make_test_params (f (default_type, expect));

fun merge_test_params
  (Test_Params {default_type = default_type1, expect = expect1},
    Test_Params {default_type = default_type2, expect = expect2}) =
  make_test_params
    (merge (op =) (default_type1, default_type2), merge_expectation (expect1, expect2));

type tester =
  Proof.context -> bool -> (string * typ) list -> (term * term list) list -> result list;

structure Data = Generic_Data
(
  type T =
    ((string * (bool Config.T * tester)) list *
      ((string * (Proof.context -> term list -> (int -> term list option) list)) list *
      ((string * (Proof.context -> term list -> (int -> bool) list)) list))) *
      test_params;
  val empty = (([], ([], [])), Test_Params {default_type = [], expect = No_Expectation});
  val extend = I;
  fun merge
   (((testers1, (batch_generators1, batch_validators1)), params1),
    ((testers2, (batch_generators2, batch_validators2)), params2)) : T =
    ((AList.merge (op =) (K true) (testers1, testers2),
      (AList.merge (op =) (K true) (batch_generators1, batch_generators2),
       AList.merge (op =) (K true) (batch_validators1, batch_validators2))),
      merge_test_params (params1, params2));
);

val test_params_of = snd o Data.get o Context.Proof;

val default_type = fst o dest_test_params o test_params_of;

val expect = snd o dest_test_params o test_params_of;

val map_test_params = Data.map o apsnd o map_test_params';

val add_tester = Data.map o apfst o apfst o AList.update (op =);

val add_batch_generator = Data.map o apfst o apsnd o apfst o AList.update (op =);

val add_batch_validator = Data.map o apfst o apsnd o apsnd o AList.update (op =);

fun active_testers ctxt =
  let
    val testers = map snd (fst (fst (Data.get (Context.Proof ctxt))));
  in
    map snd (filter (fn (active, _) => Config.get ctxt active) testers)
  end;

fun set_active_testers [] context = context
  | set_active_testers testers context =
      let
        val registered_testers = fst (fst (Data.get context));
      in
        fold (fn (name, (config, _)) => Config.put_generic config (member (op =) testers name))
          registered_testers context
      end;


(* generating tests *)

fun gen_mk_tester lookup ctxt v =
  let
    val name = Config.get ctxt batch_tester
    val tester =
      (case lookup ctxt name of
        NONE => error ("No such quickcheck batch-tester: " ^ name)
      | SOME tester => tester ctxt);
  in
    if Config.get ctxt quiet then
      try tester v
    else
      let (* FIXME !?!? *)
        val tester = Exn.interruptible_capture tester v
      in
        (case Exn.get_res tester of
          NONE => SOME (Exn.release tester)
        | SOME tester => SOME tester)
      end
  end;

val mk_batch_tester =
  gen_mk_tester (AList.lookup (op =) o fst o snd o fst o Data.get o Context.Proof);
val mk_batch_validator =
  gen_mk_tester (AList.lookup (op =) o snd o snd o fst o Data.get o Context.Proof);


(* testing propositions *)

type compile_generator =
  Proof.context -> (term * term list) list -> int list -> term list option * report option;

fun limit timeout (limit_time, is_interactive) f exc () =
  if limit_time then
    TimeLimit.timeLimit timeout f ()
      handle TimeLimit.TimeOut =>
        if is_interactive then exc () else raise TimeLimit.TimeOut
  else f ();

fun message ctxt s = if Config.get ctxt quiet then () else Output.urgent_message s;

fun verbose_message ctxt s =
  if not (Config.get ctxt quiet) andalso Config.get ctxt verbose
  then Output.urgent_message s else ();

fun test_terms ctxt (limit_time, is_interactive) insts goals =
  (case active_testers ctxt of
    [] => error "No active testers for quickcheck"
  | testers =>
      limit (seconds (Config.get ctxt timeout)) (limit_time, is_interactive)
        (fn () =>
          Par_List.get_some (fn tester =>
            tester ctxt (length testers > 1) insts goals |>
            (fn result => if exists found_counterexample result then SOME result else NONE))
          testers)
        (fn () => (message ctxt "Quickcheck ran out of time"; NONE)) ());

fun all_axioms_of ctxt t =
  let
    val intros = Locale.get_intros ctxt;
    val unfolds = Locale.get_unfolds ctxt;
    fun retrieve_prems thms t =
       (case filter (fn th => Term.could_unify (Thm.concl_of th, t)) thms of
         [] => NONE
       | [th] =>
           let
             val (tyenv, tenv) =
               Pattern.match (Proof_Context.theory_of ctxt)
                (Thm.concl_of th, t) (Vartab.empty, Vartab.empty)
           in SOME (map (Envir.subst_term (tyenv, tenv)) (Thm.prems_of th)) end);
    fun all t =
      (case retrieve_prems intros t of
        NONE => retrieve_prems unfolds t
      | SOME ts => SOME (maps (fn t => the_default [t] (all t)) ts));
  in
    all t
  end;

fun locale_config_of s =
  let
    val cs = space_explode " " s;
  in
    if forall (fn c => c = "expand" orelse c = "interpret") cs then cs
    else
     (warning ("Invalid quickcheck_locale setting: falling back to the default setting.");
      ["interpret", "expand"])
  end;

fun test_goal (time_limit, is_interactive) (insts, eval_terms) i state =
  let
    val lthy = Proof.context_of state;
    val thy = Proof.theory_of state;
    val _ = message lthy "Quickchecking..."
    fun strip (Const (@{const_name Pure.all}, _) $ Abs (_, _, t)) = strip t
      | strip t = t;
    val {goal = st, ...} = Proof.raw_goal state;
    val (gi, frees) = Logic.goal_params (prop_of st) i;
    val some_locale = Named_Target.bottom_locale_of lthy;
    val assms =
      if Config.get lthy no_assms then []
      else
        (case some_locale of
          NONE => Assumption.all_assms_of lthy
        | SOME locale => Assumption.local_assms_of lthy (Locale.init locale thy));
    val proto_goal = Logic.list_implies (map Thm.term_of assms, subst_bounds (frees, strip gi));
    fun axioms_of locale =
      (case fst (Locale.specification_of thy locale) of
        NONE => []
      | SOME t => the_default [] (all_axioms_of lthy t));
    val config = locale_config_of (Config.get lthy locale);
    val goals =
      (case some_locale of
        NONE => [(proto_goal, eval_terms)]
      | SOME locale =>
          fold (fn c =>
            if c = "expand" then
              cons (Logic.list_implies (axioms_of locale, proto_goal), eval_terms)
            else if c = "interpret" then
              append (map (fn (_, phi) =>
                  (Morphism.term phi proto_goal, map (Morphism.term phi) eval_terms))
                (Locale.registrations_of (Context.Theory thy) (* FIXME !? *) locale))
            else I) config []);
    val _ =
      verbose_message lthy
        (Pretty.string_of
          (Pretty.big_list ("Checking goals: ") (map (Syntax.pretty_term lthy o fst) goals)));
  in
    test_terms lthy (time_limit, is_interactive) insts goals
  end;


(* pretty printing *)

fun tool_name auto = (if auto then "Auto " else "") ^ "Quickcheck";

fun pretty_counterex ctxt auto NONE =
      Pretty.str (tool_name auto ^ " found no counterexample." ^ Config.get ctxt tag)
  | pretty_counterex ctxt auto (SOME ((genuine, cex), eval_terms)) =
      (Pretty.text_fold o Pretty.fbreaks)
       (Pretty.str (tool_name auto ^ " found a " ^
         (if genuine then "counterexample:"
          else "potentially spurious counterexample due to underspecified functions:") ^
        Config.get ctxt tag) ::
        Pretty.str "" ::
        map (fn (s, t) =>
          Pretty.block [Pretty.str (s ^ " ="), Pretty.brk 1, Syntax.pretty_term ctxt t]) (rev cex) @
        (if null eval_terms then []
         else
          Pretty.str "" :: Pretty.str "Evaluated terms:" ::
            map (fn (t, u) =>
              Pretty.block [Syntax.pretty_term ctxt t, Pretty.str " =", Pretty.brk 1,
                Syntax.pretty_term ctxt u]) (rev eval_terms)));


(* Isar commands *)

fun read_nat s =
  (case Library.read_int (Symbol.explode s) of
    (k, []) =>
      if k >= 0 then k
      else error ("Not a natural number: " ^ s)
  | _ => error ("Not a natural number: " ^ s));

fun read_bool "false" = false
  | read_bool "true" = true
  | read_bool s = error ("Not a Boolean value: " ^ s);

fun read_real s =
  (case Real.fromString s of
    SOME s => s
  | NONE => error ("Not a real number: " ^ s));

fun read_expectation "no_expectation" = No_Expectation
  | read_expectation "no_counterexample" = No_Counterexample
  | read_expectation "counterexample" = Counterexample
  | read_expectation s = error ("Not an expectation value: " ^ s);

fun valid_tester_name genctxt name =
  AList.defined (op =) (fst (fst (Data.get genctxt))) name;

fun parse_tester name (testers, genctxt) =
  if valid_tester_name genctxt name then
    (insert (op =) name testers, genctxt)
  else error ("Unknown tester: " ^ name);

fun parse_test_param ("tester", args) = fold parse_tester args
  | parse_test_param ("size", [arg]) = apsnd (Config.put_generic size (read_nat arg))
  | parse_test_param ("iterations", [arg]) = apsnd (Config.put_generic iterations (read_nat arg))
  | parse_test_param ("depth", [arg]) = apsnd (Config.put_generic depth (read_nat arg))
  | parse_test_param ("default_type", arg) =
      (fn (testers, context) =>
        (testers, map_test_params
          (apfst (K (map (Proof_Context.read_typ (Context.proof_of context)) arg))) context))
  | parse_test_param ("no_assms", [arg]) = apsnd (Config.put_generic no_assms (read_bool arg))
  | parse_test_param ("expect", [arg]) = apsnd (map_test_params (apsnd (K (read_expectation arg))))
  | parse_test_param ("report", [arg]) = apsnd (Config.put_generic report (read_bool arg))
  | parse_test_param ("genuine_only", [arg]) =
      apsnd (Config.put_generic genuine_only (read_bool arg))
  | parse_test_param ("abort_potential", [arg]) =
      apsnd (Config.put_generic abort_potential (read_bool arg))
  | parse_test_param ("quiet", [arg]) = apsnd (Config.put_generic quiet (read_bool arg))
  | parse_test_param ("verbose", [arg]) = apsnd (Config.put_generic verbose (read_bool arg))
  | parse_test_param ("tag", [arg]) = apsnd (Config.put_generic tag arg)
  | parse_test_param ("use_subtype", [arg]) =
      apsnd (Config.put_generic use_subtype (read_bool arg))
  | parse_test_param ("timeout", [arg]) =
      apsnd (Config.put_generic timeout (read_real arg))
  | parse_test_param ("finite_types", [arg]) =
      apsnd (Config.put_generic finite_types (read_bool arg))
  | parse_test_param ("allow_function_inversion", [arg]) =
      apsnd (Config.put_generic allow_function_inversion (read_bool arg))
  | parse_test_param ("finite_type_size", [arg]) =
      apsnd (Config.put_generic finite_type_size (read_nat arg))
  | parse_test_param (name, _) =
      (fn (testers, genctxt) =>
        if valid_tester_name genctxt name then
          (insert (op =) name testers, genctxt)
        else error ("Unknown tester or test parameter: " ^ name));

fun parse_test_param_inst (name, arg) ((insts, eval_terms), (testers, ctxt)) =
  (case try (Proof_Context.read_typ ctxt) name of
    SOME (TFree (v, _)) =>
      ((AList.update (op =) (v, Proof_Context.read_typ ctxt (the_single arg)) insts, eval_terms),
        (testers, ctxt))
  | NONE =>
      (case name of
        "eval" => ((insts, eval_terms @ map (Syntax.read_term ctxt) arg), (testers, ctxt))
      | _ =>
        ((insts, eval_terms),
          let
            val (testers', Context.Proof ctxt') =
              parse_test_param (name, arg) (testers, Context.Proof ctxt);
          in (testers', ctxt') end)));

fun quickcheck_params_cmd args =
  Context.theory_map
    (fn context => uncurry set_active_testers (fold parse_test_param args ([], context)));

fun check_expectation state results =
  if is_some results andalso expect (Proof.context_of state) = No_Counterexample then
    error "quickcheck expected to find no counterexample but found one"
  else if is_none results andalso expect (Proof.context_of state) = Counterexample then
    error "quickcheck expected to find a counterexample but did not find one"
  else ();

fun gen_quickcheck args i state =
  state
  |> Proof.map_context_result (fn ctxt =>
    apsnd (fn (testers, ctxt) => Context.proof_map (set_active_testers testers) ctxt)
      (fold parse_test_param_inst args (([], []), ([], ctxt))))
  |> (fn ((insts, eval_terms), state') =>
      test_goal (true, true) (insts, eval_terms) i state'
      |> tap (check_expectation state')
      |> rpair state');

fun quickcheck args i state =
  Option.map (the o get_first counterexample_of) (fst (gen_quickcheck args i state));

fun quickcheck_cmd args i state =
  gen_quickcheck args i (Toplevel.proof_of state)
  |> apfst (Option.map (the o get_first response_of))
  |> (fn (r, state) =>
      Output.urgent_message (Pretty.string_of
        (pretty_counterex (Proof.context_of state) false r)));

val parse_arg =
  Parse.name --
    (Scan.optional (@{keyword "="} |--
      (((Parse.name || Parse.float_number) >> single) ||
        (@{keyword "["} |-- Parse.list1 Parse.name --| @{keyword "]"}))) ["true"]);

val parse_args =
  @{keyword "["} |-- Parse.list1 parse_arg --| @{keyword "]"} || Scan.succeed [];

val _ =
  Outer_Syntax.command @{command_spec "quickcheck_params"} "set parameters for random testing"
    (parse_args >> (fn args => Toplevel.theory (quickcheck_params_cmd args)));

val _ =
  Outer_Syntax.improper_command @{command_spec "quickcheck"}
    "try to find counterexample for subgoal"
    (parse_args -- Scan.optional Parse.nat 1 >> (fn (args, i) =>
      Toplevel.unknown_proof o Toplevel.keep (quickcheck_cmd args i)));


(* automatic testing *)

fun try_quickcheck auto state =
  let
    val ctxt = Proof.context_of state;
    val i = 1;
    val res =
      state
      |> Proof.map_context (Config.put report false #> Config.put quiet true)
      |> try (test_goal (false, false) ([], []) i);
  in
    (case res of
      NONE => (unknownN, state)
    | SOME results =>
        let
          val msg = pretty_counterex ctxt auto (Option.map (the o get_first response_of) results)
        in
          if is_some results then
            (genuineN,
             state
             |> (if auto then
                   Proof.goal_message (K (Pretty.mark Markup.information msg))
                 else
                   tap (fn _ => Output.urgent_message (Pretty.string_of msg))))
          else
            (noneN, state)
        end)
  end
  |> `(fn (outcome_code, _) => outcome_code = genuineN);

val _ = Try.tool_setup (quickcheckN, (20, @{system_option auto_quickcheck}, try_quickcheck));

end;

