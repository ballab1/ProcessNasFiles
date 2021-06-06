CREATE SCHEMA IF NOT EXISTS nasinfo;

DROP SEQUENCE IF EXISTS nasinfo.id CASCADE;
CREATE SEQUENCE nasinfo.id
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE nasinfo.id OWNER TO postgres;


DROP TABLE IF EXISTS nasinfo.rawdata CASCADE;
CREATE TABLE IF NOT EXISTS nasinfo.rawdata
(
    data character varying COLLATE pg_catalog."default"
)
TABLESPACE pg_default;
ALTER TABLE nasinfo.rawdata OWNER to postgres;
    
DROP TABLE IF EXISTS nasinfo.nasdata CASCADE;
CREATE TABLE nasinfo.nasdata
(
    id bigint NOT NULL DEFAULT nextval('nasinfo.id'::regclass),
    ischild boolean DEFAULT true,
    isgit boolean DEFAULT false,
    isdel boolean DEFAULT false,
    rownum bigint,
    len integer,
    cnt integer DEFAULT 0,
    gid integer,
    uid integer,
    size bigint,
    type character varying COLLATE pg_catalog."default",
    depth integer,
    gname character varying COLLATE pg_catalog."default",
    inode bigint,
    blocks integer,
    device integer,
    file character varying COLLATE pg_catalog."default",
    name character varying COLLATE pg_catalog."default",
    folder character varying COLLATE pg_catalog."default",
    mode_8 character varying COLLATE pg_catalog."default",
    sha256 character varying COLLATE pg_catalog."default",
    dir_count integer,
    block_size integer,
    file_count integer,
    hard_links integer,
    device_type integer,
    last_access bigint,
    last_modified bigint,
    last_status_change bigint,
    last_access_time timestamp with time zone,
    last_modified_time timestamp with time zone,
    last_status_change_time timestamp with time zone,
    CONSTRAINT base_pkey PRIMARY KEY (id)
)
TABLESPACE pg_default;
ALTER TABLE nasinfo.nasdata OWNER to postgres;
