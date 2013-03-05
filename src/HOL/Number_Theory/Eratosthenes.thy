(*  Title:      HOL/Number_Theory/Eratosthenes.thy
    Author:     Florian Haftmann, TU Muenchen
*)

header {* The sieve of Eratosthenes *}

theory Eratosthenes
imports Primes
begin

subsection {* Preliminary: strict divisibility *}

context dvd
begin

abbreviation dvd_strict :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infixl "dvd'_strict" 50)
where
  "b dvd_strict a \<equiv> b dvd a \<and> \<not> a dvd b"

end

subsection {* Main corpus *}

text {* The sieve is modelled as a list of booleans, where @{const False} means \emph{marked out}. *}

type_synonym marks = "bool list"

definition numbers_of_marks :: "nat \<Rightarrow> marks \<Rightarrow> nat set"
where
  "numbers_of_marks n bs = fst ` {x \<in> set (enumerate n bs). snd x}"

lemma numbers_of_marks_simps [simp, code]:
  "numbers_of_marks n [] = {}"
  "numbers_of_marks n (True # bs) = insert n (numbers_of_marks (Suc n) bs)"
  "numbers_of_marks n (False # bs) = numbers_of_marks (Suc n) bs"
  by (auto simp add: numbers_of_marks_def intro!: image_eqI)

lemma numbers_of_marks_Suc:
  "numbers_of_marks (Suc n) bs = Suc ` numbers_of_marks n bs"
  by (auto simp add: numbers_of_marks_def enumerate_Suc_eq image_iff Bex_def)

lemma numbers_of_marks_replicate_False [simp]:
  "numbers_of_marks n (replicate m False) = {}"
  by (auto simp add: numbers_of_marks_def enumerate_replicate_eq)

lemma numbers_of_marks_replicate_True [simp]:
  "numbers_of_marks n (replicate m True) = {n..<n+m}"
  by (auto simp add: numbers_of_marks_def enumerate_replicate_eq image_def)

lemma in_numbers_of_marks_eq:
  "m \<in> numbers_of_marks n bs \<longleftrightarrow> m \<in> {n..<n + length bs} \<and> bs ! (m - n)"
  by (simp add: numbers_of_marks_def in_set_enumerate_eq image_iff add_commute)


text {* Marking out multiples in a sieve  *}
 
definition mark_out :: "nat \<Rightarrow> marks \<Rightarrow> marks"
where
  "mark_out n bs = map (\<lambda>(q, b). b \<and> \<not> Suc n dvd Suc (Suc q)) (enumerate n bs)"

lemma mark_out_Nil [simp]:
  "mark_out n [] = []"
  by (simp add: mark_out_def)
  
lemma length_mark_out [simp]:
  "length (mark_out n bs) = length bs"
  by (simp add: mark_out_def)

lemma numbers_of_marks_mark_out:
  "numbers_of_marks n (mark_out m bs) = {q \<in> numbers_of_marks n bs. \<not> Suc m dvd Suc q - n}"
  by (auto simp add: numbers_of_marks_def mark_out_def in_set_enumerate_eq image_iff
    nth_enumerate_eq less_dvd_minus)


text {* Auxiliary operation for efficient implementation  *}

definition mark_out_aux :: "nat \<Rightarrow> nat \<Rightarrow> marks \<Rightarrow> marks"
where
  "mark_out_aux n m bs =
    map (\<lambda>(q, b). b \<and> (q < m + n \<or> \<not> Suc n dvd Suc (Suc q) + (n - m mod Suc n))) (enumerate n bs)"

lemma mark_out_code [code]:
  "mark_out n bs = mark_out_aux n n bs"
proof -
  { fix a
    assume A: "Suc n dvd Suc (Suc a)"
      and B: "a < n + n"
      and C: "n \<le> a"
    have False
    proof (cases "n = 0")
      case True with A B C show False by simp
    next
      def m \<equiv> "Suc n" then have "m > 0" by simp
      case False then have "n > 0" by simp
      from A obtain q where q: "Suc (Suc a) = Suc n * q" by (rule dvdE)
      have "q > 0"
      proof (rule ccontr)
        assume "\<not> q > 0"
        with q show False by simp
      qed
      with `n > 0` have "Suc n * q \<ge> 2" by (auto simp add: gr0_conv_Suc)
      with q have a: "a = Suc n * q - 2" by simp
      with B have "q + n * q < n + n + 2"
        by auto
      then have "m * q < m * 2" by (simp add: m_def)
      with `m > 0` have "q < 2" by simp
      with `q > 0` have "q = 1" by simp
      with a have "a = n - 1" by simp
      with `n > 0` C show False by simp
    qed
  } note aux = this 
  show ?thesis
    by (auto simp add: mark_out_def mark_out_aux_def in_set_enumerate_eq intro: aux)
qed

lemma mark_out_aux_simps [simp, code]:
  "mark_out_aux n m [] = []" (is ?thesis1)
  "mark_out_aux n 0 (b # bs) = False # mark_out_aux n n bs" (is ?thesis2)
  "mark_out_aux n (Suc m) (b # bs) = b # mark_out_aux n m bs" (is ?thesis3)
proof -
  show ?thesis1
    by (simp add: mark_out_aux_def)
  show ?thesis2
    by (auto simp add: mark_out_code [symmetric] mark_out_aux_def mark_out_def
      enumerate_Suc_eq in_set_enumerate_eq less_dvd_minus)
  { def v \<equiv> "Suc m" and w \<equiv> "Suc n"
    fix q
    assume "m + n \<le> q"
    then obtain r where q: "q = m + n + r" by (auto simp add: le_iff_add)
    { fix u
      from w_def have "u mod w < w" by simp
      then have "u + (w - u mod w) = w + (u - u mod w)"
        by simp
      then have "u + (w - u mod w) = w + u div w * w"
        by (simp add: div_mod_equality' [symmetric])
    }
    then have "w dvd v + w + r + (w - v mod w) \<longleftrightarrow> w dvd m + w + r + (w - m mod w)"
      by (simp add: add_assoc add_left_commute [of m] add_left_commute [of v]
        dvd_plus_eq_left dvd_plus_eq_right)
    moreover from q have "Suc q = m + w + r" by (simp add: w_def)
    moreover from q have "Suc (Suc q) = v + w + r" by (simp add: v_def w_def)
    ultimately have "w dvd Suc (Suc (q + (w - v mod w))) \<longleftrightarrow> w dvd Suc (q + (w - m mod w))"
      by (simp only: add_Suc [symmetric])
    then have "Suc n dvd Suc (Suc (Suc (q + n) - Suc m mod Suc n)) \<longleftrightarrow>
      Suc n dvd Suc (Suc (q + n - m mod Suc n))"
      by (simp add: v_def w_def Suc_diff_le trans_le_add2)
  }
  then show ?thesis3
    by (auto simp add: mark_out_aux_def
      enumerate_Suc_eq in_set_enumerate_eq not_less)
qed


text {* Main entry point to sieve *}

fun sieve :: "nat \<Rightarrow> marks \<Rightarrow> marks"
where
  "sieve n [] = []"
| "sieve n (False # bs) = False # sieve (Suc n) bs"
| "sieve n (True # bs) = True # sieve (Suc n) (mark_out n bs)"

text {*
  There are the following possible optimisations here:

  \begin{itemize}

    \item @{const sieve} can abort as soon as @{term n} is too big to let
      @{const mark_out} have any effect.

    \item Search for further primes can be given up as soon as the search
      position exceeds the square root of the maximum candidate.

  \end{itemize}

  This is left as an constructive exercise to the reader.
*}

lemma numbers_of_marks_sieve:
  "numbers_of_marks (Suc n) (sieve n bs) =
    {q \<in> numbers_of_marks (Suc n) bs. \<forall>m \<in> numbers_of_marks (Suc n) bs. \<not> m dvd_strict q}"
proof (induct n bs rule: sieve.induct)
  case 1 show ?case by simp
next
  case 2 then show ?case by simp
next
  case (3 n bs)
  have aux: "\<And>M n. n \<in> Suc ` M \<longleftrightarrow> n > 0 \<and> n - 1 \<in> M"
  proof
    fix M and n
    assume "n \<in> Suc ` M" then show "n > 0 \<and> n - 1 \<in> M" by auto
  next
    fix M and n :: nat
    assume "n > 0 \<and> n - 1 \<in> M"
    then have "n > 0" and "n - 1 \<in> M" by auto
    then have "Suc (n - 1) \<in> Suc ` M" by blast
    with `n > 0` show "n \<in> Suc ` M" by simp
  qed
  { fix m :: nat
    assume "Suc (Suc n) \<le> m" and "m dvd Suc n"
    from `m dvd Suc n` obtain q where "Suc n = m * q" ..
    with `Suc (Suc n) \<le> m` have "Suc (m * q) \<le> m" by simp
    then have "m * q < m" by arith
    then have "q = 0" by simp
    with `Suc n = m * q` have False by simp
  } note aux1 = this
  { fix m q :: nat
    assume "\<forall>q>0. 1 < q \<longrightarrow> Suc n < q \<longrightarrow> q \<le> Suc (n + length bs)
      \<longrightarrow> bs ! (q - Suc (Suc n)) \<longrightarrow> \<not> Suc n dvd q \<longrightarrow> q dvd m \<longrightarrow> m dvd q"
    then have *: "\<And>q. Suc n < q \<Longrightarrow> q \<le> Suc (n + length bs)
      \<Longrightarrow> bs ! (q - Suc (Suc n)) \<Longrightarrow> \<not> Suc n dvd q \<Longrightarrow> q dvd m \<Longrightarrow> m dvd q"
      by auto
    assume "\<not> Suc n dvd m" and "q dvd m"
    then have "\<not> Suc n dvd q" by (auto elim: dvdE)
    moreover assume "Suc n < q" and "q \<le> Suc (n + length bs)"
      and "bs ! (q - Suc (Suc n))"
    moreover note `q dvd m`
    ultimately have "m dvd q" by (auto intro: *)
  } note aux2 = this
  from 3 show ?case
    apply (simp_all add: numbers_of_marks_mark_out numbers_of_marks_Suc Compr_image_eq inj_image_eq_iff
      in_numbers_of_marks_eq Ball_def imp_conjL aux)
    apply safe
    apply (simp_all add: less_diff_conv2 le_diff_conv2 dvd_minus_self not_less)
    apply (clarsimp dest!: aux1)
    apply (simp add: Suc_le_eq less_Suc_eq_le)
    apply (rule aux2) apply (clarsimp dest!: aux1)+
    done
qed


text {* Relation the sieve algorithm to actual primes *}

definition primes_upto :: "nat \<Rightarrow> nat set"
where
  "primes_upto n = {m. m \<le> n \<and> prime m}"

lemma in_primes_upto:
  "m \<in> primes_upto n \<longleftrightarrow> m \<le> n \<and> prime m"
  by (simp add: primes_upto_def)

lemma primes_upto_sieve [code]:
  "primes_upto n = numbers_of_marks 2 (sieve 1 (replicate (n - 1) True))"
proof (cases "n > 1")
  case False then have "n = 0 \<or> n = 1" by arith
  then show ?thesis
    by (auto simp add: numbers_of_marks_sieve One_nat_def numeral_2_eq_2 primes_upto_def dest: prime_gt_Suc_0_nat)
next
  { fix m q
    assume "Suc (Suc 0) \<le> q"
      and "q < Suc n"
      and "m dvd q"
    then have "m < Suc n" by (auto dest: dvd_imp_le)
    assume *: "\<forall>m\<in>{Suc (Suc 0)..<Suc n}. m dvd q \<longrightarrow> q dvd m"
      and "m dvd q" and "m \<noteq> 1"
    have "m = q" proof (cases "m = 0")
      case True with `m dvd q` show ?thesis by simp
    next
      case False with `m \<noteq> 1` have "Suc (Suc 0) \<le> m" by arith
      with `m < Suc n` * `m dvd q` have "q dvd m" by simp
      with `m dvd q` show ?thesis by (simp add: dvd.eq_iff)
    qed
  }
  then have aux: "\<And>m q. Suc (Suc 0) \<le> q \<Longrightarrow>
    q < Suc n \<Longrightarrow>
    m dvd q \<Longrightarrow>
    \<forall>m\<in>{Suc (Suc 0)..<Suc n}. m dvd q \<longrightarrow> q dvd m \<Longrightarrow>
    m dvd q \<Longrightarrow> m \<noteq> q \<Longrightarrow> m = 1" by auto
  case True then show ?thesis
    apply (auto simp add: numbers_of_marks_sieve One_nat_def numeral_2_eq_2 primes_upto_def dest: prime_gt_Suc_0_nat)
    apply (simp add: prime_nat_def dvd_def)
    apply (auto simp add: prime_nat_def aux)
    done
qed

end
