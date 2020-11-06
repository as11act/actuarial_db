SELECT public.func_get_sql_new_columns(
	1, 
	1
);

select	* from _config_journals

CALL public.sp_check_and_correct_journal(
	'Insurance premium journal', 
	0, 
	TRUE
);

select	*
from	public._config_journal_columns

SELECT public.func_get_column_name_of_source_by_id_column_of_journal(
	3, 
	2
)

SELECT public."func_get_SQL_of_condition_id_for_journal_for_source"(
	1,--<id_condition bigint>, 
	1,--<id_jur bigint>, 
	2--<id_src0 bigint>
)

SELECT public."func_get_SQL_of_condition_id_for_journal_for_source"(
	1, 
	1, 
	2
)

select	*
from	public._config_journals_log

select	*
from	public._config_conditions

select public."func_get_SQL_of_condition_id_for_journal"(1,1)
--condition_id0

SELECT public.func_get_sql_insert_buffer(
	1, 
	1, 
	3
)
insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) 
select d_opr,contract_id,risk_id,sum_float,1 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(contract_id as character varying),'cNULL')||coalesce(cast(risk_id as character varying),'cNULL')||coalesce(cast(sum_float as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data1; 
insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) 
select d_opr2,contract_id2,risk_id2,sum_float2,2 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr2 as character varying),'cNULL')||coalesce(cast(contract_id2 as character varying),'cNULL')||coalesce(cast(risk_id2 as character varying),'cNULL')||coalesce(cast(sum_float2 as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data2;
"insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr,contract_id,risk_id,sum_float,1 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(contract_id as character varying),'cNULL')||coalesce(cast(risk_id as character varying),'cNULL')||coalesce(cast(sum_float as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data1; insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr2,contract_id2,risk_id2,sum_float2,2 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr2 as character varying),'cNULL')||coalesce(cast(contract_id2 as character varying),'cNULL')||coalesce(cast(risk_id2 as character varying),'cNULL')||coalesce(cast(sum_float2 as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data2;"
"insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr,contract_id,risk_id,sum_float,2 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(contract_id as character varying),'cNULL')||coalesce(cast(risk_id as character varying),'cNULL')||coalesce(cast(sum_float as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data1; insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr2,contract_id2,risk_id2,sum_float2,2 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr2 as character varying),'cNULL')||coalesce(cast(contract_id2 as character varying),'cNULL')||coalesce(cast(risk_id2 as character varying),'cNULL')||coalesce(cast(sum_float2 as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data2;"
"insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr,contract_id,risk_id,sum_float,2 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(contract_id as character varying),'cNULL')||coalesce(cast(risk_id as character varying),'cNULL')||coalesce(cast(sum_float as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data1; insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr2,contract_id2,risk_id2,sum_float2"
"insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr,contract_id,risk_id,sum_float,2 id_src,1 id_log,3 id_hash_log,md5(coalesce(cast(d_opr2 as character varying),'cNULL')||coalesce(cast(contract_id2 as character varying),'cNULL')||coalesce(cast(risk_id2 as character varying),'cNULL')||coalesce(cast(sum_float2 as character varying),'cNULL')) hash_key from db_journals.public.test_source_prem_data1; insert into stage_insurance_premium_journal_buffer(date_operation,id_contract,id_risk,prem_value,id_src,id_log,id_hash_log,hash_key) select d_opr2,contract_id2,risk_id2,sum_float2"

delete from public._config_journal_hash_log_columns
delete from _config_journals_hash_log

select	* from public._config_journals_hash_log
select	* from public._config_journal_hash_log_columns
select	* from public._config_sources

select	public.func_get_sql_hash_key(3)
--"md5(coalesce(cast(date_operation as character varying),'cNULL')||coalesce(cast(id_contract as character varying),'cNULL')||coalesce(cast(id_risk as character varying),'cNULL')||coalesce(cast(prem_value as character varying),'cNULL'))"
--"md5(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(contract_id as character varying),'cNULL')||coalesce(cast(risk_id as character varying),'cNULL')||coalesce(cast(sum_float as character varying),'cNULL'))"
--"md5(coalesce(cast(d_opr2 as character varying),'cNULL')||coalesce(cast(contract_id2 as character varying),'cNULL')||coalesce(cast(risk_id2 as character varying),'cNULL')||coalesce(cast(sum_float2 as character varying),'cNULL'))"
select	public.func_get_sql_hash_key_for_source(3, 2)

CALL public.sp_load_data_to_the_journal_buffer(
	'Insurance premium journal',--<journal_name character varying>, 
	1, 
	FALSE
)

select	*
from	public.stage_insurance_premium_journal_buffer

select	md5(coalesce(cast(date_operation as character varying),'cNULL')||coalesce(cast(id_contract as character varying),'cNULL')||coalesce(cast(id_risk as character varying),'cNULL')||coalesce(cast(prem_value as character varying),'cNULL'))
from	public.stage_insurance_premium_journal_buffer

CALL public.sp_check_create_the_hash_of_journal(
	'Insurance premium journal',--<journal_name character varying>, 
	0, 
	TRUE
);

alter table stage_insurance_premium_journal add id_hash_log bigint references public._config_journals_hash_log(id_hash_log); 
alter table stage_insurance_premium_journal add id_log bigint references public._config_journals_log(id_log)

alter table stage_insurance_premium_journal add date_operation timestamp; 
alter table stage_insurance_premium_journal add id_risk character varying; 
alter table stage_insurance_premium_journal add prem_value float; 
alter table stage_insurance_premium_journal add _pk_num_link_from_storno bigint references stage_insurance_premium_journal(_pk_num);

SELECT public.func_get_sql_new_columns(
	1, 
	1
)

alter table stage_insurance_premium_journal_buffer add id_hash_log bigint references public._config_journals_hash_log(id_hash_log)