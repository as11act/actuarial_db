-- View: public.view_technical_column_of_journals_buffer

-- DROP VIEW public.view_technical_column_of_journals_buffer;

CREATE OR REPLACE VIEW public.view_technical_column_of_journals_buffer
 AS
 SELECT 'hash_key'::text AS column_name
UNION ALL
 SELECT 'id_hash_log'::text AS column_name
UNION ALL
 SELECT 'id_log'::text AS column_name
UNION ALL
 SELECT 'id_src'::text AS column_name
UNION ALL
 SELECT '_pk_num'::text AS column_name;

ALTER TABLE public.view_technical_column_of_journals_buffer
    OWNER TO postgres;

