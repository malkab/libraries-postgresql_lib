/**

  -----------------------------------------------------

  Clocking tests.

  ETE: Estimated time of execution

  -----------------------------------------------------

*/
-- Update library
\i clocking.sql

select * from mlk_clockstart('test');

begin;

SELECT pg_sleep(1);

commit;

select * from mlk_clockstep('step 0', 'test');

begin;

SELECT pg_sleep(1);

commit;

select * from mlk_clockstep('step 1', 'test');

begin;

SELECT pg_sleep(1);

commit;

select * from mlk_clockstop('test');

select * from mlk_clocklog('test');
