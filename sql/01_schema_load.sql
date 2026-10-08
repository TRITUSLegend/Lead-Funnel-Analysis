-- 01_schema_load.sql : raw table + load. Run from the project root:
--   psql -d leadfunnel -f sql/01_schema_load.sql
DROP TABLE IF EXISTS leads_raw CASCADE;
CREATE TABLE leads_raw (
  prospect_id text, lead_number int, lead_origin text, lead_source text,
  do_not_email text, do_not_call text, converted int,
  total_visits numeric, time_on_website_sec int, page_views_per_visit numeric,
  last_activity text, country text, specialization text, how_heard text,
  occupation text, what_matters_most text, search text, magazine text,
  newspaper_article text, x_forums text, newspaper text, digital_ad text,
  through_recommendations text, receive_updates text, tags text, lead_quality text,
  supply_chain_content text, dm_content text, lead_profile text, city text,
  asym_activity_index text, asym_profile_index text, asym_activity_score numeric,
  asym_profile_score numeric, cheque text, free_copy text, last_notable_activity text
);
\copy leads_raw FROM 'Leads.csv' WITH (FORMAT csv, HEADER true)
