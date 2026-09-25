with trips as (

    select
        *,
        date(pickup_datetime) as pickup_date,
        extract(hour from pickup_datetime) as pickup_hour,
        timestamp_diff(dropoff_datetime, pickup_datetime, minute) as trip_duration_min,
        safe_divide(
            trip_distance,
            timestamp_diff(dropoff_datetime, pickup_datetime, second) / 3600.0
        ) as speed_mph,
        extract(dayofweek from pickup_datetime) in (1, 7) as is_weekend,
        extract(hour from pickup_datetime) not between 6 and 20 as is_night,
        pickup_location_id in (1, 132, 138) as is_airport_pickup
    from {{ ref('stg_taxi__yellow_trips') }}
    where timestamp_diff(dropoff_datetime, pickup_datetime, minute) between 1 and 1439

)

select
    farm_fingerprint(to_json_string(struct(
        trips.vendor_id,
        trips.pickup_datetime,
        trips.dropoff_datetime,
        trips.pickup_location_id,
        trips.dropoff_location_id,
        trips.fare_amount
    ))) as trip_id,

    -- dimensions
    trips.vendor_id,
    trips.pickup_location_id,
    trips.dropoff_location_id,
    trips.payment_type,
    trips.rate_code,
    trips.store_and_fwd_flag,

    -- time dimensions
    trips.pickup_date,
    trips.pickup_hour,
    trips.pickup_datetime,
    trips.dropoff_datetime,

    -- measures
    trips.passenger_count,
    trips.trip_distance,
    trips.trip_duration_min,
    trips.speed_mph,

    -- monetary
    trips.fare_amount,
    trips.extra_amount,
    trips.mta_tax,
    trips.tip_amount,
    trips.tolls_amount,
    trips.improvement_surcharge,
    trips.total_amount,

    -- flags
    trips.is_weekend,
    trips.is_night,
    trips.is_airport_pickup,

    -- pickup zone enrichment
    pz.borough as pickup_borough,
    pz.zone as pickup_zone,

    -- dropoff zone enrichment
    dz.borough as dropoff_borough,
    dz.zone as dropoff_zone

from trips
left join {{ ref('dim_zones') }} pz
    on trips.pickup_location_id = pz.location_id
left join {{ ref('dim_zones') }} dz
    on trips.dropoff_location_id = dz.location_id
