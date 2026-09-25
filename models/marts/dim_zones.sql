select distinct
    safe_cast(zone_id as int64) as location_id,
    borough,
    zone_name as zone
from {{ source('taxi', 'taxi_zones') }}
where safe_cast(zone_id as int64) is not null
