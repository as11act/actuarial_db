SELECT *	FROM public._finance_functions;
SELECT *	FROM public._finance_function_parametres;
SELECT *	FROM public._finance_function_pins;
SELECT *	FROM public._finance_blocks;
SELECT *	FROM public._finance_block_pins;

--alter table _finance_block_pins add foreign key (id_storage) references public._finance_storage_tables(id_storage)

update	public._finance_function_pins set pin_value_type='account';
update	public._finance_function_parametres set parameter_number=1;

"func_fin_source_block"

select	* from public._finance_storage_tables;

insert into _finance_storage_tables (db_name,schema_name,table_name)
select	'db_journals','public','stage_sources'
