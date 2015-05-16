select campuses.name as campus, school_years.name as school_year, count(*)
  from enrollments
  join campuses on campuses.id = enrollments.campus_id
  join school_years on enrollments.enrolled_at >= school_years.begins_at  and enrollments.enrolled_at < school_years.ends_at
group by campuses.name, school_years.name, school_years.begins_at
order by campuses.name, school_years.begins_at;
