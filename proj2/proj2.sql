--Q1:
drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function q1(course_id integer)
    returns RoomRecord
as $$
declare
      rec RoomRecord;
      course_student_num integer;
      course_wait_student_num integer;
      course_all_student_num integer;
begin
    IF $1 NOT IN (SELECT id FROM courses) 
    THEN RAISE EXCEPTION 'INVALID COURSEID';
    END IF;	
    course_student_num := (select count(*) from course_enrolments where course = $1);
    course_wait_student_num := (select count(*) from course_enrolment_waitlist where course = $1);
    course_all_student_num := course_student_num + course_wait_student_num;
    select count(*) into rec.valid_room_number
    from rooms
    where rooms.capacity >= course_student_num;
    select count(*) into rec.bigger_room_number from rooms
    where rooms.capacity >= course_all_student_num;    return rec;   
end;
$$ language plpgsql;

--Q2:
drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
declare
	rec TeachingRecord;
	x integer;
begin 
	select course_staff.staff into x
	from course_staff
	where course_staff.staff = $1;
	IF $1 NOT IN (SELECT staff FROM course_staff) 
	THEN RAISE EXCEPTION 'INVALID STAFFID';
  	END IF;	
	for rec in 
		select courses.id,
		substr(Semesters.year::text,3,2)||lower(Semesters.term), 
		subjects.code,
		subjects.name,
		subjects.uoc,
		round(avg(course_enrolments.mark)),
		round(max(course_enrolments.mark)),
		0,
		0
		from course_staff, Course_enrolments, Courses, Subjects, Semesters
		where course_staff.staff = x
		and course_staff.course = courses.id
		and courses.id = Course_enrolments.course
		and courses.subject = subjects.id
		and Courses.semester = Semesters.id
		group by courses.id, substr(semesters.year::text,3,2)||lower(semesters.term), 
		subjects.code,
		subjects.name,
		subjects.uoc
	loop	
		SELECT CASE 
		WHEN countt % 2 = 0 AND countt > 1 
		THEN (arrayy[1]+ arrayy[2])/2 ELSE arrayy[1] END
		FROM
		(
 		SELECT ARRAY(SELECT course_enrolments.mark 
		FROM course_enrolments 
		where course_enrolments.course = rec.cid 
		ORDER BY course_enrolments.mark OFFSET (countt-1)/2) AS arrayy, countt
	        FROM (SELECT count(*) AS countt 
		FROM course_enrolments 
		where course_enrolments.mark is not null 
		and course_enrolments.course = rec.cid) AS count
		 OFFSET 0
		)
		AS medians into rec.median_mark;		
		
		select count(*) into rec.totalEnrols from Course_enrolments
			where course = rec.cid and mark is not null;
		return next rec;
	end loop;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

--Q3:
create or replace function collectOrgunits(org_id integer) returns setof integer
as $$
begin
     return query 
     with recursive
     collectOrgunits(main_id, sub_org) as (select owner, member as sub_org from orgunit_groups
     union
     ]select collectOrgunits.main_id, ogg.member
     from collectOrgunits, orgunit_groups ogg
     where collectOrgunits.sub_org = ogg.owner)
     select sub_org from collectOrgunits where main_id = $1
     union
     select $1;
end;
$$ language plpgsql;

create or replace function collectCourses(org_id integer) returns setof integer
as $$
begin
     return query
     select c.id from subjects s, courses c, (select * from collectOrgunits($1)) as org
     where s.offeredby = org.collectOrgunits
     and c.subject = s.id;
end;
$$ language plpgsql;

create or replace function collectStudents(org_id integer, num_courses integer, min_score integer) returns setof integer
as $$
begin
     return query
     select ce.student 
     from course_enrolments ce, (select * from collectCourses($1)) as collected_course, people p
     where ce.course = collected_course.collectCourses
     and ce.student = p.id
     group by ce.student, p.unswid having count(*) > $2 and max(ce.mark) >= $3
     order by p.unswid asc;
end;
$$ language plpgsql;

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
declare
	i integer := 0;
	tmp_rec record;
	rec record;
	c_rec CourseRecord;
begin
	IF $1 NOT IN (SELECT id FROM orgunits) 
	THEN RAISE EXCEPTION 'INVALID ORGID';
  	END IF;	
for tmp_rec in 
	select collectStudents from collectStudents($1, $2, $3)
loop
	c_rec.course_records = '';
	i = 0;
for rec in 
	select p.unswid as unswid, p.name as name, sj.code as sub_code, sj.name as sub_name, sm.name as semester,  og.name as org, ce.mark as mark
	from course_enrolments ce, semesters sm ,subjects sj, courses c, orgunits og, people p, (select * from collectCourses($1)) as org_courses
	where c.semester = sm.id
	and c.id = ce.course
	and c.subject = sj.id
	and sj.offeredby = og.id 
	and c.id = org_courses.collectCourses
	and p.id = ce.student
	and p.id = tmp_rec.collectStudents
	order by ce.mark desc nulls last, c.id asc
loop
	i = i + 1;
	if (i > 5) 
	then exit;
	end if;
	c_rec.student_name = rec.name;
	c_rec.unswid = rec.unswid;
	c_rec.course_records = c_rec.course_records || rec.sub_code ||', '|| rec.sub_name ||', '||rec.semester||', '||rec.org||', ';
	if (rec.mark is not Null) 
	then c_rec.course_records = c_rec.course_records||rec.mark||chr(10);  
	else c_rec.course_records = c_rec.course_records||'Null'||chr(10);
	end if;
	end loop;
	return next c_rec;
end loop;
end;
$$ language plpgsql;

