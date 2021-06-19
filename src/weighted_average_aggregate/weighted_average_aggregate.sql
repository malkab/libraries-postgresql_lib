begin;

create function wavg_accum(
  accums numeric[2],
  val numeric,
  wei numeric
) returns numeric[2] as $$

  select array[accums[1]+(val*wei), accums[2]+wei]::numeric[2];

$$ language 'sql' strict;

create function wavg_final(
  accums numeric[2]
) returns numeric as $$

  select accums[1] / accums[2];

$$ language 'sql' strict;

create aggregate wavg(numeric, numeric) (
  INITCOND = '{0,0}',
  STYPE = numeric[2],
  SFUNC = wavg_accum,
  FINALFUNC = wavg_final
);

commit;
