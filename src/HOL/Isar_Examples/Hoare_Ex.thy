header {* Using Hoare Logic *}

theory Hoare_Ex
imports Hoare
begin

subsection {* State spaces *}

text {* First of all we provide a store of program variables that
  occur in any of the programs considered later.  Slightly unexpected
  things may happen when attempting to work with undeclared variables. *}

record vars =
  I :: nat
  M :: nat
  N :: nat
  S :: nat

text {* While all of our variables happen to have the same type,
  nothing would prevent us from working with many-sorted programs as
  well, or even polymorphic ones.  Also note that Isabelle/HOL's
  extensible record types even provides simple means to extend the
  state space later. *}


subsection {* Basic examples *}

text {* We look at few trivialities involving assignment and
  sequential composition, in order to get an idea of how to work with
  our formulation of Hoare Logic. *}

text {* Using the basic @{text assign} rule directly is a bit
  cumbersome. *}

lemma "\<turnstile> \<lbrace>\<acute>(N_update (\<lambda>_. (2 * \<acute>N))) \<in> \<lbrace>\<acute>N = 10\<rbrace>\<rbrace> \<acute>N := 2 * \<acute>N \<lbrace>\<acute>N = 10\<rbrace>"
  by (rule assign)

text {* Certainly we want the state modification already done, e.g.\
  by simplification.  The \name{hoare} method performs the basic state
  update for us; we may apply the Simplifier afterwards to achieve
  ``obvious'' consequences as well. *}

lemma "\<turnstile> \<lbrace>True\<rbrace> \<acute>N := 10 \<lbrace>\<acute>N = 10\<rbrace>"
  by hoare

lemma "\<turnstile> \<lbrace>2 * \<acute>N = 10\<rbrace> \<acute>N := 2 * \<acute>N \<lbrace>\<acute>N = 10\<rbrace>"
  by hoare

lemma "\<turnstile> \<lbrace>\<acute>N = 5\<rbrace> \<acute>N := 2 * \<acute>N \<lbrace>\<acute>N = 10\<rbrace>"
  by hoare simp

lemma "\<turnstile> \<lbrace>\<acute>N + 1 = a + 1\<rbrace> \<acute>N := \<acute>N + 1 \<lbrace>\<acute>N = a + 1\<rbrace>"
  by hoare

lemma "\<turnstile> \<lbrace>\<acute>N = a\<rbrace> \<acute>N := \<acute>N + 1 \<lbrace>\<acute>N = a + 1\<rbrace>"
  by hoare simp

lemma "\<turnstile> \<lbrace>a = a \<and> b = b\<rbrace> \<acute>M := a; \<acute>N := b \<lbrace>\<acute>M = a \<and> \<acute>N = b\<rbrace>"
  by hoare

lemma "\<turnstile> \<lbrace>True\<rbrace> \<acute>M := a; \<acute>N := b \<lbrace>\<acute>M = a \<and> \<acute>N = b\<rbrace>"
  by hoare

lemma
  "\<turnstile> \<lbrace>\<acute>M = a \<and> \<acute>N = b\<rbrace>
      \<acute>I := \<acute>M; \<acute>M := \<acute>N; \<acute>N := \<acute>I
      \<lbrace>\<acute>M = b \<and> \<acute>N = a\<rbrace>"
  by hoare simp

text {* It is important to note that statements like the following one
  can only be proven for each individual program variable.  Due to the
  extra-logical nature of record fields, we cannot formulate a theorem
  relating record selectors and updates schematically. *}

lemma "\<turnstile> \<lbrace>\<acute>N = a\<rbrace> \<acute>N := \<acute>N \<lbrace>\<acute>N = a\<rbrace>"
  by hoare

lemma "\<turnstile> \<lbrace>\<acute>x = a\<rbrace> \<acute>x := \<acute>x \<lbrace>\<acute>x = a\<rbrace>"
  oops

lemma
  "Valid {s. x s = a} (Basic (\<lambda>s. x_update (x s) s)) {s. x s = n}"
  -- {* same statement without concrete syntax *}
  oops


text {* In the following assignments we make use of the consequence
  rule in order to achieve the intended precondition.  Certainly, the
  \name{hoare} method is able to handle this case, too. *}

lemma "\<turnstile> \<lbrace>\<acute>M = \<acute>N\<rbrace> \<acute>M := \<acute>M + 1 \<lbrace>\<acute>M \<noteq> \<acute>N\<rbrace>"
proof -
  have "\<lbrace>\<acute>M = \<acute>N\<rbrace> \<subseteq> \<lbrace>\<acute>M + 1 \<noteq> \<acute>N\<rbrace>"
    by auto
  also have "\<turnstile> \<dots> \<acute>M := \<acute>M + 1 \<lbrace>\<acute>M \<noteq> \<acute>N\<rbrace>"
    by hoare
  finally show ?thesis .
qed

lemma "\<turnstile> \<lbrace>\<acute>M = \<acute>N\<rbrace> \<acute>M := \<acute>M + 1 \<lbrace>\<acute>M \<noteq> \<acute>N\<rbrace>"
proof -
  have "\<And>m n::nat. m = n \<longrightarrow> m + 1 \<noteq> n"
      -- {* inclusion of assertions expressed in ``pure'' logic, *}
      -- {* without mentioning the state space *}
    by simp
  also have "\<turnstile> \<lbrace>\<acute>M + 1 \<noteq> \<acute>N\<rbrace> \<acute>M := \<acute>M + 1 \<lbrace>\<acute>M \<noteq> \<acute>N\<rbrace>"
    by hoare
  finally show ?thesis .
qed

lemma "\<turnstile> \<lbrace>\<acute>M = \<acute>N\<rbrace> \<acute>M := \<acute>M + 1 \<lbrace>\<acute>M \<noteq> \<acute>N\<rbrace>"
  by hoare simp


subsection {* Multiplication by addition *}

text {* We now do some basic examples of actual \texttt{WHILE}
  programs.  This one is a loop for calculating the product of two
  natural numbers, by iterated addition.  We first give detailed
  structured proof based on single-step Hoare rules. *}

lemma
  "\<turnstile> \<lbrace>\<acute>M = 0 \<and> \<acute>S = 0\<rbrace>
      WHILE \<acute>M \<noteq> a
      DO \<acute>S := \<acute>S + b; \<acute>M := \<acute>M + 1 OD
      \<lbrace>\<acute>S = a * b\<rbrace>"
proof -
  let "\<turnstile> _ ?while _" = ?thesis
  let "\<lbrace>\<acute>?inv\<rbrace>" = "\<lbrace>\<acute>S = \<acute>M * b\<rbrace>"

  have "\<lbrace>\<acute>M = 0 \<and> \<acute>S = 0\<rbrace> \<subseteq> \<lbrace>\<acute>?inv\<rbrace>" by auto
  also have "\<turnstile> \<dots> ?while \<lbrace>\<acute>?inv \<and> \<not> (\<acute>M \<noteq> a)\<rbrace>"
  proof
    let ?c = "\<acute>S := \<acute>S + b; \<acute>M := \<acute>M + 1"
    have "\<lbrace>\<acute>?inv \<and> \<acute>M \<noteq> a\<rbrace> \<subseteq> \<lbrace>\<acute>S + b = (\<acute>M + 1) * b\<rbrace>"
      by auto
    also have "\<turnstile> \<dots> ?c \<lbrace>\<acute>?inv\<rbrace>" by hoare
    finally show "\<turnstile> \<lbrace>\<acute>?inv \<and> \<acute>M \<noteq> a\<rbrace> ?c \<lbrace>\<acute>?inv\<rbrace>" .
  qed
  also have "\<dots> \<subseteq> \<lbrace>\<acute>S = a * b\<rbrace>" by auto
  finally show ?thesis .
qed

text {* The subsequent version of the proof applies the @{text hoare}
  method to reduce the Hoare statement to a purely logical problem
  that can be solved fully automatically.  Note that we have to
  specify the \texttt{WHILE} loop invariant in the original statement. *}

lemma
  "\<turnstile> \<lbrace>\<acute>M = 0 \<and> \<acute>S = 0\<rbrace>
      WHILE \<acute>M \<noteq> a
      INV \<lbrace>\<acute>S = \<acute>M * b\<rbrace>
      DO \<acute>S := \<acute>S + b; \<acute>M := \<acute>M + 1 OD
      \<lbrace>\<acute>S = a * b\<rbrace>"
  by hoare auto


subsection {* Summing natural numbers *}

text {* We verify an imperative program to sum natural numbers up to a
  given limit.  First some functional definition for proper
  specification of the problem. *}

text {* The following proof is quite explicit in the individual steps
  taken, with the \name{hoare} method only applied locally to take
  care of assignment and sequential composition.  Note that we express
  intermediate proof obligation in pure logic, without referring to
  the state space. *}

theorem
  "\<turnstile> \<lbrace>True\<rbrace>
      \<acute>S := 0; \<acute>I := 1;
      WHILE \<acute>I \<noteq> n
      DO
        \<acute>S := \<acute>S + \<acute>I;
        \<acute>I := \<acute>I + 1
      OD
      \<lbrace>\<acute>S = (\<Sum>j<n. j)\<rbrace>"
  (is "\<turnstile> _ (_; ?while) _")
proof -
  let ?sum = "\<lambda>k::nat. \<Sum>j<k. j"
  let ?inv = "\<lambda>s i::nat. s = ?sum i"

  have "\<turnstile> \<lbrace>True\<rbrace> \<acute>S := 0; \<acute>I := 1 \<lbrace>?inv \<acute>S \<acute>I\<rbrace>"
  proof -
    have "True \<longrightarrow> 0 = ?sum 1"
      by simp
    also have "\<turnstile> \<lbrace>\<dots>\<rbrace> \<acute>S := 0; \<acute>I := 1 \<lbrace>?inv \<acute>S \<acute>I\<rbrace>"
      by hoare
    finally show ?thesis .
  qed
  also have "\<turnstile> \<dots> ?while \<lbrace>?inv \<acute>S \<acute>I \<and> \<not> \<acute>I \<noteq> n\<rbrace>"
  proof
    let ?body = "\<acute>S := \<acute>S + \<acute>I; \<acute>I := \<acute>I + 1"
    have "\<And>s i. ?inv s i \<and> i \<noteq> n \<longrightarrow> ?inv (s + i) (i + 1)"
      by simp
    also have "\<turnstile> \<lbrace>\<acute>S + \<acute>I = ?sum (\<acute>I + 1)\<rbrace> ?body \<lbrace>?inv \<acute>S \<acute>I\<rbrace>"
      by hoare
    finally show "\<turnstile> \<lbrace>?inv \<acute>S \<acute>I \<and> \<acute>I \<noteq> n\<rbrace> ?body \<lbrace>?inv \<acute>S \<acute>I\<rbrace>" .
  qed
  also have "\<And>s i. s = ?sum i \<and> \<not> i \<noteq> n \<longrightarrow> s = ?sum n"
    by simp
  finally show ?thesis .
qed

text {* The next version uses the @{text hoare} method, while still
  explaining the resulting proof obligations in an abstract,
  structured manner. *}

theorem
  "\<turnstile> \<lbrace>True\<rbrace>
      \<acute>S := 0; \<acute>I := 1;
      WHILE \<acute>I \<noteq> n
      INV \<lbrace>\<acute>S = (\<Sum>j<\<acute>I. j)\<rbrace>
      DO
        \<acute>S := \<acute>S + \<acute>I;
        \<acute>I := \<acute>I + 1
      OD
      \<lbrace>\<acute>S = (\<Sum>j<n. j)\<rbrace>"
proof -
  let ?sum = "\<lambda>k::nat. \<Sum>j<k. j"
  let ?inv = "\<lambda>s i::nat. s = ?sum i"

  show ?thesis
  proof hoare
    show "?inv 0 1" by simp
  next
    fix s i
    assume "?inv s i \<and> i \<noteq> n"
    then show "?inv (s + i) (i + 1)" by simp
  next
    fix s i
    assume "?inv s i \<and> \<not> i \<noteq> n"
    then show "s = ?sum n" by simp
  qed
qed

text {* Certainly, this proof may be done fully automatic as well,
  provided that the invariant is given beforehand. *}

theorem
  "\<turnstile> \<lbrace>True\<rbrace>
      \<acute>S := 0; \<acute>I := 1;
      WHILE \<acute>I \<noteq> n
      INV \<lbrace>\<acute>S = (\<Sum>j<\<acute>I. j)\<rbrace>
      DO
        \<acute>S := \<acute>S + \<acute>I;
        \<acute>I := \<acute>I + 1
      OD
      \<lbrace>\<acute>S = (\<Sum>j<n. j)\<rbrace>"
  by hoare auto


subsection {* Time *}

text {* A simple embedding of time in Hoare logic: function @{text
  timeit} inserts an extra variable to keep track of the elapsed time. *}

record tstate = time :: nat

type_synonym 'a time = "\<lparr>time :: nat, \<dots> :: 'a\<rparr>"

primrec timeit :: "'a time com \<Rightarrow> 'a time com"
where
  "timeit (Basic f) = (Basic f; Basic(\<lambda>s. s\<lparr>time := Suc (time s)\<rparr>))"
| "timeit (c1; c2) = (timeit c1; timeit c2)"
| "timeit (Cond b c1 c2) = Cond b (timeit c1) (timeit c2)"
| "timeit (While b iv c) = While b iv (timeit c)"

record tvars = tstate +
  I :: nat
  J :: nat

lemma lem: "(0::nat) < n \<Longrightarrow> n + n \<le> Suc (n * n)"
  by (induct n) simp_all

lemma
  "\<turnstile> \<lbrace>i = \<acute>I \<and> \<acute>time = 0\<rbrace>
    (timeit
      (WHILE \<acute>I \<noteq> 0
        INV \<lbrace>2 *\<acute> time + \<acute>I * \<acute>I + 5 * \<acute>I = i * i + 5 * i\<rbrace>
        DO
          \<acute>J := \<acute>I;
          WHILE \<acute>J \<noteq> 0
          INV \<lbrace>0 < \<acute>I \<and> 2 * \<acute>time + \<acute>I * \<acute>I + 3 * \<acute>I + 2 * \<acute>J - 2 = i * i + 5 * i\<rbrace>
          DO \<acute>J := \<acute>J - 1 OD;
          \<acute>I := \<acute>I - 1
        OD))
    \<lbrace>2 * \<acute>time = i * i + 5 * i\<rbrace>"
  apply simp
  apply hoare
      apply simp
     apply clarsimp
    apply clarsimp
   apply arith
   prefer 2
   apply clarsimp
  apply (clarsimp simp: nat_distrib)
  apply (frule lem)
  apply arith
  done

end
