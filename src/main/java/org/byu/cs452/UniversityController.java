package org.byu.cs452;

import org.byu.cs452.persistence.*;
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

  @RequestMapping(path = "/")
  public String index() {
    return "Greetings from CS452 University app running on Cassandra";
  }

  @RequestMapping(path = "/student/slurp", method = RequestMethod.PUT)
  public String slurp() {
    return universityStore.slurp();
  }

  @RequestMapping(path = "/student/schedule", method = RequestMethod.GET)
  public List<Schedule> getSchedules() {
    List<Schedule> schedules = new ArrayList<>();
    List<Student> students = universityStore.readStudents();
    for (Student student : students) {
      List<StudentCourse> courseList = universityStore.readStudentCourses(student.getId());
      Schedule schedule = new Schedule(student);
      for (StudentCourse studentCourse : courseList) {
        schedule.addCourse(new CourseFacade(studentCourse));
      }
      schedules.add(schedule);
    }
    return schedules;
  }

  @RequestMapping(path = "/student/schedule/{id}", method = RequestMethod.GET)
  public Schedule getSchedule(@PathVariable String id) {
    Student student = universityStore.readStudent(id);
    Schedule schedule = new Schedule(student);
    List<StudentCourse> courseList = universityStore.readStudentCourses(id);
    for (StudentCourse studentCourse : courseList) {
      schedule.addCourse(new CourseFacade(studentCourse));
    }
    return schedule;
  }
}
