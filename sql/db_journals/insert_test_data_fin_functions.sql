SELECT id_function, function_name
	FROM public._finance_functions;

SELECT *
	FROM public._config_accounts;	

SELECT *
	FROM public._finance_function_parametres;	
	
SELECT *
	FROM public._finance_function_pins;		
	
insert into 	_finance_functions (function_name) values ('func_fin_source_block');

insert into 	_finance_function_parametres (id_function,parameter_name,type_value_float_string,parameter_value_string) 
select	1,'source_table_name','text','public.stage_insurance_premium_journal';

insert into 	public._finance_function_pins (id_function,pin_number,pin_name,type_in_out,pin_value_type)
select	1,1,'prem_value','out','flow'