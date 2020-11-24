PGDMP     (                
    x            db_journals    12.5    12.5 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    21639    db_journals    DATABASE     }   CREATE DATABASE db_journals WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'ru_RU.UTF-8' LC_CTYPE = 'ru_RU.UTF-8';
    DROP DATABASE db_journals;
                postgres    false                        2615    21640    pgagent    SCHEMA        CREATE SCHEMA pgagent;
    DROP SCHEMA pgagent;
                postgres    false            �           0    0    SCHEMA pgagent    COMMENT     6   COMMENT ON SCHEMA pgagent IS 'pgAgent system tables';
                   postgres    false    8                        3079    21641    pgagent 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pgagent WITH SCHEMA pgagent;
    DROP EXTENSION pgagent;
                   false    8            �           0    0    EXTENSION pgagent    COMMENT     >   COMMENT ON EXTENSION pgagent IS 'A PostgreSQL job scheduler';
                        false    2                       1255    21812 4   func_check_is_not_technical_field(character varying)    FUNCTION       CREATE FUNCTION public.func_check_is_not_technical_field(column_name character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
begin
	return (case when $1 in (SELECT v.column_name	FROM public.view_technical_column_of_journals v) then FALSE else TRUE end);
end
$_$;
 W   DROP FUNCTION public.func_check_is_not_technical_field(column_name character varying);
       public          postgres    false                       1255    21813 $   func_get_SQL_of_condition_id(bigint)    FUNCTION     �  CREATE FUNCTION public."func_get_SQL_of_condition_id"(id_condition bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
declare result_sql_text character varying;
declare sql_text0 character varying;
declare flag_bool boolean;
declare parents RECORD;
declare childs RECORD;
begin
	-- temp table for calculate dependences of conditions
	CREATE TEMP TABLE conditions (id_condition_src bigint, id_condition_dst bigint, flag_add_not_to_src integer,level_from_the_top integer,sql_text character varying);
	-- define - its group of conditions or atomic
	if (select c.type_condition_aggregate from public._config_conditions c where c.id_condition=$1) is not NULL then
		-- so its group of conditions
		-- calculate dependences for the TOP condition_id = $1
		with recursive conditions_net as
		(	select	n.id_condition_src,n.id_condition_dst,n.flag_add_not_to_src,cast(1 as integer) level_from_the_top
			from	public._config_condition_net n
			where	n.id_condition_dst=$1
			union all
			select	n1.id_condition_src,n1.id_condition_dst,n1.flag_add_not_to_src,n0.level_from_the_top+1
			from	public._config_condition_net n1
					inner join conditions_net n0 on n0.id_condition_src=n1.id_condition_dst		)
		-- all dependences for particular id_condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top
		from 	conditions_net
		union all
		-- add atomic conditions
		select	NULL,id_condition_src,0 flag_add_not_to_src,(select max(level_from_the_top) from conditions_net)+1 level_from_the_top
		from	conditions_net t
		where	not exists (	select	1
						   		from	public._config_condition_net t0
						   		where	t0.id_condition_dst=t.id_condition_src	);
	else
		-- so its not group condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	NULL,c.id_condition,0,1
		from	public._config_conditions c
		where	c.id_condition=$1;
	end if;
	
	-- update all atomic conditions
	update	conditions c
	set		sql_text=(case 
					  	-- condition ALL = always TRUE
					  	when	c0.type_condition_aggregate='ALL' then '(1=1)'
					  	-- atomic conditions
					  	when	c0.analytic_type_compare='EQUAL'	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||']='||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and [id_analytic_'||cast(a.id_analytic as character varying)||'] is not NULL)'
						when	c0.analytic_type_compare='NOT_EQUAL'	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||']<>'||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' or [id_analytic_'||cast(a.id_analytic as character varying)||'] is NULL)'
						when	c0.analytic_type_compare='LIKE'	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||'] like '||''''||c0.analytic_value_text||''''||' and [id_analytic_'||cast(a.id_analytic as character varying)||'] is not NULL)'
						when	c0.analytic_type_compare='NOT_LIKE'	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||'] not like '||''''||c0.analytic_value_text||''''||' or [id_analytic_'||cast(a.id_analytic as character varying)||'] is NULL)'
						when	c0.analytic_type_compare='IN'	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||'] in '||c0.analytic_value_text||' and [id_analytic_'||cast(a.id_analytic as character varying)||'] is not NULL)'
						when	c0.analytic_type_compare='NOT_IN'	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||'] not in '||c0.analytic_value_text||' or [id_analytic_'||cast(a.id_analytic as character varying)||'] is NULL)'
						when	c0.analytic_type_compare in ('>=','>','<=','<')	then 
								'([id_analytic_'||cast(a.id_analytic as character varying)||']'||c0.analytic_type_compare||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and [id_analytic_'||cast(a.id_analytic as character varying)||'] is not NULL)'
					  end)
	from	public._config_conditions c0,
			public._config_analytics a
	where	c0.id_condition=c.id_condition_dst and
			a.id_analytic=c0.id_analytic and
			c.sql_text is NULL and
			(	c0.type_condition_aggregate='ALL' or
				c0.type_condition_aggregate is NULL	);
	
	-- iterate group conditions from bottom to top
	flag_bool=TRUE;	
	-- exists null values of sql_text?
	if (select count(*) from conditions where sql_text is NULL)=0 then
		flag_bool=FALSE;
	end if;		
	-- while NULL values exists
	while	flag_bool loop
		-- aggregate conditions with null sql_text, but all depends already calculated
		for	parents in
			select	distinct c.id_condition_dst,c0.type_condition_aggregate
			from	conditions c
					inner join public._config_conditions c0 on c0.id_condition=c.id_condition_dst
			where	c.sql_text is NULL and 
					c0.type_condition_aggregate is not NULL and
					c0.type_condition_aggregate<>'ALL' and
					not exists (	select	1
									from	conditions c0
									where	c0.id_condition_dst=c.id_condition_src and
											c0.sql_text is NULL	)
		loop
			sql_text0='';
			for	childs in
				select	c0.sql_text,c.flag_add_not_to_src
				from	-- parent
						conditions c
						-- childs
						inner join conditions c0 on c0.id_condition_dst=c.id_condition_src
				where	c.id_condition_dst=parents.id_condition_dst
			loop
				sql_text0=	sql_text0||
							(case when sql_text0='' then '' else ' '||parents.type_condition_aggregate||' ' end)||
							(case when childs.flag_add_not_to_src=1 then 'NOT '||childs.sql_text else childs.sql_text end);
			end loop;
			-- update with sql_text
			update	conditions c
			set		sql_text='('||sql_text0||')'
			where	c.id_condition_dst=parents.id_condition_dst;
		end loop;
		
		-- check: are there conditions with sql_text null? if not, then terminate
		if (select count(*) from conditions where sql_text is NULL)=0 then
			flag_bool=FALSE;
		end if;
	end loop;
	-- get result
	result_sql_text=(select sql_text from conditions where level_from_the_top=1 limit 1);
	-- drop tempory table
	drop table conditions;
	-- return result
	return result_sql_text;
end
$_$;
 J   DROP FUNCTION public."func_get_SQL_of_condition_id"(id_condition bigint);
       public          postgres    false                       1255    21815 8   func_get_SQL_of_condition_id_for_journal(bigint, bigint)    FUNCTION     �  CREATE FUNCTION public."func_get_SQL_of_condition_id_for_journal"(id_condition bigint, id_jur bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
declare result_sql_text character varying;
declare sql_text0 character varying;
declare flag_bool boolean;
declare parents RECORD;
declare childs RECORD;
begin
	-- temp table for calculate dependences of conditions
	CREATE TEMP TABLE conditions (id_condition_src bigint, id_condition_dst bigint, flag_add_not_to_src integer,level_from_the_top integer,sql_text character varying);
	-- define - its group of conditions or atomic
	if (select c.type_condition_aggregate from public._config_conditions c where c.id_condition=$1) is not NULL then
		-- so its group of conditions
		-- calculate dependences for the TOP condition_id = $1
		with recursive conditions_net as
		(	select	n.id_condition_src,n.id_condition_dst,n.flag_add_not_to_src,cast(1 as integer) level_from_the_top
			from	public._config_condition_net n
			where	n.id_condition_dst=$1
			union all
			select	n1.id_condition_src,n1.id_condition_dst,n1.flag_add_not_to_src,n0.level_from_the_top+1
			from	public._config_condition_net n1
					inner join conditions_net n0 on n0.id_condition_src=n1.id_condition_dst		)
		-- all dependences for particular id_condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top
		from 	conditions_net
		union all
		-- add atomic conditions
		select	NULL,id_condition_src,0 flag_add_not_to_src,(select max(level_from_the_top) from conditions_net)+1 level_from_the_top
		from	conditions_net t
		where	not exists (	select	1
						   		from	public._config_condition_net t0
						   		where	t0.id_condition_dst=t.id_condition_src	);
	else
		-- so its not group condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	NULL,c.id_condition,0,1
		from	public._config_conditions c
		where	c.id_condition=$1;
	end if;
	
	-- update all atomic conditions
	update	conditions c
	set		sql_text=(case 
					  	-- condition ALL = always TRUE
					  	when	c0.type_condition_aggregate='ALL' then '(1=1)'
					  	-- atomic conditions
					  	when	c0.analytic_type_compare='EQUAL'	then 
								'('||jc.column_name||'='||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and '||jc.column_name||' is not NULL)'
						when	c0.analytic_type_compare='NOT_EQUAL'	then 
								'('||jc.column_name||'<>'||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' or '||jc.column_name||' is NULL)'
						when	c0.analytic_type_compare='LIKE'	then 
								'('||jc.column_name||' like '||''''||c0.analytic_value_text||''''||' and '||jc.column_name||' is not NULL)'
						when	c0.analytic_type_compare='NOT_LIKE'	then 
								'('||jc.column_name||' not like '||''''||c0.analytic_value_text||''''||' or '||jc.column_name||' is NULL)'
						when	c0.analytic_type_compare='IN'	then 
								'('||jc.column_name||' in '||c0.analytic_value_text||' and '||jc.column_name||' is not NULL)'
						when	c0.analytic_type_compare='NOT_IN'	then 
								'('||jc.column_name||' not in '||c0.analytic_value_text||' or '||jc.column_name||' is NULL)'
						when	c0.analytic_type_compare in ('>=','>','<=','<')	then 
								'('||jc.column_name||c0.analytic_type_compare||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and '||jc.column_name||' is not NULL)'
					  end)
	from	public._config_conditions c0,
			public._config_analytics a,
			public._config_journal_columns jc
	where	c0.id_condition=c.id_condition_dst and
			a.id_analytic=c0.id_analytic and
			jc.id_jur=$2 and 
			jc.id_analytic=a.id_analytic and
			c.sql_text is NULL and
			(	c0.type_condition_aggregate='ALL' or
				c0.type_condition_aggregate is NULL	);
				
	-- for journals who doesnt have some analytics -> replace with condition always TRUE = (1=1)
	update	conditions c
	set		sql_text='(1=1)'
	from	public._config_conditions c0,
			public._config_analytics a
	where	c0.id_condition=c.id_condition_dst and
			a.id_analytic=c0.id_analytic and
			c.sql_text is NULL and
			(	c0.type_condition_aggregate='ALL' or
				c0.type_condition_aggregate is NULL	) and
			-- this analytics dont exists in journal
			not exists (	select 	1
					   		from	public._config_journal_columns jc
					   		where	jc.id_jur=$2 and 
									jc.id_analytic=a.id_analytic	);
						
	-- iterate group conditions from bottom to top
	flag_bool=TRUE;	
	-- exists null values of sql_text?
	if (select count(*) from conditions where sql_text is NULL)=0 then
		flag_bool=FALSE;
	end if;		
	-- while NULL values exists
	while	flag_bool loop
		-- aggregate conditions with null sql_text, but all depends already calculated
		for	parents in
			select	distinct c.id_condition_dst,c0.type_condition_aggregate
			from	conditions c
					inner join public._config_conditions c0 on c0.id_condition=c.id_condition_dst
			where	c.sql_text is NULL and 
					c0.type_condition_aggregate is not NULL and
					c0.type_condition_aggregate<>'ALL' and
					not exists (	select	1
									from	conditions c0
									where	c0.id_condition_dst=c.id_condition_src and
											c0.sql_text is NULL	)
		loop
			sql_text0='';
			for	childs in
				select	c0.sql_text,c.flag_add_not_to_src
				from	-- parent
						conditions c
						-- childs
						inner join conditions c0 on c0.id_condition_dst=c.id_condition_src
				where	c.id_condition_dst=parents.id_condition_dst
			loop
				sql_text0=	sql_text0||
							(case when sql_text0='' then '' else ' '||parents.type_condition_aggregate||' ' end)||
							(case when childs.flag_add_not_to_src=1 then 'NOT '||childs.sql_text else childs.sql_text end);
			end loop;
			-- update with sql_text
			update	conditions c
			set		sql_text='('||sql_text0||')'
			where	c.id_condition_dst=parents.id_condition_dst;
		end loop;
		
		-- check: are there conditions with sql_text null? if not, then terminate
		if (select count(*) from conditions where sql_text is NULL)=0 then
			flag_bool=FALSE;
		end if;
	end loop;
	-- get result
	result_sql_text=(select sql_text from conditions where level_from_the_top=1 limit 1);
	-- drop tempory table
	drop table conditions;
	-- return result
	return result_sql_text;
end
$_$;
 e   DROP FUNCTION public."func_get_SQL_of_condition_id_for_journal"(id_condition bigint, id_jur bigint);
       public          postgres    false                       1255    21817 K   func_get_SQL_of_condition_id_for_journal_for_source(bigint, bigint, bigint)    FUNCTION       CREATE FUNCTION public."func_get_SQL_of_condition_id_for_journal_for_source"(id_condition bigint, id_jur bigint, id_src0 bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
declare result_sql_text character varying;
declare sql_text0 character varying;
declare flag_bool boolean;
declare parents RECORD;
declare childs RECORD;
begin
	-- temp table for calculate dependences of conditions
	CREATE TEMP TABLE conditions (id_condition_src bigint, id_condition_dst bigint, flag_add_not_to_src integer,level_from_the_top integer,sql_text character varying);
	-- define - its group of conditions or atomic
	if (select c.type_condition_aggregate from public._config_conditions c where c.id_condition=$1) is not NULL then
		-- so its group of conditions
		-- calculate dependences for the TOP condition_id = $1
		with recursive conditions_net as
		(	select	n.id_condition_src,n.id_condition_dst,n.flag_add_not_to_src,cast(1 as integer) level_from_the_top
			from	public._config_condition_net n
			where	n.id_condition_dst=$1
			union all
			select	n1.id_condition_src,n1.id_condition_dst,n1.flag_add_not_to_src,n0.level_from_the_top+1
			from	public._config_condition_net n1
					inner join conditions_net n0 on n0.id_condition_src=n1.id_condition_dst		)
		-- all dependences for particular id_condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top
		from 	conditions_net
		union all
		-- add atomic conditions
		select	NULL,id_condition_src,0 flag_add_not_to_src,(select max(level_from_the_top) from conditions_net)+1 level_from_the_top
		from	conditions_net t
		where	not exists (	select	1
						   		from	public._config_condition_net t0
						   		where	t0.id_condition_dst=t.id_condition_src	);
	else
		-- so its not group condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	NULL,c.id_condition,0,1
		from	public._config_conditions c
		where	c.id_condition=$1;
	end if;
	
	-- update all atomic conditions
	update	conditions c
	set		sql_text=(case 
					  	-- condition ALL = always TRUE
					  	when	c0.type_condition_aggregate='ALL' then '(1=1)'
					  	-- atomic conditions
					  	when	c0.analytic_type_compare='EQUAL'	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||'='||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is not NULL)'
						when	c0.analytic_type_compare='NOT_EQUAL'	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||'<>'||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' or '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is NULL)'
						when	c0.analytic_type_compare='LIKE'	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' like '||''''||c0.analytic_value_text||''''||' and '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is not NULL)'
						when	c0.analytic_type_compare='NOT_LIKE'	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' not like '||''''||c0.analytic_value_text||''''||' or '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is NULL)'
						when	c0.analytic_type_compare='IN'	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' in '||c0.analytic_value_text||' and '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is not NULL)'
						when	c0.analytic_type_compare='NOT_IN'	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' not in '||c0.analytic_value_text||' or '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is NULL)'
						when	c0.analytic_type_compare in ('>=','>','<=','<')	then 
								'('||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||c0.analytic_type_compare||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and '||public.func_get_column_name_of_source_by_id_column_of_journal(jc.id_col_jur, id_src0)||' is not NULL)'
					  end)
	from	public._config_conditions c0,
			public._config_analytics a,
			public._config_journal_columns jc
	where	c0.id_condition=c.id_condition_dst and
			a.id_analytic=c0.id_analytic and
			jc.id_jur=$2 and 
			jc.id_analytic=a.id_analytic and
			c.sql_text is NULL and
			(	c0.type_condition_aggregate='ALL' or
				c0.type_condition_aggregate is NULL	);
				
	-- for journals who doesnt have some analytics -> replace with condition always TRUE = (1=1)
	update	conditions c
	set		sql_text='(1=1)'
	from	public._config_conditions c0,
			public._config_analytics a
	where	c0.id_condition=c.id_condition_dst and
			a.id_analytic=c0.id_analytic and
			c.sql_text is NULL and
			(	c0.type_condition_aggregate='ALL' or
				c0.type_condition_aggregate is NULL	) and
			-- this analytics dont exists in journal
			not exists (	select 	1
					   		from	public._config_journal_columns jc
					   		where	jc.id_jur=$2 and 
									jc.id_analytic=a.id_analytic	);
						
	-- iterate group conditions from bottom to top
	flag_bool=TRUE;	
	-- exists null values of sql_text?
	if (select count(*) from conditions where sql_text is NULL)=0 then
		flag_bool=FALSE;
	end if;		
	-- while NULL values exists
	while	flag_bool loop
		-- aggregate conditions with null sql_text, but all depends already calculated
		for	parents in
			select	distinct c.id_condition_dst,c0.type_condition_aggregate
			from	conditions c
					inner join public._config_conditions c0 on c0.id_condition=c.id_condition_dst
			where	c.sql_text is NULL and 
					c0.type_condition_aggregate is not NULL and
					c0.type_condition_aggregate<>'ALL' and
					not exists (	select	1
									from	conditions c0
									where	c0.id_condition_dst=c.id_condition_src and
											c0.sql_text is NULL	)
		loop
			sql_text0='';
			for	childs in
				select	c0.sql_text,c.flag_add_not_to_src
				from	-- parent
						conditions c
						-- childs
						inner join conditions c0 on c0.id_condition_dst=c.id_condition_src
				where	c.id_condition_dst=parents.id_condition_dst
			loop
				sql_text0=	sql_text0||
							(case when sql_text0='' then '' else ' '||parents.type_condition_aggregate||' ' end)||
							(case when childs.flag_add_not_to_src=1 then 'NOT '||childs.sql_text else childs.sql_text end);
			end loop;
			-- update with sql_text
			update	conditions c
			set		sql_text='('||sql_text0||')'
			where	c.id_condition_dst=parents.id_condition_dst;
		end loop;
		
		-- check: are there conditions with sql_text null? if not, then terminate
		if (select count(*) from conditions where sql_text is NULL)=0 then
			flag_bool=FALSE;
		end if;
	end loop;
	-- get result
	result_sql_text=(select sql_text from conditions where level_from_the_top=1 limit 1);
	-- drop tempory table
	drop table conditions;
	-- return result
	return result_sql_text;
end
$_$;
 �   DROP FUNCTION public."func_get_SQL_of_condition_id_for_journal_for_source"(id_condition bigint, id_jur bigint, id_src0 bigint);
       public          postgres    false                       1255    21819 F   func_get_column_name_of_source_by_id_column_of_journal(bigint, bigint)    FUNCTION     �  CREATE FUNCTION public.func_get_column_name_of_source_by_id_column_of_journal(id_col_jur0 bigint, id_src0 bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
begin
	return	(	select	sc.column_name
				from	public._config_journal_column_match_source_column jms
			 			inner join public._config_source_columns sc on sc.id_col_src=jms.id_col_src and sc.id_src=id_src0
				where	jms.id_col_jur=id_col_jur0	);		
end
$$;
 q   DROP FUNCTION public.func_get_column_name_of_source_by_id_column_of_journal(id_col_jur0 bigint, id_src0 bigint);
       public          postgres    false                       1255    21820 ,   func_get_sql_create_journal(bigint, integer)    FUNCTION     s
  CREATE FUNCTION public.func_get_sql_create_journal(id_jur bigint, flag_buffer integer DEFAULT 1) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE tmp_cols character varying DEFAULT '';
--DECLARE tmp_hash_sql character varying DEFAULT '';
DECLARE tmp_tb_name character varying;
DECLARE tmp_result character varying;
DECLARE cols RECORD;
begin
	for cols in 
		select	-- name of journal column with type for create table
				j.column_name||' '||
			(	case 	
				 	when j.id_account is NOT NULL or a1.type_value='float'
			   			then	'float' 
			   		when a1.type_value='string'
			   			then	'character varying' 
			   		when a1.type_value='date'
			   			then	'timestamp' 			   
			   		else 'character varying'
			  	end	) column_name_with_type,
				j.column_name
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1
	loop
		-- list of columns for create table 
		tmp_cols=tmp_cols||(case when tmp_cols='' then '' else ', ' end)||cols.column_name_with_type;
		-- list of columns for HASH md5
		--tmp_hash_sql=tmp_hash_sql||(case when tmp_hash_sql='' then '' else '||' end)||'coalesce(cast('||cols.column_name||' as character varying),''cNULL'')';
	end loop;
	-- journal_name + buffer prefix
	-- if its not buffer table = add additional columns
	tmp_tb_name=(select journal_stage_table_name from public._config_journals j where j.id_jur=$1);		
	--tmp_hash_sql='md5(lower('||tmp_hash_sql||'))';
	-- add cols with references to log of loading journals and id sources
	tmp_cols=tmp_cols||',id_log bigint not null references public._config_journals_log(id_log),id_src bigint not null references public._config_sources(id_src)';
	if $2=0 then
		-- not buffer
		tmp_cols=tmp_cols||',flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references '||tmp_tb_name||'(_pk_num),flag_storno_by_other integer not NULL DEFAULT 0,storned_by_id_log bigint references public._config_journals_log(id_log)';
	else
		-- buffer
		tmp_tb_name=tmp_tb_name||'_buffer';		
	end if;
	-- add create table string
	--tmp_result='create table '||tmp_tb_name||'(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,'||tmp_cols||',hash_key character varying(32) NOT NULL GENERATED ALWAYS AS ('||tmp_cols1||') STORED)';
	tmp_result='create table '||tmp_tb_name||'(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,'||tmp_cols||',hash_key character varying(32) NOT NULL,id_hash_log bigint NOT NULL references public._config_journals_hash_log(id_hash_log))';
	return tmp_result;
end
$_$;
 V   DROP FUNCTION public.func_get_sql_create_journal(id_jur bigint, flag_buffer integer);
       public          postgres    false                       1255    21821    func_get_sql_hash_key(bigint)    FUNCTION     '  CREATE FUNCTION public.func_get_sql_hash_key(id_hash_log0 bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
--DECLARE tmp_cols character varying DEFAULT '';
DECLARE tmp_hash_sql character varying DEFAULT '';
--DECLARE tmp_tb_name character varying;
--DECLARE tmp_result character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE cols RECORD;
begin
	for cols in 
		select	j.column_name
		from	public._config_journal_hash_log_columns j
		where	j.id_hash_log=id_hash_log0
		order by j.order_n
	loop
		-- list of columns for HASH md5
		tmp_hash_sql=tmp_hash_sql||(case when tmp_hash_sql='' then '' else '||' end)||'coalesce(cast('||cols.column_name||' as character varying),''cNULL'')';
	end loop;
	-- add md5
	tmp_hash_sql='md5('||tmp_hash_sql||')';
	return tmp_hash_sql;
end
$$;
 A   DROP FUNCTION public.func_get_sql_hash_key(id_hash_log0 bigint);
       public          postgres    false                       1255    21822 0   func_get_sql_hash_key_for_source(bigint, bigint)    FUNCTION     ^  CREATE FUNCTION public.func_get_sql_hash_key_for_source(id_hash_log0 bigint, id_src0 bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
--DECLARE tmp_cols character varying DEFAULT '';
DECLARE tmp_hash_sql character varying DEFAULT '';
--DECLARE tmp_tb_name character varying;
--DECLARE tmp_result character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE cols RECORD;
begin
	for cols in 
		-- source column
		select	sc.column_name
		from	public._config_journal_hash_log_columns jhc
				inner join public._config_journals_hash_log jhl on jhl.id_hash_log=jhc.id_hash_log
				-- take info about journal columns
				inner join public._config_journal_columns jc on jc.column_name=jhc.column_name and jc.id_jur=jhl.id_jur
				-- link to columns of source
				inner join public._config_journal_column_match_source_column jcm on jcm.id_col_jur=jc.id_col_jur
				-- source columns of particular id_src0
				inner join public._config_source_columns sc on sc.id_col_src=jcm.id_col_src and sc.id_src=id_src0
		where	jhc.id_hash_log=id_hash_log0
		order by jhc.order_n
	loop
		-- list of columns for HASH md5
		tmp_hash_sql=tmp_hash_sql||(case when tmp_hash_sql='' then '' else '||' end)||'coalesce(cast('||cols.column_name||' as character varying),''cNULL'')';
	end loop;
	-- add md5
	tmp_hash_sql='md5('||tmp_hash_sql||')';
	return tmp_hash_sql;
end
$$;
 \   DROP FUNCTION public.func_get_sql_hash_key_for_source(id_hash_log0 bigint, id_src0 bigint);
       public          postgres    false                       1255    21823 2   func_get_sql_insert_buffer(bigint, bigint, bigint)    FUNCTION     >  CREATE FUNCTION public.func_get_sql_insert_buffer(id_jur0 bigint, id_log0 bigint, id_hash_log0 bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE journal_stage_table_name0 character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE sql_list_cols character varying DEFAULT '';
DECLARE id_src_prev bigint;
DECLARE id_condition0 bigint;
DECLARE sql_condition_prev character varying DEFAULT '';
DECLARE db_name_prev character varying DEFAULT '';
DECLARE schema_name_prev character varying DEFAULT '';
DECLARE table_name_prev character varying DEFAULT '';
DECLARE sql_hash_key_prev character varying DEFAULT '';
DECLARE src_cols RECORD;
begin
	-- journal stage table
	journal_stage_table_name0=(select j.journal_stage_table_name from public._config_journals j where j.id_jur=$1);
	-- so, buffer table is
	journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	-- condition_id
	id_condition0=(select c.condition_id from public._config_journals_log c where c.id_log=id_log0);
	-- create list of cols
	/*	loop on all journal columns	*/
	for src_cols in
		select	jc.column_name
		from	public._config_journals j 
				inner join public._config_journal_columns jc on jc.id_jur=j.id_jur
		where	j.id_jur=$1
		order by jc.column_name
	loop
		sql_list_cols=sql_list_cols||(case when sql_list_cols='' then '' else ',' end)||src_cols.column_name;
	end loop;	
	-- add technical columns
	sql_list_cols=sql_list_cols||',id_src,id_log,id_hash_log,hash_key';

	/*	loop on all source columns	*/
	for src_cols in 
		select	s.id_src,
				s.db_name,
				s.schema_name,
				s.table_name,
				sc.column_name column_name_src
		from	-- link columns journal-source
				public._config_journal_column_match_source_column jcm
				-- our journal columns
				inner join public._config_journal_columns jc on jc.id_col_jur=jcm.id_col_jur and jc.id_jur=$1
				-- sources column for journal
				inner join public._config_source_columns sc on sc.id_col_src=jcm.id_col_src
				-- sources 
				inner join public._config_sources s on s.id_src=sc.id_src
		order by s.id_src,jc.column_name
	loop
		-- generate sql to insert sources
		sql_text=sql_text||(	case
									-- it's first row of id_src -> insert into 
									when id_src_prev is NULL then 'insert into '||journal_stage_table_name0||'('||sql_list_cols||') select '||src_cols.column_name_src
									-- it's new row of id_src -> insert into 
									when id_src_prev<>src_cols.id_src then ','||cast(id_src_prev as character varying)||' id_src,'||cast($2 as character varying)||' id_log,'||cast($3 as character varying)||' id_hash_log,'||sql_hash_key_prev||' hash_key from '||db_name_prev||'.'||schema_name_prev||'.'||table_name_prev||' where '||sql_condition_prev||'; insert into '||journal_stage_table_name0||'('||sql_list_cols||') select '||src_cols.column_name_src
									-- other cases
									else ','||src_cols.column_name_src
								end	);			
								
		-- create prev values
		id_src_prev=src_cols.id_src;
		db_name_prev=src_cols.db_name;
		schema_name_prev=src_cols.schema_name;
		table_name_prev=src_cols.table_name;
		sql_hash_key_prev=public.func_get_sql_hash_key_for_source(id_hash_log0, src_cols.id_src);
		-- for conditon NULL replace with full condition 1=1
		sql_condition_prev=coalesce(public."func_get_SQL_of_condition_id_for_journal_for_source"(id_condition0, id_jur0, id_src_prev),'(1=1)');
	end loop;
	-- truncate buffer table first
	sql_text='truncate table '||journal_stage_table_name0||'; '||sql_text;
	-- for the last source we should add technical columns and section from
	sql_text=sql_text||','||cast(src_cols.id_src as character varying)||' id_src,'||cast($2 as character varying)||' id_log,'||cast($3 as character varying)||' id_hash_log,'||sql_hash_key_prev||' hash_key from '||db_name_prev||'.'||schema_name_prev||'.'||table_name_prev||' where '||sql_condition_prev||';';
	
	return sql_text;
end
$_$;
 f   DROP FUNCTION public.func_get_sql_insert_buffer(id_jur0 bigint, id_log0 bigint, id_hash_log0 bigint);
       public          postgres    false                       1255    21824 +   func_get_sql_insert_journal(bigint, bigint)    FUNCTION     L  CREATE FUNCTION public.func_get_sql_insert_journal(id_jur0 bigint, id_log0 bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE journal_stage_table_name0 character varying;
DECLARE journal_stage_table_name0_buffer character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE sql_list_cols character varying DEFAULT '';
DECLARE sql_list_cols_storno character varying DEFAULT '';
DECLARE id_condition0 bigint;
DECLARE sql_condition character varying DEFAULT '';
begin
	-- input parametres
	journal_stage_table_name0=(select j.journal_stage_table_name from public._config_journals j where j.id_jur=$1);
	journal_stage_table_name0_buffer=journal_stage_table_name0||'_buffer';
	id_condition0=(select condition_id from public._config_journals_log where id_log=$2);
	sql_condition=public."func_get_SQL_of_condition_id_for_journal"(id_condition0, $1);
	--sql_condition=replace(sql_condition,'''','''''');
	-- get list of columns
	sql_list_cols=public.func_get_sql_list_columns_of_journal($1,FALSE);
	-- ger list of columns where account values with (-1)*
	sql_list_cols_storno=public.func_get_sql_list_columns_of_journal($1,TRUE);
	
	/*
	raise notice 'journal_stage_table_name0: %',journal_stage_table_name0;
	raise notice 'journal_stage_table_name0_buffer: %',journal_stage_table_name0_buffer;
	raise notice 'id_condition0: %',id_condition0;
	raise notice 'sql_condition: %',sql_condition;
	raise notice 'sql_list_cols: %',sql_list_cols;
	raise notice 'sql_list_cols_storno: %',sql_list_cols_storno;*/
	
	sql_text='-- create temporty tables with hash_key and number
	create temp table tmp_target (_pk_num bigint not null,hash_key character varying(32) not null,rn bigint not null,primary key(hash_key,rn) );
	create temp table tmp_buffer (_pk_num bigint not null,hash_key character varying(32) not null,rn bigint not null,primary key(hash_key,rn) );
	-- indexies of temp tables
	create index ind_target_pk_num on tmp_target(_pk_num);
	create index ind_buffer_pk_num on tmp_buffer(_pk_num);
	
	-- insert data to target
	insert into tmp_target
	select	j._pk_num,j.hash_key,row_number() over(partition by j.hash_key order by j._pk_num) rn
	from	'||journal_stage_table_name0||' j
	where	j.flag_technical_storno=0 and
			j.flag_storno_by_other=0 and
			-- condition from id_log
			'||sql_condition||';
			
	-- insert data from buffer
	insert into tmp_buffer
	select	j._pk_num,j.hash_key,row_number() over(partition by j.hash_key order by j._pk_num) rn
	from	'||journal_stage_table_name0_buffer||' j;
	
	-- update increment journal
	insert into '||journal_stage_table_name0||' ('||sql_list_cols||',flag_technical_storno,_pk_num_link_from_storno,id_log,id_hash_log,hash_key,id_src)
	-- making storno for rows, which are not in buffer
	select	'||sql_list_cols_storno||',1,tt._pk_num,'||cast(id_log0 as character varying)||',j.id_hash_log,j.hash_key,j.id_src
	from	tmp_target tt
			left join '||journal_stage_table_name0||' j on j._pk_num=tt._pk_num
	where	not exists (	select	1
					   		from	tmp_buffer tb
					   		where	tt.hash_key=tb.hash_key and
					   				tt.rn=tb.rn	)
	union all
	-- add new rows
	select	'||sql_list_cols||',0,NULL,'||cast(id_log0 as character varying)||',j.id_hash_log,j.hash_key,j.id_src
	from	tmp_buffer tb
			left join '||journal_stage_table_name0_buffer||' j on j._pk_num=tb._pk_num
	where	not exists (	select	1
					   		from	tmp_target tt
					   		where	tt.hash_key=tb.hash_key and
					   				tt.rn=tb.rn	);									
									
	-- update rows which was storned
	update	'||journal_stage_table_name0||' j
	set		flag_storno_by_other=1,
			storned_by_id_log=j1.id_log
	from	'||journal_stage_table_name0||' j1
	where	j._pk_num=j1._pk_num_link_from_storno and 
			j1.flag_technical_storno=1 and
			j.flag_storno_by_other=0;
			
	drop table tmp_target;
	drop table tmp_buffer;';
	
	--raise notice 'sql_text: %',sql_text;
	-- return result SQL
	return sql_text;
end
$_$;
 R   DROP FUNCTION public.func_get_sql_insert_journal(id_jur0 bigint, id_log0 bigint);
       public          postgres    false                       1255    21825 5   func_get_sql_list_columns_of_journal(bigint, boolean)    FUNCTION     �  CREATE FUNCTION public.func_get_sql_list_columns_of_journal(id_jur bigint, flag_storno boolean DEFAULT false) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
--DECLARE journal_stage_table_name0 varchar(500);
DECLARE tmp_result character varying DEFAULT '';
DECLARE cols RECORD;
begin
	-- stage table of journal
	--journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.id_jur=$1);
	
	for cols in 
		select	(case when a2.id_account is not NULL and flag_storno=TRUE then '(-1)*' else '' end)||j.column_name column_name_new
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1
	loop
		-- list of columns for alter table 
		tmp_result=tmp_result||(case when tmp_result='' then '' else ', ' end)||cols.column_name_new;
	end loop;
	-- return result
	return tmp_result;
end
$_$;
 _   DROP FUNCTION public.func_get_sql_list_columns_of_journal(id_jur bigint, flag_storno boolean);
       public          postgres    false                       1255    21826 )   func_get_sql_new_columns(bigint, integer)    FUNCTION     @  CREATE FUNCTION public.func_get_sql_new_columns(id_jur bigint, flag_buffer integer DEFAULT 1) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE journal_stage_table_name0 varchar(500);
DECLARE tmp_result character varying DEFAULT '';
DECLARE cols RECORD;
begin
	-- stage table of journal
	journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.id_jur=$1);
	-- buffer or journal
	if flag_buffer=1 then
		-- so its buffer, correct name of stage table
		journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	end if;
	
	for cols in 
		select	-- name of journal column with type for create table
				j.column_name||' '||
			(	case 	
				 	when j.id_account is NOT NULL or a1.type_value='float'
			   			then	'float' 
			   		when a1.type_value='string'
			   			then	'character varying' 
			   		when a1.type_value='date'
			   			then	'timestamp' 			   
			   		else 'character varying'
			  	end	) column_name_with_type,
				j.column_name
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1 and
				-- doesnt exists in current table
				not exists	(	select	1
								from	information_schema.columns c
								where	c.column_name=j.column_name and
										c.table_name=journal_stage_table_name0 and
										c.table_schema='public'	)
		union all
		-- add technical columns
		--select * from information_schema.columns
		select	
				j.column_name||' '||
			(	case 	
				 	when j.column_name='_pk_num'
			   			then	'bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key' 
			 		when j.column_name='flag_technical_storno'
			   			then	'integer NOT NULL DEFAULT 0' 
			 		when j.column_name='_pk_num_link_from_storno'
			   			then	'bigint references '||journal_stage_table_name0||'(_pk_num)'			 
			 		when j.column_name='hash_key'
			   			then	'character varying(32) NOT NULL DEFAULT '''''	
			 		when j.column_name='id_hash_log'
			   			then	'bigint references public._config_journals_hash_log(id_hash_log)'				 
			 		when j.column_name='id_log'
			   			then	'bigint references public._config_journals_log(id_log)'
			 		when j.column_name='id_src'
			   			then	'bigint references public._config_sources(id_src)'		
			 		when j.column_name='flag_storno_by_other'
			   			then	'integer not NULL DEFAULT 0'		
			 		when j.column_name='storned_by_id_log'
			   			then	'bigint references public._config_journals_log(id_log)'					 
			  	end	) column_name_with_type,
				j.column_name
		from	(	select	j1.column_name
				 	from	public.view_technical_column_of_journals j1
					where	flag_buffer=0
				 	union all
				 	select	j1.column_name
				 	from	public.view_technical_column_of_journals_buffer j1
					where	flag_buffer=1	) j
		where	-- doesnt exists in current table
				not exists	(	select	1
								from	information_schema.columns c
								where	c.column_name=j.column_name and
										c.table_name=journal_stage_table_name0 and
										c.table_schema='public'	)		
	loop
		-- list of columns for alter table 
		tmp_result=tmp_result||(case when tmp_result='' then '' else '; ' end)||'alter table '||journal_stage_table_name0||' add '||cols.column_name_with_type;
	end loop;
	-- return result
	tmp_result=tmp_result||';';
	return tmp_result;
end
$_$;
 S   DROP FUNCTION public.func_get_sql_new_columns(id_jur bigint, flag_buffer integer);
       public          postgres    false                       1255    21827 6   func_get_table_of_analytic_id_for_condition_id(bigint)    FUNCTION     u  CREATE FUNCTION public.func_get_table_of_analytic_id_for_condition_id(id_condition bigint) RETURNS TABLE(id_analytic bigint)
    LANGUAGE plpgsql
    AS $_$
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
$_$;
 Z   DROP FUNCTION public.func_get_table_of_analytic_id_for_condition_id(id_condition bigint);
       public          postgres    false                       1255    21828 A   sp_check_and_correct_journal(character varying, integer, boolean) 	   PROCEDURE     �  CREATE PROCEDURE public.sp_check_and_correct_journal(journal_name character varying, flag_buffer integer, flag_create_update_journal boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur0 bigint;
DECLARE journal_stage_table_name0 varchar(500);
DECLARE sql_text character varying DEFAULT '';
begin
	/*	CHECK INPUT DATA	*/
	-- check journal_name
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.journal_name=$1);
	-- buffer or journal
	if flag_buffer=1 then
		-- so its buffer, correct name of stage table
		journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	end if;

	if	id_jur0 is NULL then
		-- journal doesnt exists
		if journal_name is NULL then
			raise exception 'Journal_name cant be NULL!';
		else
			raise exception 'Cant find journal ''%'' in config tables!',journal_name;
		end if;
	else
		raise notice 'OK: journal ''%'' was found in config tables.',journal_name;
	end if;
	
	/*	CHECK JOURNALS - Exsists or not	*/
	if 	not exists (	select	1
				  		from	information_schema.tables t
				  		where	t.table_name=journal_stage_table_name0 and
								t.table_schema='public'	)
	then
		-- dont exists table
		raise notice 'INFO: journal ''%'', table ''%'' doesnt exists.',journal_name,journal_stage_table_name0;			
		-- journal doesnt exists
		if flag_create_update_journal then
			-- flag = TRUE
			raise notice 'INFO: the flag_create_update_journal TRUE, so lets create table.';			
			sql_text=(select public.func_get_sql_create_journal(id_jur0, flag_buffer));
			EXECUTE sql_text;
		else
			-- flag = FALSE
			raise exception 'The flag_create_update_journal=FALSE, so we didnt created any journals. Please turn flag to TRUE or create table journal by your own.';			
		end if;
	else
		-- journal exists, lets check that all columns exists also
		if 	-- exists technical columns which are not in table 
			exists (	-- technical columns of journal
						select	v.column_name
						from	public.view_technical_column_of_journals v
						where	flag_buffer=0
						union all
						-- technical columns of buffer of journal
						select	v.column_name
						from	public.view_technical_column_of_journals_buffer v
						where	flag_buffer=1
						except
						select	c.column_name
						from	information_schema.columns c
						where 	c.table_name=journal_stage_table_name0 and c.table_schema='public'	)
			or
			-- exists columns of journal which not in table
			exists	(	select	j.column_name
						from	public._config_journal_columns j
						where	j.id_jur=id_jur0
						except
						select	c.column_name
						from	information_schema.columns c
						where	c.table_name=journal_stage_table_name0 and c.table_schema='public'	) 
		then
		-- exists some columns which are not in table
			raise notice 'INFO: journal ''%'', doesnt have some journal columns in table ''%''.',journal_name,journal_stage_table_name0;
			if flag_create_update_journal then
				-- flag = TRUE, then we should add columns
				raise notice 'INFO: the flag_create_update_journal TRUE, so lets add additional columns.';			
				sql_text=(select public.func_get_sql_new_columns(id_jur0, flag_buffer));
				EXECUTE sql_text;
			else
				-- flag = FALSE, we cant add columns
				raise exception 'The flag_create_update_journal=FALSE, so we didnt created any new columns. Please turn flag to TRUE for append columns automaticaly.';			
			end if;		
		else
		-- OK
			raise notice 'INFO: all columns exists, no errors.';			
		end if;
	end if;
end
$_$;
 �   DROP PROCEDURE public.sp_check_and_correct_journal(journal_name character varying, flag_buffer integer, flag_create_update_journal boolean);
       public          postgres    false                       1255    21829 3   sp_check_columns_journal_srouces(character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.sp_check_columns_journal_srouces(journal_name character varying)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur0 bigint;
DECLARE cols RECORD;
begin
	-- id of journal
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	-- loop for all sources
	for cols in 
		select	distinct 
				s.id_src,
				s.db_name,
				s.schema_name,
				s.table_name
		from	-- link columns journal-source
				public._config_journal_column_match_source_column jcm
				-- our journal columns
				inner join public._config_journal_columns jc on jc.id_col_jur=jcm.id_col_jur and jc.id_jur=id_jur0
				-- sources column for journal
				inner join public._config_source_columns sc on sc.id_col_src=jcm.id_col_src
				-- sources 
				inner join public._config_sources s on s.id_src=sc.id_src
		order by s.id_src
	loop
		-- generate sql to insert sources
		-- check the source id_src: do exists columns of journal without link to source?
		if exists (	select	jc.column_name
				  	from	public._config_journal_columns jc
				   	where	jc.id_jur=id_jur0
				   	except
					select	jc.column_name
					from	public._config_journal_column_match_source_column jcm
							inner join 	public._config_source_columns sc on sc.id_col_src=jcm.id_col_src 
							inner join  public._config_journal_columns jc on jc.id_col_jur=jcm.id_col_jur 
					where	sc.id_src=cols.id_src and
							jc.id_jur=id_jur0	) then
			-- so, there exist columns, which are not full linked to source
			raise exception	'The source id_src=%, table source = %.%.% not full linked to journal ''%'' (some columns of journal didn''t link)',
					cols.id_src,
					cols.db_name,
					cols.schema_name,
					cols.table_name,
					$1;
		else
			raise notice 'OK: the source id_src=%, table source = %.%.% full linked to journal ''%''',
					cols.id_src,
					cols.db_name,
					cols.schema_name,
					cols.table_name,
					$1;
		end if;
	end loop;
end
$_$;
 X   DROP PROCEDURE public.sp_check_columns_journal_srouces(journal_name character varying);
       public          postgres    false                       1255    21830 H   sp_check_create_the_hash_of_journal(character varying, integer, boolean) 	   PROCEDURE     X  CREATE PROCEDURE public.sp_check_create_the_hash_of_journal(journal_name character varying, flag_buffer integer, flag_create_update_journal boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur0 bigint;
DECLARE id_hash_log0 bigint;
DECLARE id_hash_log1 bigint;
DECLARE journal_stage_table_name0 varchar(500);
DECLARE sql_text character varying DEFAULT '';
DECLARE sql_hash_key character varying DEFAULT '';
DECLARE flag_create_hash boolean DEFAULT FALSE;
DECLARE flag_recalculate_hash boolean DEFAULT FALSE;
DECLARE flag_update_hash boolean DEFAULT FALSE;
begin
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.journal_name=$1);
	if flag_buffer=1 then
		-- its buffer, add prefix
		journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	end if;
	-- get the last hash information
	id_hash_log0=(	select	c.id_hash_log
					from	public._config_journals_hash_log c
					where	c.id_jur=id_jur0  and
							insert_timestamp=(	select 	max(c0.insert_timestamp) 
												from 	public._config_journals_hash_log c0
												where	c0.id_jur=c.id_jur	)	);
	if id_hash_log0 is NULL then
		-- so hash doesnt exists
		raise notice 'INFO: hash didnt exists for journal ''%''',journal_name;
		if flag_create_update_journal then
			-- ok, lets create hash
			raise notice 'INFO: the flag_create_update_journal TRUE, so lets create hash.';	
			flag_create_hash=TRUE;
		else
			-- we cant create hash
			raise exception 'The flag_create_update_journal=FALSE, so we didnt created any hash. Please turn flag to TRUE or create hash journal.';			
		end if;
	else
		-- hash exists, lets check columns
		if	-- more columns in journal
			exists (	select	jc.column_name
				   		from	public._config_journal_columns jc
				   		where	jc.id_jur=id_jur0
				   		except
				   		select	jhc.column_name
						from	public._config_journal_hash_log_columns	jhc
				   		where	jhc.id_hash_log=id_hash_log0	) 
			or
			-- more columns in hash
			exists (	select	jhc.column_name
						from	public._config_journal_hash_log_columns	jhc
				   		where	jhc.id_hash_log=id_hash_log0
						except
						select	jc.column_name
				   		from	public._config_journal_columns jc
				   		where	jc.id_jur=id_jur0	) 		then
			-- so exists some extra columns, need to recalculate hash
			raise notice 'INFO: exists some extra columns in journal/hash which are not in hash/journal.';	
			if flag_create_update_journal then
				-- ok, lets recalculate hash
				raise notice 'INFO: the flag_create_update_journal TRUE, so lets recalculate hash.';	
				flag_recalculate_hash=TRUE;
			else
				-- we cant recalculate hash
				raise exception 'The flag_create_update_journal=FALSE, so we didnt recalculate hash. Please turn flag to TRUE or recalculate hash journal.';			
			end if;
		else
			-- ok with hash columns
			-- lets take distinct id_hash_log
			sql_text='select distinct id_hash_log from '||journal_stage_table_name0;
			EXECUTE sql_text INTO id_hash_log1;
			-- lets check that journal hash this id_hash_log of hash
			if 	id_hash_log1 is NULL 
				or
				id_hash_log1<>id_hash_log0 then
				-- so, there are null hash_id or different id_hash_log - strange ... 
				if id_hash_log1 is NULL then
					-- hash is NULL
					raise notice 'INFO: the id_hash_log of journal ''%'' in table ''%'' is NULL.',journal_name,journal_stage_table_name0;	
				else
					-- different
					raise notice 'INFO: the id_hash_log of journal ''%'' in table ''%'' and in hash config are different.',journal_name,journal_stage_table_name0;	
				end if;				
				if flag_create_update_journal or id_hash_log1 is NULL then
					-- ok, lets recalculate hash
					if id_hash_log1 is NULL then
						-- also update hash
						raise notice 'INFO: hash is NULL, lets update.';	
					else
						-- recalculate hash
						raise notice 'INFO: the flag_create_update_journal TRUE, so lets recalculate hash.';	
					end if;										
					flag_update_hash=TRUE;
				else
					-- we cant recalculate hash
					raise exception 'The flag_create_update_journal=FALSE, so we didnt recalculate hash. Please turn flag to TRUE or recalculate hash journal.';			
				end if;

			else
				-- id_hash_log - the same, OK
				raise notice 'OK: the hash is normal';	
			end if;			
		end if;
	end if;
	
	if 	flag_create_hash or 
		flag_recalculate_hash or
		flag_update_hash	then
		-- create hash and recalculate hash here
		-- we need to construct the new seq of columns in hash, store in config, update hash_key for current date in table
		if NOT flag_update_hash then
			-- create new hash id if not only update need
			insert into public._config_journals_hash_log (id_jur,flag_journal_was_updated_by_hash)	select	id_jur0,FALSE;
			-- the last id_hash
			id_hash_log0=(select max(id_hash_log) from public._config_journals_hash_log where id_jur=id_jur0);
			-- insert columns for this hash
			insert into public._config_journal_hash_log_columns (id_hash_log,column_name,order_n)
			select	id_hash_log0,column_name,row_number() over(order by column_name asc) order_n
			from	public._config_journal_columns jc
			where	jc.id_jur=id_jur0;			
		else
			-- need only update, so get current hash id
			-- the last id_hash
			id_hash_log0=(select max(id_hash_log) from public._config_journals_hash_log where id_jur=id_jur0);
		end if;
		-- set hash key string
		sql_hash_key=func_get_sql_hash_key(id_hash_log0);
		-- update hash_key in table
		sql_text='update '||journal_stage_table_name0||' set hash_key='||sql_hash_key;
		-- execute update
		EXECUTE sql_text;
		-- update config hash table that update is done
		if flag_buffer=0 then
			update	_config_journals_hash_log
			set		flag_journal_was_updated_by_hash=TRUE
			where	id_hash_log=id_hash_log0;
		else
			update	_config_journals_hash_log
			set		flag_journal_was_updated_by_hash_buffer=TRUE
			where	id_hash_log=id_hash_log0;		
		end if;
	end if;
end
$_$;
 �   DROP PROCEDURE public.sp_check_create_the_hash_of_journal(journal_name character varying, flag_buffer integer, flag_create_update_journal boolean);
       public          postgres    false                       1255    21832 1   sp_check_the_condition(character varying, bigint) 	   PROCEDURE     #  CREATE PROCEDURE public.sp_check_the_condition(journal_name character varying, id_condition0 bigint)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur0 bigint;
DECLARE sql_text character varying DEFAULT '';
begin
	/*	CHECK INPUT DATA	*/
	-- check journal_name
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	-- check condition_id
	if 	id_condition0 is not null and not exists (select 1 from public._config_conditions c where c.id_condition=id_condition0) then
		-- cant find id condition
		raise exception 'Cant find ID condition ''%''!',id_condition0;
	else
		-- ok
		if id_condition0 is NULL then
			raise notice 'OK: condition is empty, full update journal';
		else
			raise notice 'OK: condition ID ''%'' was found.',id_condition0;
			-- check that columns for this condition_id exists
			if exists (	select 	z.id_analytic
					   	from 	public.func_get_table_of_analytic_id_for_condition_id(id_condition0) z
					  	except
					   	select	distinct j.id_analytic
					   	from	public._config_journal_columns j
					  	where	j.id_jur=id_jur0	) then
				raise exception 'Cant find some analytics of condition ''%'' in journal ''%''!',id_condition0,journal_name;
			else
				raise notice 'OK: all analytic of condition exists in journal';			
			end if;
		end if;
	end if;
end
$_$;
 d   DROP PROCEDURE public.sp_check_the_condition(journal_name character varying, id_condition0 bigint);
       public          postgres    false                       1255    21834 ?   sp_load_data_from_buffer_to_journal(character varying, boolean) 	   PROCEDURE     ~  CREATE PROCEDURE public.sp_load_data_from_buffer_to_journal(journal_name character varying, flag_create_update_journal boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur0 bigint;
DECLARE id_log0 bigint;
DECLARE journal_stage_table_name0 character varying DEFAULT '';
DECLARE sql_text character varying DEFAULT '';
begin
	-- get id_jur of journal by name
	id_jur0=(select j.id_jur from public._config_journals j where j.journal_name=$1);
	-- get stage name of journal
	journal_stage_table_name0=(select j.journal_stage_table_name from public._config_journals j where j.journal_name=$1);
	-- so buffer table is
	journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	-- check and correct journal
	CALL public.sp_check_and_correct_journal(journal_name,0,flag_create_update_journal);
	-- check hash and correct journal
	CALL public.sp_check_create_the_hash_of_journal(journal_name,0,flag_create_update_journal);	
	-- if were no errors, continue
	
	-- the last id_log of buffer table
	sql_text='select distinct id_log from '||journal_stage_table_name0;
	EXECUTE sql_text INTO id_log0;
	-- get sql query to insert buffer
	sql_text=(select public.func_get_sql_insert_journal(id_jur0,id_log0));	
	-- insert into buffer
	EXECUTE sql_text;
	-- update flag when journal was updated
	update	public._config_journals_log
	set		flag_was_loaded_to_journal=TRUE
	where	id_log=id_log0;
end
$_$;
    DROP PROCEDURE public.sp_load_data_from_buffer_to_journal(journal_name character varying, flag_create_update_journal boolean);
       public          postgres    false                       1255    21835 F   sp_load_data_to_the_journal_buffer(character varying, bigint, boolean) 	   PROCEDURE     �  CREATE PROCEDURE public.sp_load_data_to_the_journal_buffer(journal_name character varying, id_condition0 bigint, flag_create_update_journal boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur0 bigint;
DECLARE id_log0 bigint;
DECLARE id_hash_log0 bigint;
DECLARE sql_text character varying DEFAULT '';
begin
	id_jur0=(select j.id_jur from public._config_journals j where j.journal_name=$1);
	-- check and correct journal
	CALL public.sp_check_and_correct_journal(journal_name,0,flag_create_update_journal);
	-- check and correct buffer of journal
	CALL public.sp_check_and_correct_journal(journal_name,1,flag_create_update_journal);
	-- check the condition_id
	CALL public.sp_check_the_condition(journal_name,id_condition0);
	-- need to add some other checks
	-- a) match between source and journal columns (full or not)
	CALL public.sp_check_columns_journal_srouces($1);
	-- b) that source table exists with particular columns
	
	-- check hash and correct buffer of journal
	CALL public.sp_check_create_the_hash_of_journal(journal_name,1,flag_create_update_journal);		
	-- check hash and correct journal
	CALL public.sp_check_create_the_hash_of_journal(journal_name,0,flag_create_update_journal);	
	-- if were no errors, continue
	
	-- insert log entry of loading
	insert into public._config_journals_log (id_jur,condition_id) select id_jur0,id_condition0;
	-- the last id_log of buffer
	id_log0=(select max(id_log) from public._config_journals_log where id_jur=id_jur0);
	-- last id_hash_log of journal
	id_hash_log0=(select max(id_hash_log) from public._config_journals_hash_log where id_jur=id_jur0);
	-- get sql query to insert buffer
	sql_text=(select public.func_get_sql_insert_buffer(id_jur0,id_log0,id_hash_log0));	
	-- insert into buffer
	EXECUTE sql_text;
	-- update flag in log, that buffer was loaded
	update	public._config_journals_log
	set		flag_was_loaded_to_journal_buffer=TRUE
	where	id_log=id_log0;
end
$_$;
 �   DROP PROCEDURE public.sp_load_data_to_the_journal_buffer(journal_name character varying, id_condition0 bigint, flag_create_update_journal boolean);
       public          postgres    false            �            1259    21837    _config_accounts    TABLE     R  CREATE TABLE public._config_accounts (
    id_account bigint NOT NULL,
    finance_type character varying(500) NOT NULL,
    account_description character varying(1000),
    CONSTRAINT ch_config_accounts_finance_type CHECK (((finance_type)::text = ANY (ARRAY[('flow'::character varying)::text, ('reserve'::character varying)::text])))
);
 $   DROP TABLE public._config_accounts;
       public         heap    postgres    false            �           0    0 $   COLUMN _config_accounts.finance_type    COMMENT     \   COMMENT ON COLUMN public._config_accounts.finance_type IS 'Finance type - flow or reserve';
          public          postgres    false    221            �           0    0 +   COLUMN _config_accounts.account_description    COMMENT     [   COMMENT ON COLUMN public._config_accounts.account_description IS 'Description of account';
          public          postgres    false    221            �            1259    21844    _config_accounts_id_account_seq    SEQUENCE     �   ALTER TABLE public._config_accounts ALTER COLUMN id_account ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_accounts_id_account_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    221            �            1259    21846    _config_analytics    TABLE     |  CREATE TABLE public._config_analytics (
    id_analytic bigint NOT NULL,
    analytic_description character varying(2000) NOT NULL,
    type_value character varying(500) NOT NULL,
    CONSTRAINT ck_config_analytics_type_value CHECK (((type_value)::text = ANY (ARRAY[('float'::character varying)::text, ('string'::character varying)::text, ('date'::character varying)::text])))
);
 %   DROP TABLE public._config_analytics;
       public         heap    postgres    false            �           0    0 -   COLUMN _config_analytics.analytic_description    COMMENT     ^   COMMENT ON COLUMN public._config_analytics.analytic_description IS 'Description of analytic';
          public          postgres    false    223            �           0    0 #   COLUMN _config_analytics.type_value    COMMENT     Z   COMMENT ON COLUMN public._config_analytics.type_value IS 'Type value of column analytic';
          public          postgres    false    223            �            1259    21853 !   _config_analytics_id_analytic_seq    SEQUENCE     �   ALTER TABLE public._config_analytics ALTER COLUMN id_analytic ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_analytics_id_analytic_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    223            �            1259    21855    _config_condition_net    TABLE       CREATE TABLE public._config_condition_net (
    id_condition_src bigint NOT NULL,
    id_condition_dst bigint NOT NULL,
    flag_add_not_to_src integer DEFAULT 0 NOT NULL,
    CONSTRAINT ck_config_condition_net_flag CHECK ((flag_add_not_to_src = ANY (ARRAY[0, 1])))
);
 )   DROP TABLE public._config_condition_net;
       public         heap    postgres    false            �           0    0    TABLE _config_condition_net    COMMENT     F   COMMENT ON TABLE public._config_condition_net IS 'Net of conditions';
          public          postgres    false    225            �            1259    21860    _config_conditions    TABLE     �  CREATE TABLE public._config_conditions (
    id_condition bigint NOT NULL,
    condition_name character varying(500) NOT NULL,
    id_analytic bigint,
    analytic_type_compare character varying(10),
    analytic_value_float double precision,
    analytic_value_text character varying(4000),
    type_condition_aggregate character varying(10),
    CONSTRAINT ck_config_condition_consistent CHECK ((((id_analytic IS NULL) AND (type_condition_aggregate IS NOT NULL)) OR ((id_analytic IS NOT NULL) AND (type_condition_aggregate IS NULL) AND (analytic_type_compare IS NOT NULL) AND (((analytic_value_float IS NULL) AND (analytic_value_text IS NOT NULL)) OR ((analytic_value_float IS NOT NULL) AND (analytic_value_text IS NULL)))))),
    CONSTRAINT ck_config_conditions_analytic_type_compare CHECK ((((analytic_type_compare)::text = ANY (ARRAY[('IN'::character varying)::text, ('NOT_IN'::character varying)::text, ('LIKE'::character varying)::text, ('NOT_LIKE'::character varying)::text, ('EQUAL'::character varying)::text, ('NOT_EQUAL'::character varying)::text, ('<='::character varying)::text, ('>='::character varying)::text, ('<'::character varying)::text, ('>'::character varying)::text])) OR (analytic_type_compare IS NULL))),
    CONSTRAINT ck_config_conditions_type_condition_aggregate CHECK ((((type_condition_aggregate)::text = ANY (ARRAY[('OR'::character varying)::text, ('AND'::character varying)::text, ('ALL'::character varying)::text])) OR (type_condition_aggregate IS NULL)))
);
 &   DROP TABLE public._config_conditions;
       public         heap    postgres    false            �           0    0 %   COLUMN _config_conditions.id_analytic    COMMENT     b   COMMENT ON COLUMN public._config_conditions.id_analytic IS 'Analytic which will be in condition';
          public          postgres    false    226                        0    0 2   COLUMN _config_conditions.type_condition_aggregate    COMMENT     j   COMMENT ON COLUMN public._config_conditions.type_condition_aggregate IS 'Type of aggregation conditions';
          public          postgres    false    226            �            1259    21869 #   _config_conditions_id_condition_seq    SEQUENCE     �   ALTER TABLE public._config_conditions ALTER COLUMN id_condition ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_conditions_id_condition_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    226            �            1259    21871 *   _config_journal_column_match_source_column    TABLE     �   CREATE TABLE public._config_journal_column_match_source_column (
    id_col_jur bigint NOT NULL,
    id_col_src bigint NOT NULL
);
 >   DROP TABLE public._config_journal_column_match_source_column;
       public         heap    postgres    false                       0    0 0   TABLE _config_journal_column_match_source_column    COMMENT     c   COMMENT ON TABLE public._config_journal_column_match_source_column IS 'Match journal and sources';
          public          postgres    false    228            �            1259    21874    _config_journal_columns    TABLE     �  CREATE TABLE public._config_journal_columns (
    id_col_jur bigint NOT NULL,
    id_jur bigint NOT NULL,
    column_name character varying(500) NOT NULL,
    id_account bigint,
    id_analytic bigint,
    CONSTRAINT _check_config_journals_column_name_not_tech CHECK (public.func_check_is_not_technical_field(column_name)),
    CONSTRAINT _check_config_journals_id_analytic_account CHECK ((((id_account IS NOT NULL) AND (id_analytic IS NULL)) OR ((id_account IS NULL) AND (id_analytic IS NOT NULL))))
);
 +   DROP TABLE public._config_journal_columns;
       public         heap    postgres    false    257                       0    0    TABLE _config_journal_columns    COMMENT     �   COMMENT ON TABLE public._config_journal_columns IS 'Configuration table: columns of particular journal. Also each column has information about - analytic or account';
          public          postgres    false    229            �            1259    21882 &   _config_journal_columns_id_col_jur_seq    SEQUENCE     �   ALTER TABLE public._config_journal_columns ALTER COLUMN id_col_jur ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journal_columns_id_col_jur_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    229            �            1259    21884     _config_journal_hash_log_columns    TABLE     �   CREATE TABLE public._config_journal_hash_log_columns (
    id_hash_col bigint NOT NULL,
    id_hash_log bigint NOT NULL,
    column_name character varying(500) NOT NULL,
    order_n integer NOT NULL
);
 4   DROP TABLE public._config_journal_hash_log_columns;
       public         heap    postgres    false            �            1259    21890 0   _config_journal_hash_log_columns_id_hash_col_seq    SEQUENCE       ALTER TABLE public._config_journal_hash_log_columns ALTER COLUMN id_hash_col ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journal_hash_log_columns_id_hash_col_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    231            �            1259    21892    _config_journals    TABLE       CREATE TABLE public._config_journals (
    id_jur bigint NOT NULL,
    journal_name character varying(500) NOT NULL,
    journal_stage_table_name character varying(1000) GENERATED ALWAYS AS (('stage_'::text || replace(lower((journal_name)::text), ' '::text, '_'::text))) STORED
);
 $   DROP TABLE public._config_journals;
       public         heap    postgres    false                       0    0    TABLE _config_journals    COMMENT     U   COMMENT ON TABLE public._config_journals IS 'Configuration table: list of journals';
          public          postgres    false    233            �            1259    21899    _config_journals_hash_log    TABLE     �  CREATE TABLE public._config_journals_hash_log (
    id_hash_log bigint NOT NULL,
    id_jur bigint NOT NULL,
    flag_journal_was_updated_by_hash boolean DEFAULT false NOT NULL,
    insert_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    insert_user character varying(200) DEFAULT CURRENT_USER NOT NULL,
    flag_journal_was_updated_by_hash_buffer boolean DEFAULT false NOT NULL
);
 -   DROP TABLE public._config_journals_hash_log;
       public         heap    postgres    false            �            1259    21906 )   _config_journals_hash_log_id_hash_log_seq    SEQUENCE     �   ALTER TABLE public._config_journals_hash_log ALTER COLUMN id_hash_log ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journals_hash_log_id_hash_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    234            �            1259    21908    _config_journals_id_jur_seq    SEQUENCE     �   ALTER TABLE public._config_journals ALTER COLUMN id_jur ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journals_id_jur_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    233            �            1259    21910    _config_journals_log    TABLE     �  CREATE TABLE public._config_journals_log (
    id_log bigint NOT NULL,
    id_jur bigint NOT NULL,
    condition_id bigint,
    insert_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    insert_user character varying(200) DEFAULT CURRENT_USER NOT NULL,
    flag_was_loaded_to_journal_buffer boolean DEFAULT false NOT NULL,
    flag_was_loaded_to_journal boolean DEFAULT false NOT NULL
);
 (   DROP TABLE public._config_journals_log;
       public         heap    postgres    false                       0    0    TABLE _config_journals_log    COMMENT     f   COMMENT ON TABLE public._config_journals_log IS 'Log table of loading data to the buffer of journal';
          public          postgres    false    237                       0    0 (   COLUMN _config_journals_log.condition_id    COMMENT     �   COMMENT ON COLUMN public._config_journals_log.condition_id IS 'Condition to define the massive of data to update (example, period to update)';
          public          postgres    false    237            �            1259    21917    _config_journals_log_id_log_seq    SEQUENCE     �   ALTER TABLE public._config_journals_log ALTER COLUMN id_log ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journals_log_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    237            �            1259    21919    _config_source_columns    TABLE     �   CREATE TABLE public._config_source_columns (
    id_col_src bigint NOT NULL,
    id_src bigint NOT NULL,
    column_name character varying(500) NOT NULL
);
 *   DROP TABLE public._config_source_columns;
       public         heap    postgres    false                       0    0    TABLE _config_source_columns    COMMENT     Y   COMMENT ON TABLE public._config_source_columns IS 'Columns of source data for journals';
          public          postgres    false    239            �            1259    21925 %   _config_source_columns_id_col_src_seq    SEQUENCE     �   ALTER TABLE public._config_source_columns ALTER COLUMN id_col_src ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_source_columns_id_col_src_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    239            �            1259    21927    _config_sources    TABLE     �   CREATE TABLE public._config_sources (
    id_src bigint NOT NULL,
    db_name character varying(500) NOT NULL,
    schema_name character varying(500) NOT NULL,
    table_name character varying(500) NOT NULL
);
 #   DROP TABLE public._config_sources;
       public         heap    postgres    false                       0    0    TABLE _config_sources    COMMENT     >   COMMENT ON TABLE public._config_sources IS 'Sources of data';
          public          postgres    false    241            �            1259    21933    _config_sources_id_src_seq    SEQUENCE     �   ALTER TABLE public._config_sources ALTER COLUMN id_src ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_sources_id_src_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    241            �            1259    21994    stage_insurance_premium_journal    TABLE       CREATE TABLE public.stage_insurance_premium_journal (
    _pk_num bigint NOT NULL,
    date_operation timestamp without time zone,
    id_contract character varying,
    id_risk character varying,
    prem_value double precision,
    id_log bigint NOT NULL,
    id_src bigint NOT NULL,
    flag_technical_storno integer DEFAULT 0 NOT NULL,
    _pk_num_link_from_storno bigint,
    flag_storno_by_other integer DEFAULT 0 NOT NULL,
    storned_by_id_log bigint,
    hash_key character varying(32) NOT NULL,
    id_hash_log bigint NOT NULL
);
 3   DROP TABLE public.stage_insurance_premium_journal;
       public         heap    postgres    false            �            1259    22002 +   stage_insurance_premium_journal__pk_num_seq    SEQUENCE       ALTER TABLE public.stage_insurance_premium_journal ALTER COLUMN _pk_num ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.stage_insurance_premium_journal__pk_num_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    243            �            1259    22004 &   stage_insurance_premium_journal_buffer    TABLE     u  CREATE TABLE public.stage_insurance_premium_journal_buffer (
    _pk_num bigint NOT NULL,
    date_operation timestamp without time zone,
    id_contract character varying,
    id_risk character varying,
    prem_value double precision,
    id_log bigint NOT NULL,
    id_src bigint NOT NULL,
    hash_key character varying(32) NOT NULL,
    id_hash_log bigint NOT NULL
);
 :   DROP TABLE public.stage_insurance_premium_journal_buffer;
       public         heap    postgres    false            �            1259    22010 2   stage_insurance_premium_journal_buffer__pk_num_seq    SEQUENCE       ALTER TABLE public.stage_insurance_premium_journal_buffer ALTER COLUMN _pk_num ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.stage_insurance_premium_journal_buffer__pk_num_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    245            �            1259    22012    test_source_prem_data1    TABLE     �   CREATE TABLE public.test_source_prem_data1 (
    sum_float double precision,
    d_opr date,
    contract_id character varying(500),
    risk_id character varying(500)
);
 *   DROP TABLE public.test_source_prem_data1;
       public         heap    postgres    false            �            1259    22018    test_source_prem_data2    TABLE     �   CREATE TABLE public.test_source_prem_data2 (
    sum_float2 double precision,
    d_opr2 date,
    contract_id2 character varying(500),
    risk_id2 character varying(500)
);
 *   DROP TABLE public.test_source_prem_data2;
       public         heap    postgres    false            �            1259    22024 !   view_technical_column_of_journals    VIEW     !  CREATE VIEW public.view_technical_column_of_journals AS
 SELECT 'flag_technical_storno'::text AS column_name
UNION ALL
 SELECT 'flag_storno_by_other'::text AS column_name
UNION ALL
 SELECT 'storned_by_id_log'::text AS column_name
UNION ALL
 SELECT '_pk_num_link_from_storno'::text AS column_name
UNION ALL
 SELECT 'hash_key'::text AS column_name
UNION ALL
 SELECT 'id_hash_log'::text AS column_name
UNION ALL
 SELECT 'id_log'::text AS column_name
UNION ALL
 SELECT 'id_src'::text AS column_name
UNION ALL
 SELECT '_pk_num'::text AS column_name;
 4   DROP VIEW public.view_technical_column_of_journals;
       public          postgres    false            �            1259    22028 (   view_technical_column_of_journals_buffer    VIEW     .  CREATE VIEW public.view_technical_column_of_journals_buffer AS
 SELECT 'hash_key'::text AS column_name
UNION ALL
 SELECT 'id_hash_log'::text AS column_name
UNION ALL
 SELECT 'id_log'::text AS column_name
UNION ALL
 SELECT 'id_src'::text AS column_name
UNION ALL
 SELECT '_pk_num'::text AS column_name;
 ;   DROP VIEW public.view_technical_column_of_journals_buffer;
       public          postgres    false            �          0    21642    pga_jobagent 
   TABLE DATA           I   COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM stdin;
    pgagent          postgres    false    206   �      �          0    21653    pga_jobclass 
   TABLE DATA           7   COPY pgagent.pga_jobclass (jclid, jclname) FROM stdin;
    pgagent          postgres    false    208   (�      �          0    21665    pga_job 
   TABLE DATA           �   COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM stdin;
    pgagent          postgres    false    210   E�      �          0    21717    pga_schedule 
   TABLE DATA           �   COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM stdin;
    pgagent          postgres    false    214   b�      �          0    21747    pga_exception 
   TABLE DATA           J   COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM stdin;
    pgagent          postgres    false    216   �      �          0    21762 
   pga_joblog 
   TABLE DATA           X   COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM stdin;
    pgagent          postgres    false    218   ��      �          0    21691    pga_jobstep 
   TABLE DATA           �   COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM stdin;
    pgagent          postgres    false    212   ��      �          0    21779    pga_jobsteplog 
   TABLE DATA           |   COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM stdin;
    pgagent          postgres    false    220   ֬      �          0    21837    _config_accounts 
   TABLE DATA           Y   COPY public._config_accounts (id_account, finance_type, account_description) FROM stdin;
    public          postgres    false    221   �      �          0    21846    _config_analytics 
   TABLE DATA           Z   COPY public._config_analytics (id_analytic, analytic_description, type_value) FROM stdin;
    public          postgres    false    223   -�      �          0    21855    _config_condition_net 
   TABLE DATA           h   COPY public._config_condition_net (id_condition_src, id_condition_dst, flag_add_not_to_src) FROM stdin;
    public          postgres    false    225   ��      �          0    21860    _config_conditions 
   TABLE DATA           �   COPY public._config_conditions (id_condition, condition_name, id_analytic, analytic_type_compare, analytic_value_float, analytic_value_text, type_condition_aggregate) FROM stdin;
    public          postgres    false    226   ȭ      �          0    21871 *   _config_journal_column_match_source_column 
   TABLE DATA           \   COPY public._config_journal_column_match_source_column (id_col_jur, id_col_src) FROM stdin;
    public          postgres    false    228   ��      �          0    21874    _config_journal_columns 
   TABLE DATA           k   COPY public._config_journal_columns (id_col_jur, id_jur, column_name, id_account, id_analytic) FROM stdin;
    public          postgres    false    229   ˮ      �          0    21884     _config_journal_hash_log_columns 
   TABLE DATA           j   COPY public._config_journal_hash_log_columns (id_hash_col, id_hash_log, column_name, order_n) FROM stdin;
    public          postgres    false    231   ,�      �          0    21892    _config_journals 
   TABLE DATA           @   COPY public._config_journals (id_jur, journal_name) FROM stdin;
    public          postgres    false    233   ��      �          0    21899    _config_journals_hash_log 
   TABLE DATA           �   COPY public._config_journals_hash_log (id_hash_log, id_jur, flag_journal_was_updated_by_hash, insert_timestamp, insert_user, flag_journal_was_updated_by_hash_buffer) FROM stdin;
    public          postgres    false    234   ��      �          0    21910    _config_journals_log 
   TABLE DATA           �   COPY public._config_journals_log (id_log, id_jur, condition_id, insert_timestamp, insert_user, flag_was_loaded_to_journal_buffer, flag_was_loaded_to_journal) FROM stdin;
    public          postgres    false    237   
�      �          0    21919    _config_source_columns 
   TABLE DATA           Q   COPY public._config_source_columns (id_col_src, id_src, column_name) FROM stdin;
    public          postgres    false    239   j�      �          0    21927    _config_sources 
   TABLE DATA           S   COPY public._config_sources (id_src, db_name, schema_name, table_name) FROM stdin;
    public          postgres    false    241   ϱ      �          0    21994    stage_insurance_premium_journal 
   TABLE DATA           �   COPY public.stage_insurance_premium_journal (_pk_num, date_operation, id_contract, id_risk, prem_value, id_log, id_src, flag_technical_storno, _pk_num_link_from_storno, flag_storno_by_other, storned_by_id_log, hash_key, id_hash_log) FROM stdin;
    public          postgres    false    243   �      �          0    22004 &   stage_insurance_premium_journal_buffer 
   TABLE DATA           �   COPY public.stage_insurance_premium_journal_buffer (_pk_num, date_operation, id_contract, id_risk, prem_value, id_log, id_src, hash_key, id_hash_log) FROM stdin;
    public          postgres    false    245   ?�      �          0    22012    test_source_prem_data1 
   TABLE DATA           X   COPY public.test_source_prem_data1 (sum_float, d_opr, contract_id, risk_id) FROM stdin;
    public          postgres    false    247   7�      �          0    22018    test_source_prem_data2 
   TABLE DATA           \   COPY public.test_source_prem_data2 (sum_float2, d_opr2, contract_id2, risk_id2) FROM stdin;
    public          postgres    false    248   ��                 0    0    _config_accounts_id_account_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public._config_accounts_id_account_seq', 1, true);
          public          postgres    false    222            	           0    0 !   _config_analytics_id_analytic_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public._config_analytics_id_analytic_seq', 4, true);
          public          postgres    false    224            
           0    0 #   _config_conditions_id_condition_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public._config_conditions_id_condition_seq', 8, true);
          public          postgres    false    227                       0    0 &   _config_journal_columns_id_col_jur_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public._config_journal_columns_id_col_jur_seq', 5, true);
          public          postgres    false    230                       0    0 0   _config_journal_hash_log_columns_id_hash_col_seq    SEQUENCE SET     ^   SELECT pg_catalog.setval('public._config_journal_hash_log_columns_id_hash_col_seq', 8, true);
          public          postgres    false    232                       0    0 )   _config_journals_hash_log_id_hash_log_seq    SEQUENCE SET     W   SELECT pg_catalog.setval('public._config_journals_hash_log_id_hash_log_seq', 3, true);
          public          postgres    false    235                       0    0    _config_journals_id_jur_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public._config_journals_id_jur_seq', 1, true);
          public          postgres    false    236                       0    0    _config_journals_log_id_log_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public._config_journals_log_id_log_seq', 36, true);
          public          postgres    false    238                       0    0 %   _config_source_columns_id_col_src_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public._config_source_columns_id_col_src_seq', 8, true);
          public          postgres    false    240                       0    0    _config_sources_id_src_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public._config_sources_id_src_seq', 2, true);
          public          postgres    false    242                       0    0 +   stage_insurance_premium_journal__pk_num_seq    SEQUENCE SET     Z   SELECT pg_catalog.setval('public.stage_insurance_premium_journal__pk_num_seq', 13, true);
          public          postgres    false    244                       0    0 2   stage_insurance_premium_journal_buffer__pk_num_seq    SEQUENCE SET     a   SELECT pg_catalog.setval('public.stage_insurance_premium_journal_buffer__pk_num_seq', 95, true);
          public          postgres    false    246                       2606    22033 $   _config_accounts _config_accounts_pk 
   CONSTRAINT     j   ALTER TABLE ONLY public._config_accounts
    ADD CONSTRAINT _config_accounts_pk PRIMARY KEY (id_account);
 N   ALTER TABLE ONLY public._config_accounts DROP CONSTRAINT _config_accounts_pk;
       public            postgres    false    221                        2606    22035 %   _config_analytics _config_analytic_pk 
   CONSTRAINT     l   ALTER TABLE ONLY public._config_analytics
    ADD CONSTRAINT _config_analytic_pk PRIMARY KEY (id_analytic);
 O   ALTER TABLE ONLY public._config_analytics DROP CONSTRAINT _config_analytic_pk;
       public            postgres    false    223            "           2606    22037 .   _config_condition_net _config_condition_net_pk 
   CONSTRAINT     �   ALTER TABLE ONLY public._config_condition_net
    ADD CONSTRAINT _config_condition_net_pk PRIMARY KEY (id_condition_src, id_condition_dst);
 X   ALTER TABLE ONLY public._config_condition_net DROP CONSTRAINT _config_condition_net_pk;
       public            postgres    false    225    225            $           2606    22039 (   _config_conditions _config_conditions_pk 
   CONSTRAINT     p   ALTER TABLE ONLY public._config_conditions
    ADD CONSTRAINT _config_conditions_pk PRIMARY KEY (id_condition);
 R   ALTER TABLE ONLY public._config_conditions DROP CONSTRAINT _config_conditions_pk;
       public            postgres    false    226            (           2606    22041 2   _config_journal_columns _config_journal_columns_pk 
   CONSTRAINT     x   ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT _config_journal_columns_pk PRIMARY KEY (id_col_jur);
 \   ALTER TABLE ONLY public._config_journal_columns DROP CONSTRAINT _config_journal_columns_pk;
       public            postgres    false    229            ,           2606    22043 D   _config_journal_hash_log_columns _config_journal_hash_log_columns_pk 
   CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_hash_log_columns
    ADD CONSTRAINT _config_journal_hash_log_columns_pk PRIMARY KEY (id_hash_col);
 n   ALTER TABLE ONLY public._config_journal_hash_log_columns DROP CONSTRAINT _config_journal_hash_log_columns_pk;
       public            postgres    false    231            2           2606    22045 6   _config_journals_hash_log _config_journal_hash_logs_pk 
   CONSTRAINT     }   ALTER TABLE ONLY public._config_journals_hash_log
    ADD CONSTRAINT _config_journal_hash_logs_pk PRIMARY KEY (id_hash_log);
 `   ALTER TABLE ONLY public._config_journals_hash_log DROP CONSTRAINT _config_journal_hash_logs_pk;
       public            postgres    false    234            &           2606    22047 J   _config_journal_column_match_source_column _config_journal_match_source_pk 
   CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_column_match_source_column
    ADD CONSTRAINT _config_journal_match_source_pk PRIMARY KEY (id_col_jur, id_col_src);
 t   ALTER TABLE ONLY public._config_journal_column_match_source_column DROP CONSTRAINT _config_journal_match_source_pk;
       public            postgres    false    228    228            6           2606    22049 1   _config_source_columns _config_journal_sources_pk 
   CONSTRAINT     w   ALTER TABLE ONLY public._config_source_columns
    ADD CONSTRAINT _config_journal_sources_pk PRIMARY KEY (id_col_src);
 [   ALTER TABLE ONLY public._config_source_columns DROP CONSTRAINT _config_journal_sources_pk;
       public            postgres    false    239            4           2606    22051 ,   _config_journals_log _config_journals_log_pk 
   CONSTRAINT     n   ALTER TABLE ONLY public._config_journals_log
    ADD CONSTRAINT _config_journals_log_pk PRIMARY KEY (id_log);
 V   ALTER TABLE ONLY public._config_journals_log DROP CONSTRAINT _config_journals_log_pk;
       public            postgres    false    237            .           2606    22053 $   _config_journals _config_journals_pk 
   CONSTRAINT     f   ALTER TABLE ONLY public._config_journals
    ADD CONSTRAINT _config_journals_pk PRIMARY KEY (id_jur);
 N   ALTER TABLE ONLY public._config_journals DROP CONSTRAINT _config_journals_pk;
       public            postgres    false    233            :           2606    22055 "   _config_sources _config_sources_pk 
   CONSTRAINT     d   ALTER TABLE ONLY public._config_sources
    ADD CONSTRAINT _config_sources_pk PRIMARY KEY (id_src);
 L   ALTER TABLE ONLY public._config_sources DROP CONSTRAINT _config_sources_pk;
       public            postgres    false    241            @           2606    22073 R   stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_pkey PRIMARY KEY (_pk_num);
 |   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer DROP CONSTRAINT stage_insurance_premium_journal_buffer_pkey;
       public            postgres    false    245            >           2606    22075 D   stage_insurance_premium_journal stage_insurance_premium_journal_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_pkey PRIMARY KEY (_pk_num);
 n   ALTER TABLE ONLY public.stage_insurance_premium_journal DROP CONSTRAINT stage_insurance_premium_journal_pkey;
       public            postgres    false    243            *           2606    22077 2   _config_journal_columns uq__config_journal_columns 
   CONSTRAINT     |   ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT uq__config_journal_columns UNIQUE (id_jur, column_name);
 \   ALTER TABLE ONLY public._config_journal_columns DROP CONSTRAINT uq__config_journal_columns;
       public            postgres    false    229    229            8           2606    22079 0   _config_source_columns uq__config_source_columns 
   CONSTRAINT     z   ALTER TABLE ONLY public._config_source_columns
    ADD CONSTRAINT uq__config_source_columns UNIQUE (id_src, column_name);
 Z   ALTER TABLE ONLY public._config_source_columns DROP CONSTRAINT uq__config_source_columns;
       public            postgres    false    239    239            <           2606    22081 "   _config_sources uq__config_sources 
   CONSTRAINT     y   ALTER TABLE ONLY public._config_sources
    ADD CONSTRAINT uq__config_sources UNIQUE (db_name, schema_name, table_name);
 L   ALTER TABLE ONLY public._config_sources DROP CONSTRAINT uq__config_sources;
       public            postgres    false    241    241    241            0           2606    22083 #   _config_journals uq_config_journals 
   CONSTRAINT     f   ALTER TABLE ONLY public._config_journals
    ADD CONSTRAINT uq_config_journals UNIQUE (journal_name);
 M   ALTER TABLE ONLY public._config_journals DROP CONSTRAINT uq_config_journals;
       public            postgres    false    233            F           2606    22084 8   _config_journal_columns _config_journal_columns_analytic    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT _config_journal_columns_analytic FOREIGN KEY (id_analytic) REFERENCES public._config_analytics(id_analytic) MATCH FULL;
 b   ALTER TABLE ONLY public._config_journal_columns DROP CONSTRAINT _config_journal_columns_analytic;
       public          postgres    false    3104    223    229            A           2606    22114 1   _config_condition_net fk_config_condition_net_dst    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_condition_net
    ADD CONSTRAINT fk_config_condition_net_dst FOREIGN KEY (id_condition_dst) REFERENCES public._config_conditions(id_condition) MATCH FULL;
 [   ALTER TABLE ONLY public._config_condition_net DROP CONSTRAINT fk_config_condition_net_dst;
       public          postgres    false    3108    226    225            B           2606    22119 1   _config_condition_net fk_config_condition_net_src    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_condition_net
    ADD CONSTRAINT fk_config_condition_net_src FOREIGN KEY (id_condition_src) REFERENCES public._config_conditions(id_condition) MATCH FULL;
 [   ALTER TABLE ONLY public._config_condition_net DROP CONSTRAINT fk_config_condition_net_src;
       public          postgres    false    226    3108    225            C           2606    22124 3   _config_conditions fk_config_conditions_id_analytic    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_conditions
    ADD CONSTRAINT fk_config_conditions_id_analytic FOREIGN KEY (id_analytic) REFERENCES public._config_analytics(id_analytic) MATCH FULL;
 ]   ALTER TABLE ONLY public._config_conditions DROP CONSTRAINT fk_config_conditions_id_analytic;
       public          postgres    false    226    3104    223            G           2606    22129 <   _config_journal_columns fk_config_journal_columns_id_account    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT fk_config_journal_columns_id_account FOREIGN KEY (id_account) REFERENCES public._config_accounts(id_account) MATCH FULL;
 f   ALTER TABLE ONLY public._config_journal_columns DROP CONSTRAINT fk_config_journal_columns_id_account;
       public          postgres    false    3102    229    221            H           2606    22134 8   _config_journal_columns fk_config_journal_columns_id_jur    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT fk_config_journal_columns_id_jur FOREIGN KEY (id_jur) REFERENCES public._config_journals(id_jur) MATCH FULL;
 b   ALTER TABLE ONLY public._config_journal_columns DROP CONSTRAINT fk_config_journal_columns_id_jur;
       public          postgres    false    233    229    3118            I           2606    22139 O   _config_journal_hash_log_columns fk_config_journal_hash_log_columns_id_hash_log    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_hash_log_columns
    ADD CONSTRAINT fk_config_journal_hash_log_columns_id_hash_log FOREIGN KEY (id_hash_log) REFERENCES public._config_journals_hash_log(id_hash_log) MATCH FULL;
 y   ALTER TABLE ONLY public._config_journal_hash_log_columns DROP CONSTRAINT fk_config_journal_hash_log_columns_id_hash_log;
       public          postgres    false    231    234    3122            J           2606    22144 <   _config_journals_hash_log fk_config_journal_hash_logs_id_jur    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journals_hash_log
    ADD CONSTRAINT fk_config_journal_hash_logs_id_jur FOREIGN KEY (id_jur) REFERENCES public._config_journals(id_jur) MATCH FULL;
 f   ALTER TABLE ONLY public._config_journals_hash_log DROP CONSTRAINT fk_config_journal_hash_logs_id_jur;
       public          postgres    false    234    3118    233            D           2606    22149 T   _config_journal_column_match_source_column fk_config_journal_match_source_id_col_jur    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_column_match_source_column
    ADD CONSTRAINT fk_config_journal_match_source_id_col_jur FOREIGN KEY (id_col_jur) REFERENCES public._config_journal_columns(id_col_jur) MATCH FULL;
 ~   ALTER TABLE ONLY public._config_journal_column_match_source_column DROP CONSTRAINT fk_config_journal_match_source_id_col_jur;
       public          postgres    false    228    229    3112            E           2606    22154 T   _config_journal_column_match_source_column fk_config_journal_match_source_id_col_src    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journal_column_match_source_column
    ADD CONSTRAINT fk_config_journal_match_source_id_col_src FOREIGN KEY (id_col_src) REFERENCES public._config_source_columns(id_col_src) MATCH FULL;
 ~   ALTER TABLE ONLY public._config_journal_column_match_source_column DROP CONSTRAINT fk_config_journal_match_source_id_col_src;
       public          postgres    false    3126    228    239            M           2606    22159 7   _config_source_columns fk_config_journal_sources_id_src    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_source_columns
    ADD CONSTRAINT fk_config_journal_sources_id_src FOREIGN KEY (id_src) REFERENCES public._config_sources(id_src) MATCH FULL;
 a   ALTER TABLE ONLY public._config_source_columns DROP CONSTRAINT fk_config_journal_sources_id_src;
       public          postgres    false    3130    239    241            K           2606    22164 8   _config_journals_log fk_config_journals_log_condition_id    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journals_log
    ADD CONSTRAINT fk_config_journals_log_condition_id FOREIGN KEY (condition_id) REFERENCES public._config_conditions(id_condition) MATCH FULL;
 b   ALTER TABLE ONLY public._config_journals_log DROP CONSTRAINT fk_config_journals_log_condition_id;
       public          postgres    false    237    3108    226            L           2606    22169 2   _config_journals_log fk_config_journals_log_id_jur    FK CONSTRAINT     �   ALTER TABLE ONLY public._config_journals_log
    ADD CONSTRAINT fk_config_journals_log_id_jur FOREIGN KEY (id_jur) REFERENCES public._config_journals(id_jur) MATCH FULL;
 \   ALTER TABLE ONLY public._config_journals_log DROP CONSTRAINT fk_config_journals_log_id_jur;
       public          postgres    false    237    3118    233            N           2606    22194 ]   stage_insurance_premium_journal stage_insurance_premium_journal__pk_num_link_from_storno_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal__pk_num_link_from_storno_fkey FOREIGN KEY (_pk_num_link_from_storno) REFERENCES public.stage_insurance_premium_journal(_pk_num);
 �   ALTER TABLE ONLY public.stage_insurance_premium_journal DROP CONSTRAINT stage_insurance_premium_journal__pk_num_link_from_storno_fkey;
       public          postgres    false    243    243    3134            S           2606    22199 ^   stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_id_hash_log_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_id_hash_log_fkey FOREIGN KEY (id_hash_log) REFERENCES public._config_journals_hash_log(id_hash_log);
 �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer DROP CONSTRAINT stage_insurance_premium_journal_buffer_id_hash_log_fkey;
       public          postgres    false    3122    234    245            T           2606    22204 Y   stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_id_log_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_id_log_fkey FOREIGN KEY (id_log) REFERENCES public._config_journals_log(id_log);
 �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer DROP CONSTRAINT stage_insurance_premium_journal_buffer_id_log_fkey;
       public          postgres    false    237    245    3124            U           2606    22209 Y   stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_id_src_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_id_src_fkey FOREIGN KEY (id_src) REFERENCES public._config_sources(id_src);
 �   ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer DROP CONSTRAINT stage_insurance_premium_journal_buffer_id_src_fkey;
       public          postgres    false    245    241    3130            O           2606    22214 P   stage_insurance_premium_journal stage_insurance_premium_journal_id_hash_log_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_id_hash_log_fkey FOREIGN KEY (id_hash_log) REFERENCES public._config_journals_hash_log(id_hash_log);
 z   ALTER TABLE ONLY public.stage_insurance_premium_journal DROP CONSTRAINT stage_insurance_premium_journal_id_hash_log_fkey;
       public          postgres    false    243    234    3122            P           2606    22219 K   stage_insurance_premium_journal stage_insurance_premium_journal_id_log_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_id_log_fkey FOREIGN KEY (id_log) REFERENCES public._config_journals_log(id_log);
 u   ALTER TABLE ONLY public.stage_insurance_premium_journal DROP CONSTRAINT stage_insurance_premium_journal_id_log_fkey;
       public          postgres    false    237    3124    243            Q           2606    22224 K   stage_insurance_premium_journal stage_insurance_premium_journal_id_src_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_id_src_fkey FOREIGN KEY (id_src) REFERENCES public._config_sources(id_src);
 u   ALTER TABLE ONLY public.stage_insurance_premium_journal DROP CONSTRAINT stage_insurance_premium_journal_id_src_fkey;
       public          postgres    false    3130    243    241            R           2606    22229 V   stage_insurance_premium_journal stage_insurance_premium_journal_storned_by_id_log_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_storned_by_id_log_fkey FOREIGN KEY (storned_by_id_log) REFERENCES public._config_journals_log(id_log);
 �   ALTER TABLE ONLY public.stage_insurance_premium_journal DROP CONSTRAINT stage_insurance_premium_journal_storned_by_id_log_fkey;
       public          postgres    false    237    243    3124            �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �   *   x�3�L��/�t/�/.V/�,)I�S(J��,������ �d
�      �   \   x�3�tI,IU�OS�/H-J,����L�pqz��%�%�*$��%&�(x�p�e�s#Ieg#I�p�d恍L*-.2�a21z\\\ �>%�      �      x�3�4�4�2�����@��6�1z\\\ LD2      �   �   x�m���0���_�N���f���LI��e��.���731E����ۗDҖ�*T�RK[�eeK��|�>_���'��qO�;1Ym�x@�6��=�[�5��O	o�N��Zֱ�W
����G1Ͱ�4�4c�%�mF�IĶ�l����[;����]��1�4����JC0d�.o�d�} ��b>      �   )   x�3�4�2�4�2�4�2�4�2�4�́| ߐ+F��� U�y      �   Q   x�3�4�,(J͍/K�)Mrb����TJbIj|~AjQbIf~P�Ӑ�(�����WR��\4�2�eg���b���� M^�      �   L   x�3�4�LI,I��/H-J,����4�2
f��'��%&�pq�CD�2��9��,��������Ĝ�TN�=... J�      �   )   x�3���+.-J�KNU((J��,�U��/-�K������ �m
�      �   9   x�3�4�,�4202�54�50U02�2��22�34��02�,�/.I/J-�,����� �K
�      �   P  x�u��mA�swJ@�-G���k�r�T�.�t����`d|%zEAl�&.���������ϯ��x?y�E[̉�f.[��ʤ3�Wl$(�ĥ:ѓ'k�F����_�i��bADy����H2���O-X^�K���Pl�봵kGZī��K�|4:c�2-Ӯ|4x"��y���5���7\\6\��e��Ǐ��	˿�u`��ۆ��A��ti�w�F�����.�&`�L+��6J�y/�׎וx''��N��z�+"bX�B7� Y�rη<=Ֆ���"��Y���H��Jb7��l�j,�o��H��{|��<� u�c      �   U   x�M��
� �=�]?&XD	�������Po3c�5��yْ�Z�tf�J>����z�e}�7�=�A�����"L�F� 7J       �   =   x�3�LI���/-�K�)�,(M��L�,I-.�/
&����Ƨ$�$r�ֈ+F��� O!U      �     x���MJ�@�u�^ R�U�!<�l�*	��0z�d2�D!���ޫ�D@��@ Oˤx�<���t~�x����	������X3v� �*%���������`k�bc�N?pÂ��MȊ5\�T�h���g����w*�[o8n��q�&��B1�1����a��H�V\z���Ie�O�еYvϣ��2�$�Rh=GXu��ћ�Ӳ�s��:�Uo�XXX-[T��Uk�4��x��w�����`���<�#ݡ�_����H���u���      �   �   x���Kj�@�������^3�z�nF���B��S��٤�%��'� �B@0�@/ o�����^z^�\>~>�p�­`i�D�n�	�.-��]Q&+<��H�{w!�&��;)w�Clʙx�ɔ�O���#��I�YOӰ���т��j̓�]�����)#����Ns�l���:pD��9Kʂ�ԭ����NOh�'��a�w��㗨tl,�V-ݬ%j����/s�ͬ�7�_�a�e�T      �   K   x�340�420��50�50�L��+)JL.1�,�,�6�2�K�\�*m�64@�6Kq�����r�ؤc���� V�!%      �   T   x�3240�4202�50�54�L��+)JL.1�,�,�6�22�����`�fpy]CK��1Xވˈ�����͑�+���� C     