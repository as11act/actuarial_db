SELECT id_condition, condition_name, id_analytic, analytic_type_compare, analytic_value_float, analytic_value_text, type_condition_aggregate
	FROM public._config_conditions;
	
select	public."func_get_SQL_of_condition_id"(4)	
select	*
from	public.func_get_table_of_analytic_id_for_condition_id(7)

select	*
from	_config_conditions

select	public."func_get_SQL_of_condition_id"(8)
select	public."func_get_SQL_of_condition_id_for_journal"(8,1)

select	*,
		public."func_get_SQL_of_condition_id"(id_condition),
		public."func_get_SQL_of_condition_id_for_journal"(id_condition,1)
from _config_conditions;	

alter table _config_conditions add 

"((id_risk='risk1' and id_risk is not NULL)) OR ((id_risk='risk2' and id_risk is not NULL))"

select	* from public.test_source_prem_data1

select	* from _config_analytics;	

insert into _config_analytics (analytic_description,type_value)
select	'Line of bussines','string'
	
insert into _config_conditions (condition_name,id_analytic,analytic_type_compare,analytic_value_text)
select	'Date of operation after 31/12/2019',1,'>','2019-12-31'

insert into _config_conditions (condition_name,id_analytic,analytic_type_compare,analytic_value_text)
select	'Risk = risk1',3,'EQUAL','risk1'
union all
select	'Risk = risk2',3,'EQUAL','risk2'

insert into _config_conditions (condition_name,id_analytic,type_condition_aggregate)
select	'Risk = risk1 OR risk2',3,'OR'

insert into _config_conditions (condition_name,id_analytic,type_condition_aggregate)
select	'Risk = NOT risk2',3,'AND'

insert into _config_conditions (condition_name,id_analytic,analytic_type_compare,analytic_value_text)
select	'Contract = contract3',2,'EQUAL','contract3'

insert into _config_conditions (condition_name,id_analytic,analytic_type_compare,analytic_value_text)
select	'Line of bussiness = Motor',4,'EQUAL','Motor'

update	_config_conditions
set		id_analytic=NULL
where	type_condition_aggregate is not null

insert into _config_conditions (condition_name,type_condition_aggregate)
select	'Risk = risk2 & Contract = contract3','AND'

select	* from _config_condition_net

insert into public._config_condition_net
select	3,7,0
union all
select	6,7,0
