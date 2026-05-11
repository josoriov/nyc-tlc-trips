{{
    config(
        materialized='table',
        partition_by={
            "field": "pickup_date",
            "data_type": "date",
            "granularity": "month"
        },
        cluster_by=["pickup_location_id", "payment_type"]
    )
}}

with trips as (

    select * from {{ ref('int_trips__features') }}

),

zones_pickup as (

    select * from {{ ref('dim_zones') }}

),

zones_dropoff as (

    select * from {{ ref('dim_zones') }}

)

select
    {{ dbt_utils.generate_surrogate_key([
        'trips.vendor_id',
        'trips.pickup_datetime',
        'trips.dropoff_datetime',
        'trips.pickup_location_id',
        'trips.dropoff_location_id',
        'trips.fare_amount'
    ]) }} as trip_id,

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
    pz.service_zone as pickup_service_zone,

    -- dropoff zone enrichment
    dz.borough as dropoff_borough,
    dz.zone as dropoff_zone,
    dz.service_zone as dropoff_service_zone

from trips
left join zones_pickup pz
    on trips.pickup_location_id = pz.location_id
left join zones_dropoff dz
    on trips.dropoff_location_id = dz.location_id
