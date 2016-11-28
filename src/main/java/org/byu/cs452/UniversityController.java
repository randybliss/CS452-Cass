package org.byu.cs452;

import org.byu.cs452.persistence.*;
import org.byu.cs452.persistence.dataObjects.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

/**
 * @author blissrj
 */
@RestController
public class UniversityController {

  private UniversityStore universityStore;

  @Autowired
  public UniversityController(UniversityStore universityStore) {
    this.universityStore = universityStore;
  }

  @RequestMapping(path = "/slurp", method = RequestMethod.GET)
  public String slurp() {
    return universityStore.slurp();
  }

  @RequestMapping(path = "/student/schedule", method = RequestMethod.GET)
  public List<StudentSchedule> getSchedules() {
    List<StudentSchedule> schedules = new ArrayList<>();
    List<Student> students = universityStore.readStudents();
    for (Student student : students) {
      List<StudentCourse> courseList = universityStore.readStudentCourses(student.getId());
      StudentSchedule schedule = new StudentSchedule(student);
      for (StudentCourse studentCourse : courseList) {
        schedule.addCourse(new StudentCourseFacade(studentCourse));
      }
      schedules.add(schedule);
    }
    return schedules;
  }

  @RequestMapping(path = "/student/schedule/{id}", method = RequestMethod.GET)
  public StudentSchedule getSchedule(@PathVariable String id) {
    Student student = universityStore.readStudent(id);
    StudentSchedule schedule = new StudentSchedule(student);
    List<StudentCourse> courseList = universityStore.readStudentCourses(id);
    for (StudentCourse studentCourse : courseList) {
      schedule.addCourse(new StudentCourseFacade(studentCourse));
    }
    return schedule;
  }

  @RequestMapping(path = "/instructor/schedule", method = RequestMethod.GET)
  public List<InstructorSchedule> getInstructorSchedules() {
    List<InstructorSchedule> schedules = new ArrayList<>();
    List<Instructor> instructors = universityStore.readInstructors();
    for (Instructor instructor : instructors) {
      List<InstructorCourse> courseList = universityStore.readInstructorCourses(instructor.getId());
      InstructorSchedule schedule = new InstructorSchedule(instructor);
      for (InstructorCourse instructorCourse : courseList) {
        schedule.addCourse(new InstructorCourseFacade(instructorCourse));
      }
      schedules.add(schedule);
    }
    return schedules;
  }
  @RequestMapping(path = "/instructor/schedule/{id}")
  public InstructorSchedule getInstructorSchedule(@PathVariable String id) {
    Instructor instructor = universityStore.readInstructor(id);
    InstructorSchedule schedule = new InstructorSchedule(instructor);
    List<InstructorCourse> courseList = universityStore.readInstructorCourses(id);
    for (InstructorCourse instructorCourse : courseList) {
      schedule.addCourse(new InstructorCourseFacade(instructorCourse));
    }
    return schedule;
  }
}
