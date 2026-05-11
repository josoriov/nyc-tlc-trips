{% macro is_valid_trip() %}
    pickup_datetime is not null
    and dropoff_datetime is not null
    and pickup_datetime < dropoff_datetime
    and safe_cast(trip_distance as float64) >= 0
    and safe_cast(fare_amount as float64) >= 0
    and {{ safe_int64('passenger_count') }} > 0
{% endmacro %}
