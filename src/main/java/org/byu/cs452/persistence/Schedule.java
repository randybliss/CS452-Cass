package org.byu.cs452.persistence;

import java.util.ArrayList;
import java.util.List;

/**
 * @author blissrj
 */
public class Schedule {
  private Student student;
  private List<CourseFacade> schedule;

  public Schedule(Student student) {
    this.student = student;
    this.schedule = new ArrayList<>();
  }

  public void addCourse(CourseFacade courseFacade) {
    this.schedule.add(courseFacade);
  }

  public Student getStudent() {
    return student;
  }

  public List<CourseFacade> getSchedule() {
    return schedule;
  }
}
