select campuses.name as campus, grades.name as grade, school_years.name as school_year, count(*)
  from enrollments
  join grades on grades.id = enrollments.grade_id
  join campuses on campuses.id = enrollments.campus_id
  left join school_years on enrollments.enrolled_at >= school_years.begins_at  and enrollments.enrolled_at < school_years.ends_at
group by campuses.name, grades.name, grades.position, school_years.name, school_years.begins_at
order by campuses.name, grades.position, school_years.begins_at;
