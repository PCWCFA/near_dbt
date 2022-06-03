{{ config(
  materialized = 'incremental',
  incremental_strategy = 'delete+insert',
  unique_key = 'action_id',
  cluster_by = ['ingested_at::DATE', 'block_timestamp::DATE'],
  tags = ['near','actions','events','functioncall']
) }}

WITH action_events AS (

  SELECT
    *
  FROM
    {{ ref('actions_events') }}
  WHERE
    {{ incremental_load_filter('ingested_at') }}
    AND action_name = 'FunctionCall'
),
decoding AS (
  SELECT
    *,
    action_data :args AS args,
    COALESCE(TRY_PARSE_JSON(TRY_BASE64_DECODE_STRING(args)), TRY_BASE64_DECODE_STRING(args), args) AS args_decoded,
    action_data :deposit :: NUMBER AS deposit,
    action_data :gas :: NUMBER AS attached_gas,
    action_data :method_name :: STRING AS method_name
  FROM
    action_events),
    function_calls AS (
      SELECT
        action_id,
        txn_hash,
        block_timestamp,
        action_name,
        method_name,
        args_decoded AS args,
        deposit,
        attached_gas,
        ingested_at
      FROM
        decoding
    )
  SELECT
    *
  FROM
    function_calls
