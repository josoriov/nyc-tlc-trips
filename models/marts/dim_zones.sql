with zones as (

    select * from {{ ref('taxi_zone_lookup') }}

)

select
    cast(LocationID as int64) as location_id,
    Borough as borough,
    Zone as zone,
    service_zone
from zones
