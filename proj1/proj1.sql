-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: 
create or replace view Q1(unswid, name)
as
select people.unswid, people.name
from people, students,course_enrolments
where students.id = people.id
and course_enrolments.student = students.id
and students.stype = 'intl'
and course_enrolments.mark >= 85
group by people.unswid, people.name having count(course_enrolments.course)>20
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: 
create or replace view Q2(unswid, name)
as
select rooms.unswid, rooms.longname
from rooms, room_types
where room_types.id = rooms.rtype
and rooms.building = 100
and room_types.id = 7
and rooms.capacity >= 20
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: 
create or replace view Q3(unswid, name)
as
select people.unswid, people.name
from people, course_staff
where people.id = course_staff.staff
and course_staff.course in
(select course_enrolments.course 
from course_enrolments, people
where people.id = course_enrolments.student
and people.name = 'Stefan Bilek')
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4:
create or replace view Q4(unswid, name)
as
select people.unswid, people.name
from people, course_enrolments, subjects, courses
where people.id = course_enrolments.student
and course_enrolments.course = courses.id
and courses.subject = subjects.id
and subjects.code = 'COMP3331'
and people.id not in
(select people.id
from people, course_enrolments, subjects, courses
where people.id = course_enrolments.student
and course_enrolments.course = courses.id
and courses.subject = subjects.id
and subjects.code = 'COMP3231')
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q5: 
create or replace view Q5a(num)
as
select count(Distinct students.id)
from students, stream_enrolments, program_enrolments, streams
where students.id = program_enrolments.student
and program_enrolments.id = stream_enrolments.partof
and stream_enrolments.stream = streams.id
and program_enrolments.semester = 167
and students.stype = 'local'
and streams.name = 'Chemistry'
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q5: 
create or replace view Q5b(num)
as
select count(Distinct students.id)
from students, program_enrolments, orgunits, programs
where students.id = program_enrolments.student
and programs.id = program_enrolments.program
and programs.offeredby = orgunits.id
and program_enrolments.semester = 167
and students.stype = 'intl'
and orgunits.longname = 'School of Computer Science and Engineering'
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q6:
create or replace function Q6(text) returns text
as 
$$select concat(code,' ',name,' ',uoc) as text from subjects
where code = $1
--... SQL statements, possibly using other views/functions defined by you ...
$$ language sql;



-- Q7: 
CREATE OR REPLACE VIEW public.q7_1 AS 
 SELECT programs.id,
    programs.code,
    programs.name,
    count(students.id) AS count_all
   FROM programs,
    students,
    program_enrolments
  WHERE program_enrolments.student = students.id AND program_enrolments.program = programs.id
  GROUP BY programs.id;
CREATE OR REPLACE VIEW public.q7_2 AS 
 SELECT programs.id,
    programs.code,
    programs.name,
    count(students.id) AS count_intl
   FROM programs,
    students,
    program_enrolments
  WHERE program_enrolments.student = students.id AND program_enrolments.program = programs.id AND students.stype::text = 'intl'::text
  GROUP BY programs.id;
create or replace view Q7(code, name)
as
select programs.code, programs.name
from programs, q7_1, q7_2
where programs.id = q7_1.id
and q7_1.id = q7_2.id
and (1.00*q7_2.count_intl/q7_1.count_all)*100 > 50
--... SQL statements, possibly using other views/functions defined by you ...
;


-- Q8:
create or replace view Q8_1(course_id, avg_mark)
as
select course_enrolments.course, avg(course_enrolments.mark)
from course_enrolments
where course_enrolments.mark is not null
group by course_enrolments.course
having count(course_enrolments.mark) > 15;
create or replace view Q8_2(max_avg_mark)
as
select max(avg_mark) from q8_1;
create or replace view Q8(code, name, semester)
as
select subjects.code, subjects.name, semesters.name
from q8_1, q8_2, subjects, semesters, course_enrolments, courses
where courses.id = course_enrolments.course
and courses.subject = subjects.id
and semesters.id = courses.semester
and q8_1.course_id = courses.id
and q8_1.avg_mark = Q8_2.max_avg_mark
group by subjects.code, subjects.name, semesters.name
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q9:
create or replace view Q9_1(id, name, school, email, starting)
as
select people.id, people.name, orgunits.longname, people.email, affiliations.starting
from people, staff, orgunits, affiliations, orgunit_types, staff_roles
where people.id = staff.id 
and orgunits.id = affiliations.orgunit 
and affiliations.staff = staff.id
and orgunit_types.id = orgunits.utype
and staff_roles.id = affiliations.role
and staff_roles.name = 'Head of School'
and affiliations.ending is null
and affiliations.isprimary = True
and orgunit_types.name = 'School';
create or replace view Q9_2(id,num_subjects)
as
select q9_1.id, count(Distinct subjects.code)
from q9_1, subjects, courses, course_staff
where course_staff.staff = q9_1.id
and courses.id = course_staff.course
and courses.subject = subjects.id 
group by q9_1.id;
create or replace view Q9(name, school, email, starting, num_subjects)
as
select q9_1.name, q9_1.school, q9_1.email, q9_1.starting, q9_2.num_subjects
from q9_1, q9_2
where q9_1.id = q9_2.id
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q10:
create or replace view Q10_1(sub_id, sub_code, sub_name)
as
SELECT Subjects.id, Subjects.code, Subjects.name
From Semesters,Subjects,Courses 
WHERE SUBSTR(Subjects.code,1,6)='COMP93' AND Subjects.id=Courses.subject 
AND Courses.semester=Semesters.id 
GROUP BY Subjects.id 
HAVING COUNT(Courses.id)=24 
;
create or replace view Q10_2(code, name, year, term, count_hd)
as
select Q10_1.sub_code, Q10_1.sub_name, SUBSTR(semesters.name,8,9), semesters.term, count(course_enrolments.mark)
from courses, course_enrolments, semesters, subjects, q10_1
where courses.id = course_enrolments.course
and semesters.id = courses.semester
and subjects.id = courses.subject
and subjects.id = q10_1.sub_id
and course_enrolments.grade = 'HD'
group by Q10_1.sub_code, Q10_1.sub_name, SUBSTR(semesters.name,8,9), semesters.term
;
create or replace view Q10_3(code, name, year, term, count_all)
as
select Q10_1.sub_code, Q10_1.sub_name, SUBSTR(semesters.name,8,9), semesters.term, count(course_enrolments.mark)
from courses, course_enrolments, semesters, subjects, q10_1
where courses.id = course_enrolments.course
and semesters.id = courses.semester
and subjects.id = courses.subject
and subjects.id = q10_1.sub_id
and course_enrolments.mark is not null
group by Q10_1.sub_code, Q10_1.sub_name, SUBSTR(semesters.name,8,9), semesters.term
;
create or replace view Q10_4(code, name, year, s1_HD_rate)
as
select q10_3.code, q10_3.name, Q10_3.year, cast(cast(q10_2.count_hd as float)/cast(q10_3.count_all as float) as numeric(4,2))
from q10_2, q10_3
where q10_3.code = q10_2.code
and q10_3.name = q10_2.name
and q10_2.year = q10_3.year
and q10_2.term = q10_3.term
and q10_2.term = 'S1'
group by q10_3.code, q10_3.name, Q10_3.year, cast(cast(q10_2.count_hd as float)/cast(q10_3.count_all as float) as numeric(4,2))
;
create or replace view Q10_5(code, name, year, s2_HD_rate)
as
select q10_3.code, q10_3.name, Q10_3.year, cast(cast(q10_2.count_hd as float)/cast(q10_3.count_all as float) as numeric(4,2))
from q10_2, q10_3
where q10_3.code = q10_2.code
and q10_3.name = q10_2.name
and q10_2.year = q10_3.year
and q10_2.term = q10_3.term
and q10_2.term = 'S2'
group by q10_3.code, q10_3.name, Q10_3.year, cast(cast(q10_2.count_hd as float)/cast(q10_3.count_all as float) as numeric(4,2))
;
create or replace view Q10_6(code, name, year)
as
select code, name, year
from q10_3
group by code, name, year
; 
create or replace view Q10_7(code, name, year, s1_HD_rate)
as
select q10_6.code, q10_6.name, q10_6.year, q10_4.s1_HD_rate
from q10_6
left join Q10_4
on q10_6.code = Q10_4.code
and q10_6.name = Q10_4.name
and q10_6.year = Q10_4.year
; 
create or replace view Q10_8(code, name, year, s1_HD_rate, s2_HD_rate)
as
select q10_7.code, q10_7.name, q10_7.year, q10_7.s1_HD_rate, Q10_5.s2_HD_rate
from q10_7
left join Q10_5
on q10_7.code = Q10_5.code
and q10_7.name = Q10_5.name
and q10_7.year = Q10_5.year
; 
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
select code, name, year, 
	case when s1_HD_rate is null then '0.00'
		else s1_HD_rate
	end s1_HD_rate,
	case when s2_HD_rate is null then '0.00'
		else s2_HD_rate
	end s2_HD_rate
from q10_8;
--... SQL statements, possibly using other views/functions defined by you ...
;
