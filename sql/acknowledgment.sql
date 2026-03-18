-- ============================================
-- Claims Letter Data Preparation (Acknowledgment)
-- ============================================

-- This query builds a structured dataset for acknowledgment letters
-- combining claim, policy, vehicle, and coverage data

WITH policy_coverage AS (
    SELECT
        PolicyNumber,
        VIN,
        MAX(CASE WHEN CoverageType = 'BI' THEN Limit1 END) AS BI_PerPerson,
        MAX(CASE WHEN CoverageType = 'BI' THEN Limit2 END) AS BI_PerAccident,
        MAX(CASE WHEN CoverageType = 'PD' THEN Limit3 END) AS PD_Limit,
        MAX(CASE WHEN CoverageType = 'COMP' THEN Deductible END) AS COMP_Ded,
        MAX(CASE WHEN CoverageType = 'COLL' THEN Deductible END) AS COLL_Ded
    FROM policy_table
    GROUP BY PolicyNumber, VIN
),

base_claim AS (
    SELECT
        c.ClaimNumber,
        c.PolicyNumber,
        c.LossDate,
        c.InsuredName,
        v.VIN,
        CONCAT(v.Year, ' ', v.Make, ' ', v.Model) AS Vehicle,
        p.BI_PerPerson,
        p.BI_PerAccident,
        p.PD_Limit,
        p.COMP_Ded,
        p.COLL_Ded
    FROM claims_table c
    LEFT JOIN vehicle_table v ON c.ClaimID = v.ClaimID
    LEFT JOIN policy_coverage p 
        ON c.PolicyNumber = p.PolicyNumber AND v.VIN = p.VIN
)

SELECT
    ClaimNumber,
    PolicyNumber,
    InsuredName,
    LossDate,
    Vehicle,
    BI_PerPerson,
    BI_PerAccident,
    PD_Limit,
    COMP_Ded,
    COLL_Ded
FROM base_claim;
