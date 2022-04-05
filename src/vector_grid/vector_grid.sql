begin;

/*

  A data type for the grid elements.

*/
create type public.gs__vector_grid_cell as (
  row integer,
  col integer,
  geom geometry
);

/*

  Returns a polygonal grid that covers a geometry at a regular step,
  with an optional bleed (overlapping of cells, set to 0 for no bleed).

*/
create or replace function public.gs__vector_grid(
  _geom geometry,
  _size float,
  _bleed float
) returns setof gs__vector_grid_cell as
$$
declare
  _bounds float[];
  _width float;
  _height float;
  _cols integer;
  _rows integer;
  _x float;
  _y float;
  _c integer;
  _r integer;
  _g geometry;
begin
  _bounds = gs__vector_grid_geomboundaries(_geom);
  _cols = ((_bounds[3]-_bounds[1])/_size)::integer;
  _rows = ((_bounds[4]-_bounds[2])/_size)::integer;

  if (_bounds[3]-_bounds[1])::numeric%_size::numeric<>0 then
    _cols = _cols+1;
  end if;

  if (_bounds[4]-_bounds[2])::numeric%_size::numeric<>0 then
    _rows = _rows+1;
  end if;

  _width = _cols*_size;
  _height = _rows*_size;

  _x = _bounds[1]-((_width-(_bounds[3]-_bounds[1]))/2);
  _y = _bounds[2]-((_height-(_bounds[4]-_bounds[2]))/2);

  for _c in 0.._cols-1 loop
    for _r in 0.._rows-1 loop
      _g = gs__vector_grid_rectangle(array[
        _x+(_c*_size)-_bleed,
        _y+(_r*_size)-_bleed,
        _x+(_c*_size)+_size+_bleed,
        _y+(_r*_size)+_size+_bleed
      ]::float[]);
      return next (_r, _c, _g)::gs__vector_grid_cell;
    end loop;
  end loop;
end;
$$
language plpgsql;

/*

  Returns a [minx,miny,maxx,maxy] for a geometry.

*/
create or replace function public.gs__vector_grid_geomboundaries(
  _geom geometry
) returns float[] as
$$
declare
  _g geometry;
  _minx float;
  _miny float;
  _maxx float;
  _maxy float;
begin
  _minx = st_xmin(_geom);
  _miny = st_ymin(_geom);
	_maxx = st_xmax(_geom);
	_maxy = st_ymax(_geom);

  return array[_minx,_miny,_maxx,_maxy]::float[];
end;
$$
language plpgsql;

/*

  Same as above, but gets a [minx,miny,maxx,maxy] parameter.

*/
create or replace function public.gs__vector_grid_rectangle(
  _array float[]
) returns geometry as
$$
declare
  _point_ll geometry;
  _point_lr geometry;
  _point_ul geometry;
  _point_ur geometry;
begin
  _point_ll = st_makepoint(_array[1], _array[2]);
  _point_lr = st_makepoint(_array[3], _array[2]);
  _point_ul = st_makepoint(_array[1], _array[4]);
  _point_ur = st_makepoint(_array[3], _array[4]);

  return st_makepolygon(
    st_makeline(array[
      _point_ll,
      _point_lr,
      _point_ur,
      _point_ul,
      _point_ll]));
end;
$$
language plpgsql;

commit;
