# Consulta nulos em last_month_salary 
SELECT
  COUNT(*)
FROM
  `riscorelativo.user_info`
WHERE
  last_month_salary IS NULL

# Consulta nulos em number_dependents 
SELECT
  COUNT(*)
FROM
  `riscorelativo.user_info`
WHERE
  number_dependents IS NULL

#Consulta para verificar a mediana em "number_dependents"
WITH median_values AS (
  SELECT
    APPROX_QUANTILES(number_dependents, 100)[OFFSET(50)] AS mediana_dependents
  FROM
    `riscorelativo.user_info`
)
SELECT
  mediana_dependents
FROM
  median_values;

#Consulta para verificar a mediana em "last_month_salary"
WITH median_values AS (
  SELECT
    APPROX_QUANTILES(last_month_salary, 100)[OFFSET(50)] AS mediana_salary
  FROM
    `riscorelativo.user_info`
)
SELECT
  mediana_salary
FROM
  median_values;

#Substituir os nulos de "number_dependents" e "last_month_salary"
CREATE OR REPLACE TABLE `riscorelativo.user_info_limpa` AS
SELECT
user_id,
age,
sex,
IFNULL(last_month_salary, 0) AS number_dependents_limpo,
IFNULL(number_dependents, 5400) AS last_month_salary_limpo,
FROM `riscorelativo.user_info`

#Consulta para o cálculo de correlação de more_90_days_overdue e number_times_delayed_payment_loan_30_59_days e number_times_delayed_payment_loan_60_89_days
SELECT
    CORR(more_90_days_overdue, number_times_delayed_payment_loan_30_59_days) AS correlacao_30_59,
    CORR(more_90_days_overdue, number_times_delayed_payment_loan_60_89_days) AS correlacao_60_89,
FROM 
    `riscorelativo.loansdetail_userinfo_limpa`

# Consulta duplicados e agrupando por quantidade de empréstimos por id
SELECT
  user_id,
  loan_type,
  COUNT(*) AS quantidade_emprestimo
FROM
  `riscorelativo.loans_outstanding`
GROUP BY
  user_id,
  loan_type

#Consulta para criar nova variável total_loans e ajustar dados inconsistentes em variáveis categóricas
CREATE OR REPLACE TABLE `riscorelativo.loans_outstanding_corrigido` AS
SELECT
  user_id,
  COUNT(DISTINCT loan_id) AS total_loans,
  COUNTIF(REGEXP_CONTAINS(loan_type, '(?i)real estate')) AS real_estate,
  COUNTIF(REGEXP_CONTAINS(loan_type, '(?i)other')) AS others
FROM
  `riscorelativo.loans_outstanding`
GROUP BY
  user_id

# Consulta para tratar dados discrepantes em loans_detail
CREATE TABLE `riscorelativo.loans_detail_corrigida` AS
WITH loans_detail_corrigido AS (
  SELECT
    user_id,
    more_90_days_overdue,
    CASE
      WHEN using_lines_not_secured_personal_assets > 1 THEN 1
      ELSE using_lines_not_secured_personal_assets
    END AS using_lines_corrigida,
    number_times_delayed_payment_loan_30_59_days,
    number_times_delayed_payment_loan_60_89_days,
    CASE
      WHEN debt_ratio > 1 THEN 1
      ELSE debt_ratio
    END AS debt_ratio_corrigido
  FROM
    `riscorelativo.loans_detail` 
)
SELECT
  *
FROM
  loans_detail_corrigido;

# Consulta para valores fora do alcance da análise
SELECT 
  STDDEV(more_90_days_overdue) AS desvpad_90,
  STDDEV(number_times_delayed_payment_loan_30_59_days) AS desvpad_30_59,
  STDDEV(number_times_delayed_payment_loan_60_89_days) AS desvpad_60_89,
FROM `projeto03-supercaja.riscorelativo.loans_detail` 

#Consulta para unir tabelas
CREATE OR REPLACE TABLE `riscorelativo.loansdetail_userinfo` AS
SELECT
  u.user_id,
  u.age,
  u.sex,
  u.last_month_salary_limpo,
  u.number_dependents_limpo,
  l.more_90_days_overdue,
  l.using_lines_corrigida,
  l.number_times_delayed_payment_loan_30_59_days,
  l.debt_ratio_corrigido,
  l.number_times_delayed_payment_loan_60_89_days
FROM
  `riscorelativo.user_info_limpa` u
LEFT JOIN
  `riscorelativo.loans_detail_corrigida` l
ON
  u.user_id = l.user_id

#Consulta para unir tabelas
CREATE OR REPLACE TABLE `riscorelativo.default_loansoutstanding` AS
SELECT
  d.user_id,
  d.default_flag,
  l.total_loans,
  l.real_estate,
  l.others
FROM
  `riscorelativo.default` d
LEFT JOIN
  `riscorelativo.loans_outstanding_corrigido` l
ON
  d.user_id = l.user_id

#Consulta para unir todas as tabelas usando FULL JOIN
CREATE OR REPLACE TABLE `riscorelativo.tabela_final_full` AS
SELECT
  lu.age,
  lu.sex,
  lu.last_month_salary_limpo,
  lu.number_dependents_limpo,
  lu.more_90_days_overdue,
  lu.using_lines_corrigida,
  lu.number_times_delayed_payment_loan_30_59_days,
  lu.number_times_delayed_payment_loan_60_89_days,
  lu.debt_ratio_corrigido,
  dl.user_id,
  dl.default_flag,
  dl.total_loans,
  dl.real_estate,
  dl.others,
FROM
  `riscorelativo.loansdetail_userinfo` lu
FULL JOIN
  `riscorelativo.default_loansoutstanding` dl
ON
  lu.user_id = dl.user_id

#Consulta para unir todas as tabelas e tratar os valores nulos
CREATE OR REPLACE TABLE `riscorelativo.tabela_final_tratada` AS
SELECT
  lu.age,
  lu.sex,
  lu.last_month_salary_limpo,
  lu.number_dependents_limpo,
  lu.more_90_days_overdue,
  lu.using_lines_corrigida,
  lu.number_times_delayed_payment_loan_30_59_days,
  lu.number_times_delayed_payment_loan_60_89_days,
  lu.debt_ratio_corrigido,
  dl.user_id,
  dl.default_flag,
  COALESCE(dl.total_loans, 0) AS total_loans,
  COALESCE(dl.real_estate, 0) AS real_estate,
  COALESCE(dl.others, 0) AS others
FROM
  `riscorelativo.loansdetail_userinfo` lu
RIGHT JOIN
  `riscorelativo.default_loansoutstanding` dl
ON
  lu.user_id = dl.user_id;

#Consulta correlações entre variáveis ​​numéricas
SELECT
  CORR(age,last_month_salary_limpo) AS correlacao_age_salary,
  CORR(number_dependents_limpo, last_month_salary_limpo) AS correlacao_dependents_salary,
  CORR(number_dependents_limpo, total_loans) AS correlacao_dependents_total_loans
  CORR(total_loans,debt_ratio_corrigido) AS correlacao_total_loans_debt_ratio,
  CORR(age,last_month_salary_limpo) AS correlacao_age_salary,
  CORR(using_lines_corrigida,default_flag) AS correlacao_using_lines_default_flag,
  CORR(number_times_delayed_payment_loan_30_59_days,default_flag) AS correlacao_30_59_default_flag,
  CORR(number_times_delayed_payment_loan_60_89_days,default_flag) AS correlacao_60_89_default_flag,
FROM
  `riscorelativo.tabela_final_tratada`

#Consulta para criar quartis
WITH
  quartis AS (
    SELECT
      user_id,
      default_flag,
      age,
      last_month_salary_limpo,
      number_dependents_limpo,
      more_90_days_overdue,
      using_lines_corrigida,
      number_times_delayed_payment_loan_30_59_days,
      number_times_delayed_payment_loan_60_89_days,
      debt_ratio_corrigido,
      total_loans,
      NTILE(4) OVER (ORDER BY age) AS age_quartil,
      NTILE(4) OVER (ORDER BY last_month_salary_limpo) AS salary_quartil,
      NTILE(4) OVER (ORDER BY number_dependents_limpo) AS dependent_quartil,
      NTILE(4) OVER (ORDER BY more_90_days_overdue) AS more_90_days_quartil,
      NTILE(4) OVER (ORDER BY using_lines_corrigida) AS using_lines_quartil,
      NTILE(4) OVER (ORDER BY number_times_delayed_payment_loan_30_59_days) AS delayed_payment_30_59_quartil,
      NTILE(4) OVER (ORDER BY number_times_delayed_payment_loan_60_89_days) AS delayed_payment_60_89_quartil,
      NTILE(4) OVER (ORDER BY debt_ratio_corrigido) AS debt_ratio_quartil,
      NTILE(4) OVER (ORDER BY total_loans) AS total_loans_quartil
    FROM
      `riscorelativo.tabela_final_tratada`
  )
SELECT
  q.user_id,
  q.default_flag,
  q.age,
  q.last_month_salary_limpo,
  q.number_dependents_limpo,
  q.more_90_days_overdue,
  q.using_lines_corrigida,
  q.number_times_delayed_payment_loan_30_59_days,
  q.number_times_delayed_payment_loan_60_89_days,
  q.debt_ratio_corrigido,
  q.total_loans,
  q.age_quartil,
  q.salary_quartil,
  q.dependent_quartil,
  q.more_90_days_quartil,
  q.using_lines_quartil,
  q.delayed_payment_30_59_quartil,
  q.delayed_payment_60_89_quartil,
  q.debt_ratio_quartil,
  q.total_loans_quartil
FROM
  quartis q;

#Consulta para o cálculo risco relativo com mín e máx de cada quartil

WITH Totals AS (
  SELECT
    COUNTIF(default_flag = 1) AS default_1,
    COUNTIF(default_flag = 0) AS default_0
  FROM `riscorelativo.quartis_final`
),
Quartil_Stats AS (
  SELECT
    salary_quartil AS quartil,
    'last_month_salary_limpo' AS variavel,
    MIN(last_month_salary_limpo) AS min_valor,
    MAX(last_month_salary_limpo) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY salary_quartil
  
  UNION ALL
  
  SELECT
    dependent_quartil AS quartil,
    'number_dependents_limpo' AS variavel,
    MIN(number_dependents_limpo) AS min_valor,
    MAX(number_dependents_limpo) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY dependent_quartil

  UNION ALL

  SELECT
    age_quartil AS quartil,
    'age' AS variavel,
    MIN(age) AS min_valor,
    MAX(age) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY age_quartil

  UNION ALL

  SELECT
    more_90_days_quartil AS quartil,
    'more_90_days_overdue' AS variavel,
    MIN(more_90_days_overdue) AS min_valor,
    MAX(more_90_days_overdue) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY more_90_days_quartil

  UNION ALL

  SELECT
    delayed_payment_30_59_quartil AS quartil,
    'number_times_delayed_payment_loan_30_59_days' AS variavel,
    MIN(number_times_delayed_payment_loan_30_59_days) AS min_valor,
    MAX(number_times_delayed_payment_loan_30_59_days) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY delayed_payment_30_59_quartil

  UNION ALL

  SELECT
    delayed_payment_60_89_quartil AS quartil,
    'number_times_delayed_payment_loan_60_89_days' AS variavel,
    MIN(number_times_delayed_payment_loan_60_89_days) AS min_valor,
    MAX(number_times_delayed_payment_loan_60_89_days) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY delayed_payment_60_89_quartil

  UNION ALL

  SELECT
    debt_ratio_quartil AS quartil,
    'debt_ratio_corrigido' AS variavel,
    MIN(debt_ratio_corrigido) AS min_valor,
    MAX(debt_ratio_corrigido) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY debt_ratio_quartil

  UNION ALL

  SELECT
    using_lines_quartil AS quartil,
    'using_lines_corrigida' AS variavel,
    MIN(using_lines_corrigida) AS min_valor,
    MAX(using_lines_corrigida) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY using_lines_quartil

  UNION ALL

  SELECT
    total_loans_quartil AS quartil,
    'total_loans' AS variavel,
    MIN(total_loans) AS min_valor,
    MAX(total_loans) AS max_valor
  FROM `riscorelativo.quartis_final`
  GROUP BY total_loans_quartil
)
SELECT
  q.salary_quartil AS quartil,
  'last_month_salary_limpo' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.salary_quartil = s.quartil AND s.variavel = 'last_month_salary_limpo'
GROUP BY
  q.salary_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.dependent_quartil AS quartil,
  'number_dependents_limpo' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.dependent_quartil = s.quartil AND s.variavel = 'number_dependents_limpo'
GROUP BY
  q.dependent_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.age_quartil AS quartil,
  'age' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.age_quartil = s.quartil AND s.variavel = 'age'
GROUP BY
  q.age_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.more_90_days_quartil AS quartil,
  'more_90_days_overdue' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.more_90_days_quartil = s.quartil AND s.variavel = 'more_90_days_overdue'
GROUP BY
  q.more_90_days_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.delayed_payment_30_59_quartil AS quartil,
  'number_times_delayed_payment_loan_30_59_days' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.delayed_payment_30_59_quartil = s.quartil AND s.variavel = 'number_times_delayed_payment_loan_30_59_days'
GROUP BY
  q.delayed_payment_30_59_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.delayed_payment_60_89_quartil AS quartil,
  'number_times_delayed_payment_loan_60_89_days' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.delayed_payment_60_89_quartil = s.quartil AND s.variavel = 'number_times_delayed_payment_loan_60_89_days'
GROUP BY
  q.delayed_payment_60_89_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.debt_ratio_quartil AS quartil,
  'debt_ratio_corrigido' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.debt_ratio_quartil = s.quartil AND s.variavel = 'debt_ratio_corrigido'
GROUP BY
  q.debt_ratio_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.using_lines_quartil AS quartil,
  'using_lines_corrigida' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.using_lines_quartil = s.quartil AND s.variavel = 'using_lines_corrigida'
GROUP BY
  q.using_lines_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

UNION ALL

SELECT
  q.total_loans_quartil AS quartil,
  'total_loans' AS variavel,
  COUNTIF(q.default_flag = 1) / t.default_1 AS maus_pagadores,
  COUNTIF(q.default_flag = 0) / t.default_0 AS bons_pagadores,
  (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) AS risco_entre_bons_maus,
  CASE
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) > 1 THEN 'Risco maior de ser mal pagador'
    WHEN (COUNTIF(q.default_flag = 1) / t.default_1) / (COUNTIF(q.default_flag = 0) / t.default_0) < 1 THEN 'Risco menor de ser mal pagador'
    ELSE 'Risco indefinido'
  END AS categoria,
  s.min_valor,
  s.max_valor
FROM
  `riscorelativo.quartis_final` q
  JOIN Totals t ON 1=1
  JOIN Quartil_Stats s ON q.total_loans_quartil = s.quartil AND s.variavel = 'total_loans'
GROUP BY
  q.total_loans_quartil, s.variavel, t.default_1, t.default_0, s.min_valor, s.max_valor

  
# Consulta para criação de score
WITH dummy AS (
  SELECT
    user_id,
    default_flag,
    CASE WHEN age_quartil IN (1, 2) THEN 1 ELSE 0 END AS age_dummy,
    CASE WHEN dependent_quartil IN (3, 4) THEN 1 ELSE 0 END AS dependent_dummy,
    CASE WHEN salary_quartil IN (1, 2) THEN 1 ELSE 0 END AS salary_dummy,
    CASE WHEN total_loans_quartil IN (1, 2) THEN 1 ELSE 0 END AS total_loans_dummy,
    CASE WHEN more_90_days_quartil = 4 THEN 1 ELSE 0 END AS more_90_days_dummy,
    CASE WHEN using_lines_quartil = 4 THEN 1 ELSE 0 END AS using_lines_dummy,
    CASE WHEN debt_ratio_quartil IN (3, 4) THEN 1 ELSE 0 END AS debt_ratio_dummy
  FROM
    `projeto03-supercaja.riscorelativo.quartis_final`
),
score_final AS (
  SELECT
    *,
    age_dummy + salary_dummy + total_loans_dummy + more_90_days_dummy + using_lines_dummy + dependent_dummy + debt_ratio_dummy
    AS score
  FROM
    dummy
)
SELECT
  *,
  CASE WHEN score >= 4 THEN 1 ELSE 0 END AS score_0_1
FROM
  score_final; 
