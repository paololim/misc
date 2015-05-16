create table campuses (
  id        bigserial primary key,
  name      text not null unique
);

insert into campuses (name) values ('Morris Plains');
insert into campuses (name) values ('New Milford');

create table school_years (
  id        bigserial primary key,
  name      text not null,
  begins_at timestamptz not null unique,
  ends_at   timestamptz not null unique,
  constraint school_years_ends_at_after_begins_at_ck check (ends_at > begins_at)
);

insert into school_years (name, begins_at, ends_at) values ('07 - 08', '07-09-01 00:00:00', '2008-08-31 00:00:00');
insert into school_years (name, begins_at, ends_at) values ('08 - 09', '2008-09-01 00:00:00', '2009-08-31 00:00:00');
insert into school_years (name, begins_at, ends_at) values ('09 - 10', '2009-09-01 00:00:00', '2010-08-31 00:00:00');
insert into school_years (name, begins_at, ends_at) values ('10 - 11', '2010-09-01 00:00:00', '2011-08-31 00:00:00');
insert into school_years (name, begins_at, ends_at) values ('11 - 12', '2011-09-01 00:00:00', '2012-08-31 00:00:00');
insert into school_years (name, begins_at, ends_at) values ('12 - 13', '2012-09-01 00:00:00', '2013-08-31 00:00:00');
insert into school_years (name, begins_at, ends_at) values ('13 - 14', '2013-09-01 00:00:00', '2014-08-31 00:00:00');

create table grades (
  id        bigserial primary key,
  name      text not null unique,
  position  smallint not null unique check (position >= 1)
);

insert into grades (position, name) values (1, 'Pre-K 2');
insert into grades (position, name) values (2, 'Pre-K 3');
insert into grades (position, name) values (3, 'Pre-K 4');
insert into grades (position, name) values (4, 'K');
insert into grades (position, name) values (5, '1st');
insert into grades (position, name) values (6, '2nd');
insert into grades (position, name) values (7, '3rd');
insert into grades (position, name) values (8, '4th');
insert into grades (position, name) values (9, '5th');

create table students (
  id               bigserial primary key,
  name             text not null
);

create table enrollments (
  id               bigserial primary key,
  student_id       bigint not null references students,
  grade_id         bigint not null references grades,
  campus_id        bigint not null references campuses,
  enrolled_at      timestamptz not null
);

