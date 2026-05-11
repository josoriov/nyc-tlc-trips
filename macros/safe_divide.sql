{% macro safe_divide(numerator, denominator) %}
    case
        when {{ denominator }} is null or {{ denominator }} = 0
            then null
        else cast({{ numerator }} as float64) / cast({{ denominator }} as float64)
    end
{% endmacro %}
