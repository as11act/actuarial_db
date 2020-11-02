/*	insert insurance premium journal	*/
insert into public._config_journals (journal_name) select	'Insurance premium journal';

/*	insert base analytics of insurance premium journal	*/
insert into public._config_analytics
select	1,'Date of operation' union all
select	2,'Insurance contract ID' union all
select	3,'Insurance risk ID';

/*	insert	*/

/*	insert columns of journal	*/
insert into public._config_journal_columns (id_jur,column_name,id_account,id_analytic) 
select 1,'prem_value',1,NULL union all
select 1,'date_operation',NULL,1 union all
select 1,'id_contract',NULL,2 union all
select 1,'id_risk',NULL,3
