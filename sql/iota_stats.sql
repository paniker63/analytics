CREATE MATERIALIZED VIEW iota_stats AS (
  WITH
    bundles AS (SELECT
      tx."bundle" "bundle",
      MAX(tx."timestamp") "timestamp",
      SUM(GREATEST("value" :: NUMERIC, 0)) "value"
      FROM iota tx
      GROUP BY tx."bundle"
      HAVING MAX(tx."lastIndex") + 1 = COUNT(*)
      ),
    bundle_stats AS (SELECT
      DATE_TRUNC('day', TO_TIMESTAMP(bundle."timestamp")) "date",
      COUNT(*) "cnt",
      SUM(bundle."value") "value",
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bundle."value") "med_value"
      FROM bundles bundle
      GROUP BY "date"
      ),
    tx_stats AS (SELECT
      DATE_TRUNC('day', TO_TIMESTAMP(tx."timestamp")) "date",
      SUM(CASE WHEN tx."value" < 0 THEN 1 ELSE 0 END) "from_cnt",
      SUM(CASE WHEN tx."value" > 0 THEN 1 ELSE 0 END) "to_cnt",
      COUNT(DISTINCT tx."address") "addr_cnt"
      FROM iota tx
      INNER JOIN bundles bundle ON tx."bundle" = bundle."bundle"
      GROUP BY "date"
      )
    SELECT
      tx_stats."date" "date",
      bundle_stats."cnt" "cnt",
      bundle_stats."value" "value",
      bundle_stats."med_value" "med_value",
      tx_stats."from_cnt" "from_cnt",
      tx_stats."to_cnt" "to_cnt",
      tx_stats."addr_cnt" "addr_cnt"
    FROM tx_stats
    LEFT JOIN bundle_stats ON tx_stats."date" = bundle_stats."date"
    ORDER BY tx_stats."date"
  ) WITH NO DATA;
