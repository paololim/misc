select school_years.name as school_year, grades.name as grade, count(*)
  from enrollments
  join grades on grades.id = enrollments.grade_id
  left join school_years on enrollments.enrolled_at >= school_years.begins_at  and enrollments.enrolled_at < school_years.ends_at
 group by school_years.name, school_years.begins_at, grades.name, grades.position
 order by school_years.begins_at, grades.position;
