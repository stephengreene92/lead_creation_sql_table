WITH outbound_database AS (
 SELECT
    email,
    created_date,
    account_creation_date,
    account_id_c,
    (CASE WHEN sf.malt_account_id_c IS NOT null THEN true ELSE false END) AS has_converted_into_user,
    owner_id,
    owner_account_id,
    owner_first_name,
    owner_last_name,
    company_id_c,
    user_country_code


 FROM `@sources.leadgen.sf_cold_prospects_and_contacts` AS sf
 WHERE lead_source_type IN ('Outbound')
),

opp_database AS (
 SELECT
   opp.client_account_id AS account_id,
   creation_date AS fpo_at
 FROM  `@sources.opportunity.all_opportunity_business_impact` opp
 LEFT JOIN `@sources.opportunity.all_opportunity_core` AS opp_core USING(opportunity_id)
 WHERE is_first_client_opportunity IS TRUE
),

first_project AS (
 SELECT
   client_account_id AS account_id,
   MIN(proposal_acceptance_date) AS first_project_date
 FROM `@sources.public.all_quotes` AS all_quotes
 WHERE proposal_cancellation_date IS NULL
   AND mission_cancellation_date IS NULL
   AND proposal_acceptance_date IS NOT NULL
  GROUP BY client_account_id
)

SELECT
 email,
 created_date AS lead_creation_date,
 owner_id AS lead_owner_id,
 owner_account_id AS lead_account_id,
 owner_first_name AS lead_owner_first_name,
 owner_last_name AS lead_owner_last_name,
 has_converted_into_user,
 (CASE WHEN fpo_at IS NOT null THEN true ELSE false END) AS has_done_an_opp,
 (CASE WHEN first_project.first_project_date IS NOT null THEN true ELSE false END) AS has_started_project,
 outbound_database.account_creation_date AS account_creation_date,
 outbound_database.account_id_c AS user_account_id,
 fpo_at,
 first_project_date,
 company_id_c AS company_id,
 user_country_code AS country_code,
 business_unit
FROM outbound_database
LEFT JOIN opp_database ON opp_database.account_id = outbound_database.account_id_c
LEFT JOIN first_project ON first_project.account_id = outbound_database.account_id_c
LEFT JOIN `@sources.manager.all_admins` AS ama ON ama.account_id = outbound_database.owner_account_id
WHERE (created_date < account_creation_date OR account_creation_date is null)
