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
begin

  -- Check if divisor is 0 or null
  if accums[2] is null or accums[2] = 0 then

    return null;

  else

    return accums[1] / accums[2];

  end if;

end;
$$ language 'plpgsql' strict;

create aggregate wavg(numeric, numeric) (
  INITCOND = '{0,0}',
  STYPE = numeric[2],
  SFUNC = wavg_accum,
  FINALFUNC = wavg_final
);

commit;
