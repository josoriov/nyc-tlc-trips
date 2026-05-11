with trips as (

    select * from {{ ref('stg_taxi__yellow_trips') }}

),

with_duration as (

    select
        *,
        date(pickup_datetime) as pickup_date,
        extract(hour from pickup_datetime) as pickup_hour,
        timestamp_diff(dropoff_datetime, pickup_datetime, minute) as trip_duration_min,
        timestamp_diff(dropoff_datetime, pickup_datetime, second) / 3600.0 as trip_duration_hours
    from trips

),

features as (

    select
        *,
        {{ safe_divide('trip_distance', 'trip_duration_hours') }} as speed_mph,
        extract(dayofweek from pickup_datetime) in (1, 7) as is_weekend,
        extract(hour from pickup_datetime) not between 6 and 20 as is_night,
        pickup_location_id in (1, 132, 138) as is_airport_pickup
    from with_duration
    where trip_duration_min > 0
      and trip_duration_min < 1440

)

select * from features
