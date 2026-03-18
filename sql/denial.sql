-- ============================================
-- Claims Letter Data Preparation (Denial Letter)
-- ============================================

-- This query builds denial-letter-ready data including
-- claim details, coverage, and dynamically generated policy wording

WITH policy_coverage AS (
    SELECT
        PolicyNumber,
        VIN,
        MAX(CASE WHEN CoverageType = 'BI' THEN Limit1 END) AS BI_PerPerson,
        MAX(CASE WHEN CoverageType = 'BI' THEN Limit2 END) AS BI_PerAccident,
        MAX(CASE WHEN CoverageType = 'PD' THEN Limit3 END) AS PD_Limit,
        MAX(CASE WHEN CoverageType = 'COMP' THEN Deductible END) AS COMP_Ded,
        MAX(CASE WHEN CoverageType = 'COLL' THEN Deductible END) AS COLL_Ded,
        MAX(State) AS State
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
        p.*
    FROM claims_table c
    LEFT JOIN vehicle_table v ON c.ClaimID = v.ClaimID
    LEFT JOIN policy_coverage p 
        ON c.PolicyNumber = p.PolicyNumber AND v.VIN = p.VIN
),

coverage_description AS (
    SELECT *,
        CASE 
            WHEN State = 'CA' THEN
                CONCAT(
                    'Bodily injury liability of $', BI_PerPerson, ' per person / $', BI_PerAccident, ' per accident',
                    ', property damage liability of $', PD_Limit,
                    CASE WHEN COMP_Ded IS NOT NULL THEN CONCAT(', comprehensive deductible $', COMP_Ded) ELSE '' END,
                    CASE WHEN COLL_Ded IS NOT NULL THEN CONCAT(', collision deductible $', COLL_Ded) ELSE '' END
                )
            WHEN State = 'TX' THEN
                CONCAT(
                    'Liability coverage of $', BI_PerPerson, '/', BI_PerAccident,
                    ', property damage $', PD_Limit,
                    CASE WHEN COLL_Ded IS NOT NULL THEN CONCAT(', collision deductible $', COLL_Ded) ELSE '' END
                )
            ELSE
                CONCAT(
                    'Coverage limits: BI ', BI_PerPerson, '/', BI_PerAccident,
                    ', PD ', PD_Limit
                )
        END AS CoverageDescription
    FROM base_claim
)

SELECT
    ClaimNumber,
    PolicyNumber,
    InsuredName,
    LossDate,
    Vehicle,
    CoverageDescription,
    'Denial due to policy terms and coverage limitations.' AS DenialReason
FROM coverage_description;
