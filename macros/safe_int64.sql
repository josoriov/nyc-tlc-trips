{% macro safe_int64(column_name) %}
    safe_cast(
        regexp_replace(trim(cast({{ column_name }} as string)), r'\.0+$', '')
        as int64
    )
{% endmacro %}
