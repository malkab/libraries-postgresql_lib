#!/usr/bin/env python3
# coding=UTF8

import argparse, psycopg2, sys, psycopg2.extras

def scripts(table, host="localhost", port="5432", user="postgres", database="postgres", password="postgres", newTableName=None, renameConstraints=False):

    # Create new table name
    newTableFullName = newTableName if newTableName else table
    newTableName = newTableFullName.split(".")[1] if "." in newTableFullName \
                        else newTableName

    # Examine original table name
    if "." in table:
        tableSchema, tableName = table.split(".")
    else:
        tableSchema, tableName = ["public", table]

    # Output string
    output = ""

    # Connect to the database
    conn = psycopg2.connect("dbname=%s user=%s host=%s password=%s port=%s" % \
                        (database, user, host, password, port))

    conn.set_client_encoding("utf8")

    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    sql = """
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
    where
        a.relkind not in ('i', 't', 'c', 'S') and attnum>0 and
        d.nspname=%s and
        a.relname=%s
    order by d.nspname, a.relname, attnum
    """

    cur.execute(sql, (tableSchema, tableName))

    # Write load script

    # Write create table
    output += ("-- Table DDL for %s\n\n" % newTableFullName)
    output += ("create table %s(\n" % newTableFullName)
    columns = ""
    geomColumns = []

    for i in cur:
        if i["typename"] == 'geometry':
            columns += "    %s %s(%s, %s),\n" % \
                (i["columnname"], i["typename"], i["geom_type"], i["geom_srid"])

        # Array types
        elif i["typename"][0] == '_':
            columns += "    %s %s[],\n" % \
                (i["columnname"], i["typename"][1:])

        elif i["typename"] == 'varchar':
            columns += "    %s %s(%s),\n" % \
                (i["columnname"], i["typename"], i["length"])

        else:
            columns += "    %s %s,\n" % (i["columnname"], i["typename"])

    columns = columns[:-2]

    output += (columns)
    output += ("\n);")


    # Write primary key

    sql = """
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
    where
        a.tableschema=%s and
        a.tablename=%s
    group by tableschema, tablename, conname
    """

    cur.execute(sql, (tableSchema, tableName))
    pkey = cur.fetchone()


    # Check if there is a primary key
    if cur.rowcount>0:
        output += ("\n\nalter table %s\n" % (newTableFullName))
        output += ("add constraint ")
        constraintColumns = []
        
        # Check new name for constraint
        cNewName = "%s_pkey" % newTableName if renameConstraints else pkey["conname"]

        output += (cNewName+"\nprimary key(")
        c = ""

        for i in pkey["columns"]:
            c += (i+", ")

        output += (c[:-2]+");")


    # Write geom indices

    output += ("\n")

    sql = """
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
        b.opcname='gist_geometry_ops_2d' and
        a.schemaname=%s and 
        a.tablename=%s
    """

    cur.execute(sql, (tableSchema, tableName))

    for i in cur:
        # Check new name for constraint
        cNewName = "%s_%s_gist" % (newTableName, i["columnname"]) \
                        if renameConstraints else i["indexname"]

        output += ("""
create index %s
on %s
using gist(%s);
    """ % (cNewName, newTableFullName, i["columnname"]))


    # Copy from

    output += ("""
\copy %s from %s.csv with delimiter ',' csv header quote '"' encoding 'utf-8' null '-'
""" % (newTableFullName, newTableName))


    # Final vacuum

    output += ("""
vacuum analyze %s;
""" % (newTableFullName))

    # Copy script
    copyScript = """--Export %s.%s\n\n\copy (select * from %s.%s) to %s.csv with delimiter ',' csv header quote '"' encoding 'utf-8' null '-'""" % (tableSchema, tableName, tableSchema, tableName, newTableName)

    # Close database objects
    cur.close()
    conn.close()

    # Return final result
    return output, copyScript
