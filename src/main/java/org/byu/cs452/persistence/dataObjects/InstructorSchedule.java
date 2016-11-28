package org.byu.cs452.persistence.dataObjects;

import java.util.ArrayList;
import java.util.List;

/**
 * @author blissrj
 */
public class InstructorSchedule {
  private Instructor instructor;
  private List<InstructorCourseFacade> schedule;

  public InstructorSchedule(Instructor instructor) {
    this.instructor = instructor;
    this.schedule = new ArrayList<>();
  }

  public void addCourse(InstructorCourseFacade courseFacade) {
    this.schedule.add(courseFacade);
  }

  public Instructor getInstructor() {
    return instructor;
  }

  public List<InstructorCourseFacade> getSchedule() {
    return schedule;
  }
}
