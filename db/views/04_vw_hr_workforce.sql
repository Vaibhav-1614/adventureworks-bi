CREATE OR REPLACE VIEW bi.vw_hr_workforce AS
WITH current_department AS (
    SELECT
        edh.business_entity_id,
        edh.department_id,
        edh.start_date,
        edh.end_date
    FROM humanresources.employee_department_history edh
    WHERE edh.end_date IS NULL
),
latest_pay AS (
    SELECT
        eph.business_entity_id,
        eph.rate AS current_pay_rate,
        eph.pay_frequency,
        ROW_NUMBER() OVER (
            PARTITION BY eph.business_entity_id
            ORDER BY eph.rate_change_date DESC
        ) AS rn
    FROM humanresources.employee_pay_history eph
)
SELECT
    e.business_entity_id AS employee_id,
    (p.first_name || ' ' || p.last_name)::text AS full_name,
    e.job_title,
    e.gender,
    d.name AS department_name,
    d.group_name,
    e.hire_date,
    e.birth_date,
    bi.days_between(e.hire_date, CURRENT_DATE) / 365.0 AS tenure_years,
    bi.days_between(e.birth_date, CURRENT_DATE) / 365.0 AS age,
    CASE
        WHEN bi.days_between(e.birth_date, CURRENT_DATE) / 365.0 < 25 THEN '<25'
        WHEN bi.days_between(e.birth_date, CURRENT_DATE) / 365.0 < 35 THEN '25-34'
        WHEN bi.days_between(e.birth_date, CURRENT_DATE) / 365.0 < 45 THEN '35-44'
        WHEN bi.days_between(e.birth_date, CURRENT_DATE) / 365.0 < 55 THEN '45-54'
        ELSE '55+'
    END AS age_band,
    CASE
        WHEN bi.days_between(e.hire_date, CURRENT_DATE) / 365.0 < 1 THEN '<1yr'
        WHEN bi.days_between(e.hire_date, CURRENT_DATE) / 365.0 < 3 THEN '1-3yr'
        WHEN bi.days_between(e.hire_date, CURRENT_DATE) / 365.0 < 5 THEN '3-5yr'
        WHEN bi.days_between(e.hire_date, CURRENT_DATE) / 365.0 < 10 THEN '5-10yr'
        ELSE '10yr+'
    END AS tenure_band,
    lp.current_pay_rate,
    lp.pay_frequency,
    CASE
        WHEN lp.pay_frequency = 1 THEN lp.current_pay_rate * 12
        WHEN lp.pay_frequency = 2 THEN lp.current_pay_rate * 26
        ELSE NULL
    END AS annual_salary,
    CASE
        WHEN (
            CASE
                WHEN lp.pay_frequency = 1 THEN lp.current_pay_rate * 12
                WHEN lp.pay_frequency = 2 THEN lp.current_pay_rate * 26
                ELSE NULL
            END
        ) < 50000 THEN '<50k'
        WHEN (
            CASE
                WHEN lp.pay_frequency = 1 THEN lp.current_pay_rate * 12
                WHEN lp.pay_frequency = 2 THEN lp.current_pay_rate * 26
                ELSE NULL
            END
        ) < 75000 THEN '50-75k'
        WHEN (
            CASE
                WHEN lp.pay_frequency = 1 THEN lp.current_pay_rate * 12
                WHEN lp.pay_frequency = 2 THEN lp.current_pay_rate * 26
                ELSE NULL
            END
        ) < 100000 THEN '75-100k'
        ELSE '100k+'
    END AS salary_band,
    (sp.business_entity_id IS NOT NULL) AS is_salesperson,
    sp.sales_ytd AS ytd_sales,
    sp.sales_quota,
    bi.safe_divide(sp.sales_ytd, NULLIF(sp.sales_quota, 0)) * 100 AS quota_attainment_pct,
    TRUE AS is_current,
    COUNT(*) OVER (PARTITION BY d.department_id) AS dept_headcount,
    AVG(
        CASE
            WHEN lp.pay_frequency = 1 THEN lp.current_pay_rate * 12
            WHEN lp.pay_frequency = 2 THEN lp.current_pay_rate * 26
            ELSE NULL
        END
    ) OVER (PARTITION BY d.department_id) AS dept_avg_salary,
    RANK() OVER (
        PARTITION BY d.department_id
        ORDER BY
            CASE
                WHEN lp.pay_frequency = 1 THEN lp.current_pay_rate * 12
                WHEN lp.pay_frequency = 2 THEN lp.current_pay_rate * 26
                ELSE NULL
            END DESC NULLS LAST
    ) AS dept_salary_rank
FROM humanresources.employee e
JOIN person.person p
  ON p.business_entity_id = e.business_entity_id
JOIN current_department cd
  ON cd.business_entity_id = e.business_entity_id
JOIN humanresources.department d
  ON d.department_id = cd.department_id
LEFT JOIN latest_pay lp
  ON lp.business_entity_id = e.business_entity_id
 AND lp.rn = 1
LEFT JOIN sales.sales_person sp
  ON sp.business_entity_id = e.business_entity_id
ORDER BY d.name, full_name;

COMMENT ON VIEW bi.vw_hr_workforce IS
'Current employee workforce view with demographics, pay, department context, and salesperson metrics.';
