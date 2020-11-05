-- View: public.view_technical_column_of_journals

-- DROP VIEW public.view_technical_column_of_journals;

CREATE OR REPLACE VIEW public.view_technical_column_of_journals
 AS
 SELECT 'flag_technical_storno'::text AS column_name
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

ALTER TABLE public.view_technical_column_of_journals
    OWNER TO postgres;

