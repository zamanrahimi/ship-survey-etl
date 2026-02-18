-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv (query only; result is logged in the workflow).
-- The workflow also copies all bronze blobs to the silver container so you see files in ship-silver-data.
-- Storage account placeholder is replaced at run time (e.g. by GitHub Actions) with actual value.

SELECT TOP 5
    survey_id,
    response_date,
    vessel_name,
    vessel_type,
    flag_country,
    crew_size,
    safety_rating,
    satisfaction_rating,
    maintenance_rating,
    port_of_survey
FROM OPENROWSET(
    BULK 'https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data/ship_survey.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;
