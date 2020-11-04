--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

-- Started on 2020-11-04 14:01:51 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 258 (class 1255 OID 17548)
-- Name: func_get_SQL_of_condition_id(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."func_get_SQL_of_condition_id"(id_condition bigint) RETURNS character varying
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


ALTER FUNCTION public."func_get_SQL_of_condition_id"(id_condition bigint) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 18350)
-- Name: func_get_SQL_of_condition_id_for_journal(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."func_get_SQL_of_condition_id_for_journal"(id_condition bigint, id_jur bigint) RETURNS character varying
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


ALTER FUNCTION public."func_get_SQL_of_condition_id_for_journal"(id_condition bigint, id_jur bigint) OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 19390)
-- Name: func_get_sql_create_journal(bigint, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.func_get_sql_create_journal(id_jur bigint, flag_buffer integer DEFAULT 1) RETURNS character varying
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
		tmp_cols=tmp_cols||',flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references '||tmp_tb_name||'(_pk_num)';
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


ALTER FUNCTION public.func_get_sql_create_journal(id_jur bigint, flag_buffer integer) OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 18294)
-- Name: func_get_table_of_analytic_id_for_condition_id(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.func_get_table_of_analytic_id_for_condition_id(id_condition bigint) RETURNS TABLE(id_analytic bigint)
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


ALTER FUNCTION public.func_get_table_of_analytic_id_for_condition_id(id_condition bigint) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 18291)
-- Name: sp_load_data_to_the_journal_buffer(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_load_data_to_the_journal_buffer()
    LANGUAGE plpgsql
    AS $$
begin
end
$$;


ALTER PROCEDURE public.sp_load_data_to_the_journal_buffer() OWNER TO postgres;

--
-- TOC entry 3170 (class 0 OID 0)
-- Dependencies: 244
-- Name: PROCEDURE sp_load_data_to_the_journal_buffer(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.sp_load_data_to_the_journal_buffer() IS 'This procedure runs scripts to fill journal buffer table from sources. Part of sources to load configured by condition_id.';


--
-- TOC entry 257 (class 1255 OID 18292)
-- Name: sp_load_data_to_the_journal_buffer(character varying, bigint); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_load_data_to_the_journal_buffer(journal_name character varying, id_condition bigint)
    LANGUAGE plpgsql
    AS $_$
DECLARE id_jur bigint;
begin
	-- check journal_name
	id_jur=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	if	id_jur is NULL then
		-- journal doesnt exists
		if journal_name is NULL then
			raise exception 'Journal_name cant be NULL!';
		else
			raise exception 'Cant find journal ''%'' in config tables!',journal_name;
		end if;
	else
		raise notice 'OK: journal ''%'' was found in config tables.',journal_name;
	end if;
	-- check conditio_id
	if 	id_condition is not null and not exists (select 1 from public._config_conditions c where c.id_condition=$2) then
		-- cant find id condition
		raise exception 'Cant find ID condition ''%''!',id_condition;
	else
		-- ok
		if id_condition is NULL then
			raise notice 'OK: condition is empty, full update journal';
		else
			raise notice 'OK: condition ID ''%'' was found.',id_condition;
			-- check that columns for this condition_id exists
			if exists (	select 	z.id_analytic
					   	from 	public.func_get_table_of_analytic_id_for_condition_id($2) z
					  	except
					   	select	distinct j.id_analytic
					   	from	public._config_journal_columns j	  ) then
				raise exception 'Cant find some analytics of condition ''%'' in journal ''%''!',id_condition,journal_name;
			else
				raise notice 'OK: all analytic of condition exists in journal';			
			end if;
		end if;
	end if;
end
$_$;


ALTER PROCEDURE public.sp_load_data_to_the_journal_buffer(journal_name character varying, id_condition bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 17198)
-- Name: _config_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_accounts (
    id_account bigint NOT NULL,
    finance_type character varying(500) NOT NULL,
    account_description character varying(1000),
    CONSTRAINT ch_config_accounts_finance_type CHECK (((finance_type)::text = ANY ((ARRAY['flow'::character varying, 'reserve'::character varying])::text[])))
);


ALTER TABLE public._config_accounts OWNER TO postgres;

--
-- TOC entry 3171 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN _config_accounts.finance_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_accounts.finance_type IS 'Finance type - flow or reserve';


--
-- TOC entry 3172 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN _config_accounts.account_description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_accounts.account_description IS 'Description of account';


--
-- TOC entry 220 (class 1259 OID 17196)
-- Name: _config_accounts_id_account_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_accounts ALTER COLUMN id_account ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_accounts_id_account_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 17211)
-- Name: _config_analytics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_analytics (
    id_analytic bigint NOT NULL,
    analytic_description character varying(2000) NOT NULL,
    type_value character varying(500) NOT NULL,
    CONSTRAINT ck_config_analytics_type_value CHECK (((type_value)::text = ANY ((ARRAY['float'::character varying, 'string'::character varying, 'date'::character varying])::text[])))
);


ALTER TABLE public._config_analytics OWNER TO postgres;

--
-- TOC entry 3173 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN _config_analytics.analytic_description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_analytics.analytic_description IS 'Description of analytic';


--
-- TOC entry 3174 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN _config_analytics.type_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_analytics.type_value IS 'Type value of column analytic';


--
-- TOC entry 222 (class 1259 OID 17209)
-- Name: _config_analytics_id_analytic_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_analytics ALTER COLUMN id_analytic ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_analytics_id_analytic_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 235 (class 1259 OID 17496)
-- Name: _config_condition_net; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_condition_net (
    id_condition_src bigint NOT NULL,
    id_condition_dst bigint NOT NULL,
    flag_add_not_to_src integer DEFAULT 0 NOT NULL,
    CONSTRAINT ck_config_condition_net_flag CHECK ((flag_add_not_to_src = ANY (ARRAY[0, 1])))
);


ALTER TABLE public._config_condition_net OWNER TO postgres;

--
-- TOC entry 3175 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE _config_condition_net; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_condition_net IS 'Net of conditions';


--
-- TOC entry 234 (class 1259 OID 17486)
-- Name: _config_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_conditions (
    id_condition bigint NOT NULL,
    condition_name character varying(500) NOT NULL,
    id_analytic bigint,
    analytic_type_compare character varying(10),
    analytic_value_float double precision,
    analytic_value_text character varying(4000),
    type_condition_aggregate character varying(10),
    CONSTRAINT ck_config_condition_consistent CHECK ((((id_analytic IS NULL) AND (type_condition_aggregate IS NOT NULL)) OR ((id_analytic IS NOT NULL) AND (type_condition_aggregate IS NULL) AND (analytic_type_compare IS NOT NULL) AND (((analytic_value_float IS NULL) AND (analytic_value_text IS NOT NULL)) OR ((analytic_value_float IS NOT NULL) AND (analytic_value_text IS NULL)))))),
    CONSTRAINT ck_config_conditions_analytic_type_compare CHECK ((((analytic_type_compare)::text = ANY ((ARRAY['IN'::character varying, 'NOT_IN'::character varying, 'LIKE'::character varying, 'NOT_LIKE'::character varying, 'EQUAL'::character varying, 'NOT_EQUAL'::character varying, '<='::character varying, '>='::character varying, '<'::character varying, '>'::character varying])::text[])) OR (analytic_type_compare IS NULL))),
    CONSTRAINT ck_config_conditions_type_condition_aggregate CHECK ((((type_condition_aggregate)::text = ANY ((ARRAY['OR'::character varying, 'AND'::character varying, 'ALL'::character varying])::text[])) OR (type_condition_aggregate IS NULL)))
);


ALTER TABLE public._config_conditions OWNER TO postgres;

--
-- TOC entry 3176 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN _config_conditions.id_analytic; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_conditions.id_analytic IS 'Analytic which will be in condition';


--
-- TOC entry 3177 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN _config_conditions.type_condition_aggregate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_conditions.type_condition_aggregate IS 'Type of aggregation conditions';


--
-- TOC entry 233 (class 1259 OID 17484)
-- Name: _config_conditions_id_condition_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_conditions ALTER COLUMN id_condition ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_conditions_id_condition_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 226 (class 1259 OID 17234)
-- Name: _config_journal_column_match_source_column; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_journal_column_match_source_column (
    id_col_jur bigint NOT NULL,
    id_col_src bigint NOT NULL
);


ALTER TABLE public._config_journal_column_match_source_column OWNER TO postgres;

--
-- TOC entry 3178 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE _config_journal_column_match_source_column; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_journal_column_match_source_column IS 'Match journal and sources';


--
-- TOC entry 219 (class 1259 OID 17185)
-- Name: _config_journal_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_journal_columns (
    id_col_jur bigint NOT NULL,
    id_jur bigint NOT NULL,
    column_name character varying(500) NOT NULL,
    id_account bigint,
    id_analytic bigint,
    CONSTRAINT _check_config_journals_id_analytic_account CHECK ((((id_account IS NOT NULL) AND (id_analytic IS NULL)) OR ((id_account IS NULL) AND (id_analytic IS NOT NULL))))
);


ALTER TABLE public._config_journal_columns OWNER TO postgres;

--
-- TOC entry 3179 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE _config_journal_columns; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_journal_columns IS 'Configuration table: columns of particular journal. Also each column has information about - analytic or account';


--
-- TOC entry 218 (class 1259 OID 17183)
-- Name: _config_journal_columns_id_col_jur_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_journal_columns ALTER COLUMN id_col_jur ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journal_columns_id_col_jur_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 239 (class 1259 OID 18157)
-- Name: _config_journal_hash_log_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_journal_hash_log_columns (
    id_hash_col bigint NOT NULL,
    id_hash_log bigint NOT NULL,
    column_name character varying(500) NOT NULL,
    order_n integer NOT NULL
);


ALTER TABLE public._config_journal_hash_log_columns OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 18155)
-- Name: _config_journal_hash_log_columns_id_hash_col_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_journal_hash_log_columns ALTER COLUMN id_hash_col ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journal_hash_log_columns_id_hash_col_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 217 (class 1259 OID 17173)
-- Name: _config_journals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_journals (
    id_jur bigint NOT NULL,
    journal_name character varying(500) NOT NULL,
    journal_stage_table_name character varying(1000) GENERATED ALWAYS AS (('stage_'::text || replace(lower((journal_name)::text), ' '::text, '_'::text))) STORED
);


ALTER TABLE public._config_journals OWNER TO postgres;

--
-- TOC entry 3180 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE _config_journals; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_journals IS 'Configuration table: list of journals';


--
-- TOC entry 237 (class 1259 OID 18147)
-- Name: _config_journals_hash_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_journals_hash_log (
    id_hash_log bigint NOT NULL,
    id_jur bigint NOT NULL,
    flag_journal_was_updated_by_hash boolean DEFAULT false NOT NULL,
    insert_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    insert_user character varying(200) DEFAULT CURRENT_USER NOT NULL
);


ALTER TABLE public._config_journals_hash_log OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 18145)
-- Name: _config_journals_hash_log_id_hash_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_journals_hash_log ALTER COLUMN id_hash_log ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journals_hash_log_id_hash_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 17171)
-- Name: _config_journals_id_jur_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_journals ALTER COLUMN id_jur ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journals_id_jur_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 232 (class 1259 OID 17477)
-- Name: _config_journals_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_journals_log (
    id_log bigint NOT NULL,
    id_jur bigint NOT NULL,
    condition_id bigint,
    insert_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    insert_user character varying(200) DEFAULT CURRENT_USER NOT NULL
);


ALTER TABLE public._config_journals_log OWNER TO postgres;

--
-- TOC entry 3181 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE _config_journals_log; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_journals_log IS 'Log table of loading data to the buffer of journal';


--
-- TOC entry 3182 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN _config_journals_log.condition_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public._config_journals_log.condition_id IS 'Condition to define the massive of data to update (example, period to update)';


--
-- TOC entry 231 (class 1259 OID 17475)
-- Name: _config_journals_log_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_journals_log ALTER COLUMN id_log ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_journals_log_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 225 (class 1259 OID 17224)
-- Name: _config_source_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_source_columns (
    id_col_src bigint NOT NULL,
    id_src bigint NOT NULL,
    column_name character varying(500) NOT NULL
);


ALTER TABLE public._config_source_columns OWNER TO postgres;

--
-- TOC entry 3183 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE _config_source_columns; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_source_columns IS 'Columns of source data for journals';


--
-- TOC entry 224 (class 1259 OID 17222)
-- Name: _config_source_columns_id_col_src_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_source_columns ALTER COLUMN id_col_src ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_source_columns_id_col_src_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 228 (class 1259 OID 17241)
-- Name: _config_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._config_sources (
    id_src bigint NOT NULL,
    db_name character varying(500) NOT NULL,
    schema_name character varying(500) NOT NULL,
    table_name character varying(500) NOT NULL
);


ALTER TABLE public._config_sources OWNER TO postgres;

--
-- TOC entry 3184 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE _config_sources; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public._config_sources IS 'Sources of data';


--
-- TOC entry 227 (class 1259 OID 17239)
-- Name: _config_sources_id_src_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public._config_sources ALTER COLUMN id_src ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public._config_sources_id_src_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 243 (class 1259 OID 18261)
-- Name: stage_insurance_premium_journal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stage_insurance_premium_journal (
    _pk_num bigint NOT NULL,
    date_operation timestamp without time zone,
    id_contract character varying,
    id_risk character varying,
    prem_value double precision,
    id_log bigint NOT NULL,
    id_src bigint NOT NULL,
    flag_technical_storno integer DEFAULT 0 NOT NULL,
    _pk_num_link_from_storno bigint,
    hash_key character varying(32) NOT NULL,
    id_hash_log bigint NOT NULL
);


ALTER TABLE public.stage_insurance_premium_journal OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 18259)
-- Name: stage_insurance_premium_journal__pk_num_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.stage_insurance_premium_journal ALTER COLUMN _pk_num ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.stage_insurance_premium_journal__pk_num_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 241 (class 1259 OID 18236)
-- Name: stage_insurance_premium_journal_buffer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stage_insurance_premium_journal_buffer (
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


ALTER TABLE public.stage_insurance_premium_journal_buffer OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 18234)
-- Name: stage_insurance_premium_journal_buffer__pk_num_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.stage_insurance_premium_journal_buffer ALTER COLUMN _pk_num ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.stage_insurance_premium_journal_buffer__pk_num_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 17281)
-- Name: test_source_prem_data1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_source_prem_data1 (
    sum_float double precision,
    d_opr date,
    contract_id character varying(500),
    risk_id character varying(500)
);


ALTER TABLE public.test_source_prem_data1 OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 17287)
-- Name: test_source_prem_data2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_source_prem_data2 (
    sum_float2 double precision,
    d_opr2 date,
    contract_id2 character varying(500),
    risk_id2 character varying(500)
);


ALTER TABLE public.test_source_prem_data2 OWNER TO postgres;

--
-- TOC entry 3142 (class 0 OID 17198)
-- Dependencies: 221
-- Data for Name: _config_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_accounts (id_account, finance_type, account_description) FROM stdin;
1	flow	Gross Written Premium
\.


--
-- TOC entry 3144 (class 0 OID 17211)
-- Dependencies: 223
-- Data for Name: _config_analytics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_analytics (id_analytic, analytic_description, type_value) FROM stdin;
1	Date of operation	date
2	Insurance contract ID	string
3	Insurance risk ID	string
4	Line of bussines	string
\.


--
-- TOC entry 3156 (class 0 OID 17496)
-- Dependencies: 235
-- Data for Name: _config_condition_net; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_condition_net (id_condition_src, id_condition_dst, flag_add_not_to_src) FROM stdin;
2	4	0
3	4	0
3	5	1
3	7	0
6	7	0
\.


--
-- TOC entry 3155 (class 0 OID 17486)
-- Dependencies: 234
-- Data for Name: _config_conditions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_conditions (id_condition, condition_name, id_analytic, analytic_type_compare, analytic_value_float, analytic_value_text, type_condition_aggregate) FROM stdin;
1	Date of operation after 31/12/2019	1	>	\N	2019-12-31	\N
2	Risk = risk1	3	EQUAL	\N	risk1	\N
3	Risk = risk2	3	EQUAL	\N	risk2	\N
6	Contract = contract3	2	EQUAL	\N	contract3	\N
4	Risk = risk1 OR risk2	\N	\N	\N	\N	OR
5	Risk = NOT risk2	\N	\N	\N	\N	AND
7	Risk = risk2 & Contract = contract3	\N	\N	\N	\N	AND
8	Line of bussiness = Motor	4	EQUAL	\N	Motor	\N
\.


--
-- TOC entry 3147 (class 0 OID 17234)
-- Dependencies: 226
-- Data for Name: _config_journal_column_match_source_column; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_journal_column_match_source_column (id_col_jur, id_col_src) FROM stdin;
1	1
2	2
3	3
4	4
1	5
2	6
3	7
4	8
\.


--
-- TOC entry 3140 (class 0 OID 17185)
-- Dependencies: 219
-- Data for Name: _config_journal_columns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_journal_columns (id_col_jur, id_jur, column_name, id_account, id_analytic) FROM stdin;
1	1	prem_value	1	\N
2	1	date_operation	\N	1
3	1	id_contract	\N	2
4	1	id_risk	\N	3
\.


--
-- TOC entry 3160 (class 0 OID 18157)
-- Dependencies: 239
-- Data for Name: _config_journal_hash_log_columns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_journal_hash_log_columns (id_hash_col, id_hash_log, column_name, order_n) FROM stdin;
\.


--
-- TOC entry 3138 (class 0 OID 17173)
-- Dependencies: 217
-- Data for Name: _config_journals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_journals (id_jur, journal_name) FROM stdin;
1	Insurance premium journal
\.


--
-- TOC entry 3158 (class 0 OID 18147)
-- Dependencies: 237
-- Data for Name: _config_journals_hash_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_journals_hash_log (id_hash_log, id_jur, flag_journal_was_updated_by_hash, insert_timestamp, insert_user) FROM stdin;
\.


--
-- TOC entry 3153 (class 0 OID 17477)
-- Dependencies: 232
-- Data for Name: _config_journals_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_journals_log (id_log, id_jur, condition_id, insert_timestamp, insert_user) FROM stdin;
\.


--
-- TOC entry 3146 (class 0 OID 17224)
-- Dependencies: 225
-- Data for Name: _config_source_columns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_source_columns (id_col_src, id_src, column_name) FROM stdin;
1	1	sum_float
2	1	d_opr
3	1	contract_id
4	1	risk_id
5	2	sum_float2
6	2	d_opr2
7	2	contract_id2
8	2	risk_id2
\.


--
-- TOC entry 3149 (class 0 OID 17241)
-- Dependencies: 228
-- Data for Name: _config_sources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._config_sources (id_src, db_name, schema_name, table_name) FROM stdin;
1	db_journals	public	test_source_prem_data1
2	db_journals	public	test_source_prem_data2
\.


--
-- TOC entry 3164 (class 0 OID 18261)
-- Dependencies: 243
-- Data for Name: stage_insurance_premium_journal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stage_insurance_premium_journal (_pk_num, date_operation, id_contract, id_risk, prem_value, id_log, id_src, flag_technical_storno, _pk_num_link_from_storno, hash_key, id_hash_log) FROM stdin;
\.


--
-- TOC entry 3162 (class 0 OID 18236)
-- Dependencies: 241
-- Data for Name: stage_insurance_premium_journal_buffer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stage_insurance_premium_journal_buffer (_pk_num, date_operation, id_contract, id_risk, prem_value, id_log, id_src, hash_key, id_hash_log) FROM stdin;
\.


--
-- TOC entry 3150 (class 0 OID 17281)
-- Dependencies: 229
-- Data for Name: test_source_prem_data1; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_source_prem_data1 (sum_float, d_opr, contract_id, risk_id) FROM stdin;
100	2019-07-01	contract1	risk1
500	2019-09-02	contract2	risk1
600	2019-10-02	contract3	risk2
350	2020-01-02	contract3	risk2
\.


--
-- TOC entry 3151 (class 0 OID 17287)
-- Dependencies: 230
-- Data for Name: test_source_prem_data2; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_source_prem_data2 (sum_float2, d_opr2, contract_id2, risk_id2) FROM stdin;
\.


--
-- TOC entry 3185 (class 0 OID 0)
-- Dependencies: 220
-- Name: _config_accounts_id_account_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_accounts_id_account_seq', 1, true);


--
-- TOC entry 3186 (class 0 OID 0)
-- Dependencies: 222
-- Name: _config_analytics_id_analytic_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_analytics_id_analytic_seq', 4, true);


--
-- TOC entry 3187 (class 0 OID 0)
-- Dependencies: 233
-- Name: _config_conditions_id_condition_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_conditions_id_condition_seq', 8, true);


--
-- TOC entry 3188 (class 0 OID 0)
-- Dependencies: 218
-- Name: _config_journal_columns_id_col_jur_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_journal_columns_id_col_jur_seq', 4, true);


--
-- TOC entry 3189 (class 0 OID 0)
-- Dependencies: 238
-- Name: _config_journal_hash_log_columns_id_hash_col_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_journal_hash_log_columns_id_hash_col_seq', 1, false);


--
-- TOC entry 3190 (class 0 OID 0)
-- Dependencies: 236
-- Name: _config_journals_hash_log_id_hash_log_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_journals_hash_log_id_hash_log_seq', 1, false);


--
-- TOC entry 3191 (class 0 OID 0)
-- Dependencies: 216
-- Name: _config_journals_id_jur_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_journals_id_jur_seq', 1, true);


--
-- TOC entry 3192 (class 0 OID 0)
-- Dependencies: 231
-- Name: _config_journals_log_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_journals_log_id_log_seq', 1, false);


--
-- TOC entry 3193 (class 0 OID 0)
-- Dependencies: 224
-- Name: _config_source_columns_id_col_src_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_source_columns_id_col_src_seq', 8, true);


--
-- TOC entry 3194 (class 0 OID 0)
-- Dependencies: 227
-- Name: _config_sources_id_src_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public._config_sources_id_src_seq', 2, true);


--
-- TOC entry 3195 (class 0 OID 0)
-- Dependencies: 242
-- Name: stage_insurance_premium_journal__pk_num_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stage_insurance_premium_journal__pk_num_seq', 1, false);


--
-- TOC entry 3196 (class 0 OID 0)
-- Dependencies: 240
-- Name: stage_insurance_premium_journal_buffer__pk_num_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stage_insurance_premium_journal_buffer__pk_num_seq', 1, false);


--
-- TOC entry 2964 (class 2606 OID 17206)
-- Name: _config_accounts _config_accounts_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_accounts
    ADD CONSTRAINT _config_accounts_pk PRIMARY KEY (id_account);


--
-- TOC entry 2966 (class 2606 OID 17219)
-- Name: _config_analytics _config_analytic_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_analytics
    ADD CONSTRAINT _config_analytic_pk PRIMARY KEY (id_analytic);


--
-- TOC entry 2982 (class 2606 OID 17502)
-- Name: _config_condition_net _config_condition_net_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_condition_net
    ADD CONSTRAINT _config_condition_net_pk PRIMARY KEY (id_condition_src, id_condition_dst);


--
-- TOC entry 2980 (class 2606 OID 17495)
-- Name: _config_conditions _config_conditions_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_conditions
    ADD CONSTRAINT _config_conditions_pk PRIMARY KEY (id_condition);


--
-- TOC entry 2960 (class 2606 OID 17193)
-- Name: _config_journal_columns _config_journal_columns_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT _config_journal_columns_pk PRIMARY KEY (id_col_jur);


--
-- TOC entry 2986 (class 2606 OID 18164)
-- Name: _config_journal_hash_log_columns _config_journal_hash_log_columns_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_hash_log_columns
    ADD CONSTRAINT _config_journal_hash_log_columns_pk PRIMARY KEY (id_hash_col);


--
-- TOC entry 2984 (class 2606 OID 18154)
-- Name: _config_journals_hash_log _config_journal_hash_logs_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals_hash_log
    ADD CONSTRAINT _config_journal_hash_logs_pk PRIMARY KEY (id_hash_log);


--
-- TOC entry 2972 (class 2606 OID 17238)
-- Name: _config_journal_column_match_source_column _config_journal_match_source_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_column_match_source_column
    ADD CONSTRAINT _config_journal_match_source_pk PRIMARY KEY (id_col_jur, id_col_src);


--
-- TOC entry 2968 (class 2606 OID 17231)
-- Name: _config_source_columns _config_journal_sources_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_source_columns
    ADD CONSTRAINT _config_journal_sources_pk PRIMARY KEY (id_col_src);


--
-- TOC entry 2978 (class 2606 OID 17483)
-- Name: _config_journals_log _config_journals_log_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals_log
    ADD CONSTRAINT _config_journals_log_pk PRIMARY KEY (id_log);


--
-- TOC entry 2956 (class 2606 OID 17180)
-- Name: _config_journals _config_journals_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals
    ADD CONSTRAINT _config_journals_pk PRIMARY KEY (id_jur);


--
-- TOC entry 2974 (class 2606 OID 17248)
-- Name: _config_sources _config_sources_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_sources
    ADD CONSTRAINT _config_sources_pk PRIMARY KEY (id_src);


--
-- TOC entry 2988 (class 2606 OID 18243)
-- Name: stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_pkey PRIMARY KEY (_pk_num);


--
-- TOC entry 2990 (class 2606 OID 18269)
-- Name: stage_insurance_premium_journal stage_insurance_premium_journal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_pkey PRIMARY KEY (_pk_num);


--
-- TOC entry 2962 (class 2606 OID 17195)
-- Name: _config_journal_columns uq__config_journal_columns; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT uq__config_journal_columns UNIQUE (id_jur, column_name);


--
-- TOC entry 2970 (class 2606 OID 17233)
-- Name: _config_source_columns uq__config_source_columns; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_source_columns
    ADD CONSTRAINT uq__config_source_columns UNIQUE (id_src, column_name);


--
-- TOC entry 2976 (class 2606 OID 17250)
-- Name: _config_sources uq__config_sources; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_sources
    ADD CONSTRAINT uq__config_sources UNIQUE (db_name, schema_name, table_name);


--
-- TOC entry 2958 (class 2606 OID 17182)
-- Name: _config_journals uq_config_journals; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals
    ADD CONSTRAINT uq_config_journals UNIQUE (journal_name);


--
-- TOC entry 2993 (class 2606 OID 17261)
-- Name: _config_journal_columns _config_journal_columns_analytic; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT _config_journal_columns_analytic FOREIGN KEY (id_analytic) REFERENCES public._config_analytics(id_analytic) MATCH FULL;


--
-- TOC entry 3001 (class 2606 OID 17518)
-- Name: _config_condition_net fk_config_condition_net_dst; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_condition_net
    ADD CONSTRAINT fk_config_condition_net_dst FOREIGN KEY (id_condition_dst) REFERENCES public._config_conditions(id_condition) MATCH FULL;


--
-- TOC entry 3000 (class 2606 OID 17513)
-- Name: _config_condition_net fk_config_condition_net_src; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_condition_net
    ADD CONSTRAINT fk_config_condition_net_src FOREIGN KEY (id_condition_src) REFERENCES public._config_conditions(id_condition) MATCH FULL;


--
-- TOC entry 2999 (class 2606 OID 17508)
-- Name: _config_conditions fk_config_conditions_id_analytic; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_conditions
    ADD CONSTRAINT fk_config_conditions_id_analytic FOREIGN KEY (id_analytic) REFERENCES public._config_analytics(id_analytic) MATCH FULL;


--
-- TOC entry 2992 (class 2606 OID 17256)
-- Name: _config_journal_columns fk_config_journal_columns_id_account; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT fk_config_journal_columns_id_account FOREIGN KEY (id_account) REFERENCES public._config_accounts(id_account) MATCH FULL;


--
-- TOC entry 2991 (class 2606 OID 17251)
-- Name: _config_journal_columns fk_config_journal_columns_id_jur; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_columns
    ADD CONSTRAINT fk_config_journal_columns_id_jur FOREIGN KEY (id_jur) REFERENCES public._config_journals(id_jur) MATCH FULL;


--
-- TOC entry 3003 (class 2606 OID 18170)
-- Name: _config_journal_hash_log_columns fk_config_journal_hash_log_columns_id_hash_log; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_hash_log_columns
    ADD CONSTRAINT fk_config_journal_hash_log_columns_id_hash_log FOREIGN KEY (id_hash_log) REFERENCES public._config_journals_hash_log(id_hash_log) MATCH FULL;


--
-- TOC entry 3002 (class 2606 OID 18165)
-- Name: _config_journals_hash_log fk_config_journal_hash_logs_id_jur; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals_hash_log
    ADD CONSTRAINT fk_config_journal_hash_logs_id_jur FOREIGN KEY (id_jur) REFERENCES public._config_journals(id_jur) MATCH FULL;


--
-- TOC entry 2995 (class 2606 OID 17271)
-- Name: _config_journal_column_match_source_column fk_config_journal_match_source_id_col_jur; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_column_match_source_column
    ADD CONSTRAINT fk_config_journal_match_source_id_col_jur FOREIGN KEY (id_col_jur) REFERENCES public._config_journal_columns(id_col_jur) MATCH FULL;


--
-- TOC entry 2996 (class 2606 OID 17276)
-- Name: _config_journal_column_match_source_column fk_config_journal_match_source_id_col_src; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journal_column_match_source_column
    ADD CONSTRAINT fk_config_journal_match_source_id_col_src FOREIGN KEY (id_col_src) REFERENCES public._config_source_columns(id_col_src) MATCH FULL;


--
-- TOC entry 2994 (class 2606 OID 17266)
-- Name: _config_source_columns fk_config_journal_sources_id_src; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_source_columns
    ADD CONSTRAINT fk_config_journal_sources_id_src FOREIGN KEY (id_src) REFERENCES public._config_sources(id_src) MATCH FULL;


--
-- TOC entry 2998 (class 2606 OID 17523)
-- Name: _config_journals_log fk_config_journals_log_condition_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals_log
    ADD CONSTRAINT fk_config_journals_log_condition_id FOREIGN KEY (condition_id) REFERENCES public._config_conditions(id_condition) MATCH FULL;


--
-- TOC entry 2997 (class 2606 OID 17503)
-- Name: _config_journals_log fk_config_journals_log_id_jur; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._config_journals_log
    ADD CONSTRAINT fk_config_journals_log_id_jur FOREIGN KEY (id_jur) REFERENCES public._config_journals(id_jur) MATCH FULL;


--
-- TOC entry 3009 (class 2606 OID 18280)
-- Name: stage_insurance_premium_journal stage_insurance_premium_journal__pk_num_link_from_storno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal__pk_num_link_from_storno_fkey FOREIGN KEY (_pk_num_link_from_storno) REFERENCES public.stage_insurance_premium_journal(_pk_num);


--
-- TOC entry 3006 (class 2606 OID 18254)
-- Name: stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_id_hash_log_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_id_hash_log_fkey FOREIGN KEY (id_hash_log) REFERENCES public._config_journals_hash_log(id_hash_log);


--
-- TOC entry 3004 (class 2606 OID 18244)
-- Name: stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_id_log_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_id_log_fkey FOREIGN KEY (id_log) REFERENCES public._config_journals_log(id_log);


--
-- TOC entry 3005 (class 2606 OID 18249)
-- Name: stage_insurance_premium_journal_buffer stage_insurance_premium_journal_buffer_id_src_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal_buffer
    ADD CONSTRAINT stage_insurance_premium_journal_buffer_id_src_fkey FOREIGN KEY (id_src) REFERENCES public._config_sources(id_src);


--
-- TOC entry 3010 (class 2606 OID 18285)
-- Name: stage_insurance_premium_journal stage_insurance_premium_journal_id_hash_log_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_id_hash_log_fkey FOREIGN KEY (id_hash_log) REFERENCES public._config_journals_hash_log(id_hash_log);


--
-- TOC entry 3007 (class 2606 OID 18270)
-- Name: stage_insurance_premium_journal stage_insurance_premium_journal_id_log_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_id_log_fkey FOREIGN KEY (id_log) REFERENCES public._config_journals_log(id_log);


--
-- TOC entry 3008 (class 2606 OID 18275)
-- Name: stage_insurance_premium_journal stage_insurance_premium_journal_id_src_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_insurance_premium_journal
    ADD CONSTRAINT stage_insurance_premium_journal_id_src_fkey FOREIGN KEY (id_src) REFERENCES public._config_sources(id_src);


-- Completed on 2020-11-04 14:01:51 MSK

--
-- PostgreSQL database dump complete
--

