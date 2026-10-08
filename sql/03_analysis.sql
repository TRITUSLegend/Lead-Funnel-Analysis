-- 03_analysis.sql : every query that feeds the dashboard / recommendations.
-- North-star metric: Lead-to-Customer conversion rate = SUM(converted) / COUNT(*)

-- Q1 Headline KPIs
SELECT COUNT(*) AS leads, SUM(converted) AS converted,
       ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM leads;

-- Q2 Lead source: volume share vs conversion share (where does value come from?)
WITH t AS (SELECT SUM(converted) AS conv_total, COUNT(*) AS n_total, AVG(converted) AS base FROM leads)
SELECT l.lead_source,
       COUNT(*)                                             AS leads,
       ROUND(100.0*COUNT(*)/t.n_total,1)                    AS pct_of_leads,
       ROUND(100.0*AVG(l.converted),1)                      AS conv_rate_pct,
       ROUND(100.0*SUM(l.converted)/t.conv_total,1)         AS pct_of_conversions,
       ROUND((AVG(l.converted)/t.base)::numeric,2)          AS lift_vs_avg
FROM leads l, t
GROUP BY l.lead_source, t.conv_total, t.n_total, t.base
ORDER BY leads DESC;

-- Q3 Lead origin
SELECT lead_origin, COUNT(*) AS leads, ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM leads GROUP BY lead_origin ORDER BY leads DESC;

-- Q4 Engagement depth. Excludes 'Lead Add Form' (sales-entered, mostly pre-qualified)
--    so web behaviour is not confounded with how the lead was created.
SELECT engagement_band, COUNT(*) AS leads, ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM leads WHERE lead_origin <> 'Lead Add Form'
GROUP BY engagement_band ORDER BY engagement_band;

-- Q5 Last activity (post-contact signal: use for follow-up playbooks, not scoring)
SELECT COALESCE(last_activity,'Unknown') AS last_activity, COUNT(*) AS leads,
       ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM leads GROUP BY 1 HAVING COUNT(*) >= 100 ORDER BY conv_rate_pct DESC;

-- Q6 Profile completeness at capture (occupation, specialization, city, how_heard)
WITH c AS (
  SELECT converted,
         (occupation IS NOT NULL)::int + (specialization IS NOT NULL)::int
       + (city IS NOT NULL)::int + (how_heard IS NOT NULL)::int AS fields_filled
  FROM leads WHERE lead_origin <> 'Lead Add Form')
SELECT fields_filled, COUNT(*) AS leads, ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM c GROUP BY fields_filled ORDER BY fields_filled;

-- Q7 Occupation
SELECT COALESCE(occupation,'Not provided') AS occupation, COUNT(*) AS leads,
       ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM leads GROUP BY 1 HAVING COUNT(*) >= 100 ORDER BY leads DESC;

-- Q8 Email opt-out
SELECT do_not_email, COUNT(*) AS leads, ROUND(100.0*AVG(converted),1) AS conv_rate_pct
FROM leads GROUP BY do_not_email;

-- Q9 Priority score for WEB-ORIGINATED leads (excludes 'Lead Add Form': all 'Reference' and
--    'Welingak Website' leads are sales-entered and ~92-99% convert, which would inflate any score).
--    Uses ONLY signals known at capture / on-site (no sales-assigned fields).
--    Coarse, rule-based, in-sample: directional evidence, not a validated model.
WITH scored AS (
  SELECT lead_number, converted,
    CASE WHEN lead_source IN ('Google','Organic Search') THEN 1
         WHEN lead_source IN ('Olark Chat','Referral Sites') THEN -1 ELSE 0 END
  + CASE engagement_band WHEN '3. 15+ min' THEN 3 WHEN '2. 5-15 min' THEN 1
                         WHEN '1. Under 5 min' THEN -2 ELSE 0 END
  + CASE WHEN occupation = 'Working Professional' THEN 3
         WHEN occupation IS NULL THEN -2 ELSE 0 END
  + CASE WHEN do_not_email THEN -1 ELSE 0 END AS score
  FROM leads WHERE lead_origin <> 'Lead Add Form'),
ranked AS (SELECT *, NTILE(5) OVER (ORDER BY score DESC, lead_number) AS quintile FROM scored),
tot AS (SELECT SUM(converted) AS c FROM ranked)
SELECT quintile AS priority_quintile, COUNT(*) AS leads,
       ROUND(100.0*AVG(converted),1) AS conv_rate_pct, SUM(converted) AS conversions,
       ROUND(100.0*SUM(SUM(converted)) OVER (ORDER BY quintile) / (SELECT c FROM tot),1) AS cum_pct_of_conversions
FROM ranked GROUP BY quintile ORDER BY quintile;

-- Q10 'Hot but not converted': 15+ min on site, web-originated, still open -> follow-up pool
SELECT COUNT(*) AS hot_open_leads
FROM leads WHERE lead_origin <> 'Lead Add Form' AND engagement_band = '3. 15+ min' AND converted = 0;
