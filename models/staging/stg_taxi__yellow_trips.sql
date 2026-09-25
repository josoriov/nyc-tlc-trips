select
    {{ safe_int64('vendor_id') }} as vendor_id,
    {{ safe_int64('pickup_location_id') }} as pickup_location_id,
    {{ safe_int64('dropoff_location_id') }} as dropoff_location_id,
    pickup_datetime,
    dropoff_datetime,
    {{ safe_int64('passenger_count') }} as passenger_count,
    safe_cast(trip_distance as float64) as trip_distance,
    {{ safe_int64('rate_code') }} as rate_code,
    store_and_fwd_flag,
    {{ safe_int64('payment_type') }} as payment_type,
    safe_cast(fare_amount as float64) as fare_amount,
    safe_cast(extra as float64) as extra_amount,
    safe_cast(mta_tax as float64) as mta_tax,
    safe_cast(tip_amount as float64) as tip_amount,
    safe_cast(tolls_amount as float64) as tolls_amount,
    safe_cast(imp_surcharge as float64) as improvement_surcharge,
    safe_cast(total_amount as float64) as total_amount
from {{ source('taxi', 'yellow_trips') }}
where pickup_datetime >= cast('{{ var("start_date") }}' as timestamp)
  and pickup_datetime < cast('{{ var("end_date") }}' as timestamp)
  and pickup_datetime < dropoff_datetime
  and safe_cast(trip_distance as float64) >= 0
  and safe_cast(fare_amount as float64) >= 0
  and {{ safe_int64('passenger_count') }} > 0
