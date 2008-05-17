(*  Title:      ZF/Datatype.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1997  University of Cambridge

*)

header{*Datatype and CoDatatype Definitions*}

theory Datatype_ZF
imports Inductive_ZF Univ QUniv
uses "Tools/datatype_package.ML"
begin

ML {*
(*Typechecking rules for most datatypes involving univ*)
structure Data_Arg =
  struct
  val intrs = 
      [@{thm SigmaI}, @{thm InlI}, @{thm InrI},
       @{thm Pair_in_univ}, @{thm Inl_in_univ}, @{thm Inr_in_univ}, 
       @{thm zero_in_univ}, @{thm A_into_univ}, @{thm nat_into_univ}, @{thm UnCI}];


  val elims = [make_elim @{thm InlD}, make_elim @{thm InrD},   (*for mutual recursion*)
               @{thm SigmaE}, @{thm sumE}];                    (*allows * and + in spec*)
  end;


structure Data_Package = 
  Add_datatype_def_Fun
   (structure Fp=Lfp and Pr=Standard_Prod and CP=Standard_CP
    and Su=Standard_Sum
    and Ind_Package = Ind_Package
    and Datatype_Arg = Data_Arg
    val coind = false);


(*Typechecking rules for most codatatypes involving quniv*)
structure CoData_Arg =
  struct
  val intrs = 
      [@{thm QSigmaI}, @{thm QInlI}, @{thm QInrI},
       @{thm QPair_in_quniv}, @{thm QInl_in_quniv}, @{thm QInr_in_quniv}, 
       @{thm zero_in_quniv}, @{thm A_into_quniv}, @{thm nat_into_quniv}, @{thm UnCI}];

  val elims = [make_elim @{thm QInlD}, make_elim @{thm QInrD},   (*for mutual recursion*)
               @{thm QSigmaE}, @{thm qsumE}];                    (*allows * and + in spec*)
  end;

structure CoData_Package = 
  Add_datatype_def_Fun
   (structure Fp=Gfp and Pr=Quine_Prod and CP=Quine_CP
    and Su=Quine_Sum
    and Ind_Package = CoInd_Package
    and Datatype_Arg = CoData_Arg
    val coind = true);



(*Simproc for freeness reasoning: compare datatype constructors for equality*)
structure DataFree =
struct
  val trace = ref false;

  fun mk_new ([],[]) = Const("True",FOLogic.oT)
    | mk_new (largs,rargs) =
        BalancedTree.make FOLogic.mk_conj
                 (map FOLogic.mk_eq (ListPair.zip (largs,rargs)));

 val datatype_ss = @{simpset};

 fun proc sg ss old =
   let val _ = if !trace then writeln ("data_free: OLD = " ^ 
                                       Display.string_of_cterm (cterm_of sg old))
               else ()
       val (lhs,rhs) = FOLogic.dest_eq old
       val (lhead, largs) = strip_comb lhs
       and (rhead, rargs) = strip_comb rhs
       val lname = #1 (dest_Const lhead) handle TERM _ => raise Match;
       val rname = #1 (dest_Const rhead) handle TERM _ => raise Match;
       val lcon_info = the (Symtab.lookup (ConstructorsData.get sg) lname)
         handle Option => raise Match;
       val rcon_info = the (Symtab.lookup (ConstructorsData.get sg) rname)
         handle Option => raise Match;
       val new = 
           if #big_rec_name lcon_info = #big_rec_name rcon_info 
               andalso not (null (#free_iffs lcon_info)) then
               if lname = rname then mk_new (largs, rargs)
               else Const("False",FOLogic.oT)
           else raise Match
       val _ = if !trace then 
                 writeln ("NEW = " ^ Display.string_of_cterm (Thm.cterm_of sg new))
               else ();
       val goal = Logic.mk_equals (old, new)
       val thm = Goal.prove (Simplifier.the_context ss) [] [] goal
         (fn _ => rtac iff_reflection 1 THEN
           simp_tac (Simplifier.inherit_context ss datatype_ss addsimps #free_iffs lcon_info) 1)
         handle ERROR msg =>
         (warning (msg ^ "\ndata_free simproc:\nfailed to prove " ^ Sign.string_of_term sg goal);
          raise Match)
   in SOME thm end
   handle Match => NONE;


 val conv = Simplifier.simproc @{theory} "data_free" ["(x::i) = y"] proc;

end;


Addsimprocs [DataFree.conv];
*}

end
