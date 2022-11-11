-- On a PostGIS, columns with types and geometry details

select 
    d.nspname as schemaname,
    a.relname as tablename,
    a.relkind as tabletype,
    b.attname as columnname,
    c.typname as typename,
    b.atttypmod as length,
    e.srid as geom_srid,
    e.type as geom_type
from
    pg_catalog.pg_class a inner join
    pg_catalog.pg_attribute b on
    a.oid=b.attrelid inner join
    pg_catalog.pg_type c on
    b.atttypid=c.oid inner join
    pg_catalog.pg_namespace d on
    a.relnamespace=d.oid left join
    public.geometry_columns e on
    d.nspname=e.f_table_schema and a.relname=e.f_table_name and b.attname=e.f_geometry_column
where a.relkind not in ('i', 't', 'c', 'S') and attnum>0
order by d.nspname, a.relname, attnum;



-- This returns columns that are primary key

with a as(
    select
        b.nspname as tableschema,
        c.relname as tablename,
        a.conname as conname,
        unnest(conkey) as conkey,
        conrelid
    from
        pg_catalog.pg_constraint a inner join
        pg_catalog.pg_namespace b on
        a.connamespace=b.oid inner join
        pg_catalog.pg_class c on
        a.conrelid=c.oid
    where
        a.contype='p')
select
    a.tableschema,
    a.tablename,
    a.conname,
    array_agg(b.attname)::varchar[] as columns
from
    a a inner join
    pg_catalog.pg_attribute b on
    a.conrelid=b.attrelid and a.conkey=b.attnum
group by tableschema, tablename, conname;



-- This returns the gist geometry indices in place

with a as(
    select
        d.nspname as schemaname, 
        c.relname as tablename,
        b.relname as indexname,
        c.oid as oidtable,
        unnest(a.indkey) as indkey,
        unnest(a.indclass) as indclass
    from
        pg_catalog.pg_index a inner join
        pg_catalog.pg_class b on
        a.indexrelid=b.oid inner join
        pg_catalog.pg_class c on
        a.indrelid=c.oid inner join
        pg_catalog.pg_namespace d on
        b.relnamespace=d.oid 
    order by b.relname, c.relname)

select
    a.schemaname,
    a.tablename,
    a.indexname,
    c.attname as columnname,
    b.opcname as indextype
from
    a inner join 
    pg_catalog.pg_opclass b on
    a.indclass=b.oid inner join
    pg_catalog.pg_attribute c on
    a.oidtable=c.attrelid and a.indkey=c.attnum
where
    b.opcname='gist_geometry_ops_2d';