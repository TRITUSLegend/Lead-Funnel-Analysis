-- 02_clean_view.sql : one clean view. Fixes the dataset's quirks:
--  * 'Select' is a dropdown placeholder (= not filled in) -> NULL
--  * lead_source has case variants ('google' vs 'Google') and a long tail -> grouped
--  * Fields assigned by sales AFTER contact (lead_quality, tags, last_activity) are kept
--    but flagged, so they are not used to "predict" conversion (outcome leakage).
CREATE OR REPLACE VIEW leads AS
SELECT
  lead_number,
  converted,
  lead_origin,
  CASE
    WHEN lower(lead_source) = 'google'                                  THEN 'Google'
    WHEN lead_source IN ('Direct Traffic','Olark Chat','Organic Search',
                         'Reference','Welingak Website','Referral Sites') THEN lead_source
    WHEN lead_source IS NULL                                            THEN 'Unknown'
    ELSE 'Other'
  END AS lead_source,
  (do_not_email = 'Yes')                              AS do_not_email,
  COALESCE(total_visits, 0)                           AS total_visits,
  time_on_website_sec,
  ROUND(time_on_website_sec / 60.0, 1)                AS time_on_website_min,
  CASE WHEN time_on_website_sec = 0   THEN '0. No site time'
       WHEN time_on_website_sec < 300 THEN '1. Under 5 min'
       WHEN time_on_website_sec < 900 THEN '2. 5-15 min'
       ELSE                                 '3. 15+ min' END AS engagement_band,
  NULLIF(occupation, 'Select')                        AS occupation,
  NULLIF(specialization, 'Select')                    AS specialization,
  NULLIF(city, 'Select')                              AS city,
  NULLIF(how_heard, 'Select')                         AS how_heard,
  last_activity,                                       -- post-contact (sales/engagement)
  NULLIF(lead_quality, 'Select')                      AS lead_quality  -- assigned by sales
FROM leads_raw;
