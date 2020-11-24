-- FUNCTION: public.func_check_is_not_technical_field(character varying)

-- DROP FUNCTION public.func_check_is_not_technical_field(character varying);

CREATE OR REPLACE FUNCTION public.func_check_is_not_technical_field(
	column_name character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
begin
	return (case when $1 in (SELECT v.column_name	FROM public.view_technical_column_of_journals v) then FALSE else TRUE end);
end
$BODY$;

ALTER FUNCTION public.func_check_is_not_technical_field(character varying)
    OWNER TO postgres;
