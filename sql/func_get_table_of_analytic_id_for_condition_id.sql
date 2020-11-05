-- FUNCTION: public.func_get_table_of_analytic_id_for_condition_id(bigint)

-- DROP FUNCTION public.func_get_table_of_analytic_id_for_condition_id(bigint);

CREATE OR REPLACE FUNCTION public.func_get_table_of_analytic_id_for_condition_id(
	id_condition bigint)
    RETURNS TABLE(id_analytic bigint) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
begin
	return query
	with recursive conditions_net as
	(	select	n.id_condition_src,n.id_condition_dst,n.flag_add_not_to_src,cast(1 as integer) level_from_the_top
		from	public._config_condition_net n
		where	n.id_condition_dst=$1
		union all
		select	n1.id_condition_src,n1.id_condition_dst,n1.flag_add_not_to_src,n0.level_from_the_top+1
		from	public._config_condition_net n1
				inner join conditions_net n0 on n0.id_condition_src=n1.id_condition_dst		)
	select	distinct a.id_analytic
	from
	(	-- all dependences for particular id_condition
		select	id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top
		from 	conditions_net
		union all
		-- add atomic conditions
		select	NULL,id_condition_src,0 flag_add_not_to_src,(select max(level_from_the_top) from conditions_net)+1 level_from_the_top
		from	conditions_net t
		where	not exists (	select	1
								from	public._config_condition_net t0
								where	t0.id_condition_dst=t.id_condition_src	)
		union all
		select	NULL,c.id_condition,0,1
		from	public._config_conditions c
		where	c.id_condition=$1	) c
		inner join public._config_conditions c0 on c0.id_condition=c.id_condition_dst
		inner join public._config_analytics a on a.id_analytic=c0.id_analytic;
end
$BODY$;

ALTER FUNCTION public.func_get_table_of_analytic_id_for_condition_id(bigint)
    OWNER TO postgres;
