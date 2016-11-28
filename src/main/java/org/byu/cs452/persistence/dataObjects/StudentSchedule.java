package org.byu.cs452.persistence.dataObjects;

import java.util.ArrayList;
import java.util.List;

/**
 * @author blissrj
 */
public class StudentSchedule {
  private Student student;
  private List<StudentCourseFacade> schedule;

  public StudentSchedule(Student student) {
    this.student = student;
    this.schedule = new ArrayList<>();
  }

  public void addCourse(StudentCourseFacade courseFacade) {
    this.schedule.add(courseFacade);
  }

  public Student getStudent() {
    return student;
  }

  public List<StudentCourseFacade> getSchedule() {
    return schedule;
  }
}
