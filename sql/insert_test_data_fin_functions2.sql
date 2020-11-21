SELECT *	FROM public._finance_functions;
SELECT *	FROM public._finance_function_parametres;
SELECT *	FROM public._finance_function_pins;
SELECT *	FROM public._finance_blocks;
SELECT *	FROM public._finance_block_pins;

insert into _finance_blocks (block_name,id_function,operation_mode)
select	'Source_GWP',1,'manual'

--alter table _finance_block_pins add foreign key (id_storage) references public._finance_storage_tables(id_storage)

update _finance_functions set function_name='sp_fin_source_block'
update	public._finance_function_pins set pin_value_type='account';
update	public._finance_function_parametres set parameter_number=1;

"func_fin_source_block"

select	* from public._finance_storage_tables;

insert into _finance_storage_tables (db_name,schema_name,table_name)
select	'db_journals','public','stage_sources'
