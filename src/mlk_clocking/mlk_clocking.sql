/**

  -----------------------------------------------------

  Clocking functions to clock the total execution of a script.

  This functions must be used outside transactions, because all now() results
  are executed at commit time.

  Usage:

  Start clocking at the start of the script:
    select * from mlk_clockstart('optional name of clock');

  In the middle:
    select * from mlk_clockstep('optional name of clock', 'optional name of step');

  At the end of the script:
    select * from mlk_clockstop('optional name of clock');

  To check the log at any time:
    select * from mlk_clocklog('optional name of clock');

  -----------------------------------------------------

*/
begin;

/**

  Clean up.

*/
drop function if exists mlk_clockstart(varchar);

drop function if exists mlk_clockstep(varchar, varchar);

drop function if exists mlk_clockstop(varchar);

drop function if exists mlk_clocklog(varchar);

drop table if exists mlk_clocking;

/**

  Clock start function.

*/
create or replace function mlk_clockstart(
  _clock_name varchar default 'default'
)
returns timestamp as
$$
begin

  -- Create clocking table
  create table if not exists mlk_clocking(
    clock_name varchar,
    step_name varchar,
    time timestamp
  );

  -- Clean existing entries for current
  -- _clock_name
  delete from mlk_clocking
  where clock_name = _clock_name;

  insert into mlk_clocking
  values (_clock_name, 'start', now());

  return now();

end;
$$
language plpgsql;

/**

  Clock step function.

*/
create or replace function mlk_clockstep(
  _step_name varchar default 'step',
  _clock_name varchar default 'default'
)
returns table(step varchar, "time" timestamp, elapsed interval, accumulated interval) as
$$
begin

  insert into mlk_clocking
  values (_clock_name, _step_name, now());

  return query
    select
      step_name as step,
      a.time,
      coalesce(a.time - lead(a.time) over (order by a.time desc),
        interval '0 seconds') as elapsed,
      a.time - last_value(a.time) over () as accumulated
    from
      mlk_clocking a
    where clock_name = _clock_name
    order by a.time desc;

end;
$$
language plpgsql;

/**

  Clock stop function.

*/
create or replace function mlk_clockstop(
  _clock_name varchar default 'default'
)
returns table(step varchar, "time" timestamp, elapsed interval, accumulated interval) as
$$
begin

  insert into mlk_clocking
  values (_clock_name, 'stop', now());

  return query
    select
      step_name as step,
      a.time,
      coalesce(a.time - lead(a.time) over (order by a.time desc),
        interval '0 seconds') as elapsed,
      a.time - last_value(a.time) over () as accumulated
    from
      mlk_clocking a
    where clock_name = _clock_name
    order by a.time desc;

end;
$$
language plpgsql;

/**

  Clock log function.

*/
create or replace function mlk_clocklog(
  _clock_name varchar default 'default'
)
returns table(step varchar, "time" timestamp, elapsed interval, accumulated interval) as
$$
begin

  return query
    select
      step_name as step,
      a.time,
      coalesce(a.time - lead(a.time) over (order by a.time desc),
        interval '0 seconds') as elapsed,
      a.time - last_value(a.time) over () as accumulated
    from
      mlk_clocking a
    where clock_name = _clock_name
    order by a.time desc;

end;
$$
language plpgsql;

commit;
