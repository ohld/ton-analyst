-- created with github.com/ohld/ton-analyst
-- Estimate Telegram trading-bot adoption from inbound TON fee messages.
-- Volume is inferred from fee / fee_rate; validate fee_rate per bot.

WITH bot_fee_rules(
    bot_name,
    fee_receiver,
    fee_rate,
    memo_pattern,
    exclude_source
) AS (
    VALUES
        ('DTrade', '0:93C1B918FA90EAC774C9BBEFF0E49742B4BFAC15D49E289A43351782C59A650C', 0.01, '.*dtrade.*', NULL),
        ('blum', '0:57B6B44279BCA07733E47432309A88F9BE5717C21DA8471B7FBB42BA614C6F10', 0.01, '^blumtradingbotfee.*', NULL),
        ('grim', '0:55D457ED7CCEE033A4448A3E1B2FA02FED3AA7F3DE889B3B32B55806ECCDAEB6', 0.01, '^grim fee.*', NULL),
        ('sky', '0:1349FED64609A6CEDBC447A26FEFECB47C5AECBB7823F4957DBA19A8765CA6D0', 0.01, '.*skybotfee.*', NULL),
        ('stonks', '0:EF7BA08B55B69A5D04DDE78808F972BC891EB74AC69281CA1167D6F2B9215D6A', 0.01, '.*stonks trading bot.*', '0:FCCFDAAEB90C7BB38C01C11DF67D48492FE0888548936D50290753C0084C1815'),
        ('redo', '0:3E46DC22DEE14AB40E8C8B2762EC02B06ED069AAF0AC2E93AEFD3A800096B8ED', 0.01, '.*redotrade.*', NULL),
        ('not.trade', '0:AF0FB80FDDBD109FD60CCF33D1D16EF10FEBA2E2A43D52841639D61E78A56DAA', 0.01, '.*not\\.trade fee.*', NULL),
        ('groyp', '0:EEE00893FFF24ABAA4F46678DED11A1721030F723E2E20661999EDD42B884594', 0.01, '.*groypfi.*', NULL),
        ('swapi', '0:6111D8D14F76C2E457D243BAF4B68FBEBFA840EE24C73297ADAD8E182319931F', 0.01, NULL, NULL),
        ('pocketfi', '0:C6EB305FC719924FB3DDF902019DA2F6FFA27E52362A1F9FE8F36F6949AB7F69', 0.01, NULL, NULL),
        ('maestro', '0:64E01810BD9F3386508F91DB5F282E9B5D3C49BF0B20BB2FA9FBB121ECAE6F43', 0.01, NULL, NULL),
        ('x1000', '0:72F8D9C820908BC590D107D6D0D7E0C913093D236BB511F8A325D52270E344C9', 0.006, NULL, NULL),
        ('tontrade', '0:7E986176EE53922BA2F409B4E931A30F3BEF55341CCBB3BBD69330F8389C9936', 0.01, NULL, NULL),
        ('tontrade', '0:FAC33F54A4F627F3E3B75E260730DF79AA54FD6B1686BF1826057710FAB916A9', 0.01, NULL, NULL),
        ('tontrade', '0:3899FAD5E3938422E4F224A0D07B8D455F55F45C3F083C9F5461BED3A6EDE02B', 0.01, NULL, NULL),
        ('tontrade', '0:6E8B42DB2D1A3DB04930C620E2C7F79098E8955CABD5DDFD49C1C4A51DA7EA27', 0.01, NULL, NULL)
),

fee_messages AS (
    SELECT
        DATE_TRUNC('day', m.block_time) AS date,
        r.bot_name,
        m.source AS trader_address,
        m.value AS fee_raw,
        r.fee_rate
    FROM ton.messages m
    JOIN bot_fee_rules r
      ON m.destination = r.fee_receiver
    WHERE m.block_date >= CURRENT_DATE - INTERVAL '6' MONTH
      AND m.block_time >= CURRENT_DATE - INTERVAL '6' MONTH
      AND m.block_time < CURRENT_DATE
      AND m.direction = 'in'
      AND NOT m.bounced
      AND (r.memo_pattern IS NULL OR regexp_like(lower(coalesce(m.comment, '')), r.memo_pattern))
      AND (r.exclude_source IS NULL OR m.source <> r.exclude_source)
)

SELECT
    date,
    bot_name,
    TRY_CAST(SUM(fee_raw) / 1e9 AS DECIMAL(18, 9)) AS fee_ton,
    TRY_CAST(SUM(fee_raw / fee_rate) / 1e9 AS DECIMAL(38, 9)) AS inferred_volume_ton,
    COUNT(*) AS daily_fee_messages,
    COUNT(DISTINCT trader_address) AS daily_unique_fee_payers
FROM fee_messages
GROUP BY 1, 2
ORDER BY date DESC, inferred_volume_ton DESC;
