/*	insert insurance premium journal	*/
insert into public._config_journals (journal_name) select	'Insurance premium journal';

--select	* from _config_journals

/*	insert base analytics of insurance premium journal	*/
insert into public._config_analytics (analytic_name,analytic_description,type_value)
select	'd_opr','Date of operation','date' union all
select	'id_contract','Insurance contract ID','string' union all
select	'id_risk','Insurance risk ID','string';

/*	insert base accounts of insurance premuim journal	*/
insert into public._config_accounts (account_name,finance_type)
select	'Gross Written Premium','flow';

/*	insert columns of journal	*/
insert into public._config_journal_columns (id_jur,column_name,id_account,id_analytic) 
select 1,'prem_value',1,NULL union all
select 1,'date_operation',NULL,1 union all
select 1,'id_contract',NULL,2 union all
select 1,'id_risk',NULL,3;

/*	create test sources	*/
create table public.test_source_prem_data1 (sum_float float,d_opr date,contract_id varchar(500),risk_id varchar(500));
create table public.test_source_prem_data2 (sum_float2 float,d_opr2 date,contract_id2 varchar(500),risk_id2 varchar(500));

/*	fill info about sources	*/
insert into public._config_sources (db_name,schema_name,table_name) 
select 'db_journals','public','test_source_prem_data1'
union all
select 'db_journals','public','test_source_prem_data2';

/*	source columns	*/
--select	* from _config_source_columns
insert into public._config_source_columns (id_src,column_name)
select	1,'sum_float' union all
select	1,'d_opr' union all
select	1,'contract_id' union all
select	1,'risk_id' union all
select	2,'sum_float2' union all
select	2,'d_opr2' union all
select	2,'contract_id2' union all
select	2,'risk_id2';