truncate nasinfo.rawdata;
copy nasinfo.rawdata from ':jsonfile';

DROP TABLE nasinfo.nasdata;
CREATE TABLE nasinfo.nasdata
(
    -- Inherited from table nasinfo.base: id bigint NOT NULL DEFAULT nextval('nasinfo.id'::regclass),
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
    jsondata jsonb
)
INHERITS (nasinfo.base) TABLESPACE pg_default;
ALTER TABLE nasinfo.nasdata OWNER to postgres;

insert into nasinfo.nasdata (jsondata) select data::jsonb from nasinfo.rawdata;

update nasinfo.nasdata z set (
    "len"
  , "gid"
  , "uid"
  , "file"
  , "name"
  , "size"
  , "type"
  , "depth"
  , "gname"
  , "inode"
  , "blocks"
  , "device"
  , "folder"
  , "mode_8"
  , "sha256"
  , "dir_count"
  , "block_size"
  , "file_count"
  , "hard_links"
  , "device_type"
  , "last_access"
  , "last_modified"
  , "last_status_change"
  , "last_access_time"
  , "last_modified_time"
  , "last_status_change_time"
  , "isgit"
) = (
    length(z.jsondata->>'file')
  , (z.jsondata->>'gid')::int
  , (z.jsondata->>'uid')::int
  , regexp_replace(z.jsondata->>'file', '^/mnt/', '')
  , z.jsondata->>'name'
  , (z.jsondata->>'size')::bigint
  , z.jsondata->>'type'
  , (z.jsondata->>'depth')::int
  , z.jsondata->>'gname'
  , (z.jsondata->>'inode')::bigint
  , (z.jsondata->>'blocks')::int
  , (z.jsondata->>'device')::int
  , regexp_replace(z.jsondata->>'folder', '^/mnt/', '')
  , z.jsondata->>'mode_8'
  , z.jsondata->>'sha256'
  , (z.jsondata->>'dir_count')::int
  , (z.jsondata->>'block_size')::int
  , (z.jsondata->>'file_count')::int
  , (z.jsondata->>'hard_links')::int
  , (z.jsondata->>'device_type')::int
  , (z.jsondata->>'last_access')::bigint
  , (z.jsondata->>'last_modified')::bigint
  , (z.jsondata->>'last_status_change')::bigint
  , (z.jsondata->>'last_access_time')::timestamp with time zone
  , (z.jsondata->>'last_modified_time')::timestamp with time zone
  , (z.jsondata->>'last_status_change_time')::timestamp with time zone
  , (z.jsondata->>'file' ~* '/.git/')::boolean
);

ALTER TABLE nasinfo.nasdata DROP COLUMN "jsondata";

with
 a as (select sha256, count(*) cnt from nasinfo.nasdata group by sha256)
update nasinfo.nasdata z set (cnt,rownum) = (a.cnt,1) from a where a.sha256 = z.sha256;

with
 a as (select id, row_number() over (partition by sha256 order by len) rnum from nasinfo.nasdata where cnt > 1 )
update nasinfo.nasdata z set rownum = rnum from a where a.id = z.id;

with
 a as (select *
         from nasinfo.nasdata
         where "size" > 0 and "type" = 'directory')
,f as (select f00.id
         from a f00
         left join a f10 on left(f10."file", f00.len) = f00."file" and f10.len > f00.len
        where f10."file" is null)
update nasinfo.nasdata z set ischild = false from f where z.id = f.id;