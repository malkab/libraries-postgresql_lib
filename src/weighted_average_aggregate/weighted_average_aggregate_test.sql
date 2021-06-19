begin;

create schema a;

create table a.data(
  val numeric,
  wei numeric,
  grp char
);

insert into a.data values
(2,4,'a'),
(4,3,'a'),
(5,10,'b'),
(8,15,'b');

select avg(val), wavg(val, wei)
from a.data
group by grp;

commit;
