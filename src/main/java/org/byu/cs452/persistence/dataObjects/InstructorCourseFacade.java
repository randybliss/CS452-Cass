package org.byu.cs452.persistence.dataObjects;

/**
 * @author blissrj
 */
public class InstructorCourseFacade {
  private String courseId;
  private String section;
  private String semester;
  private int year;

  public InstructorCourseFacade(InstructorCourse instructorCourse) {
    this.courseId = instructorCourse.getCourseId();
    this.section = instructorCourse.getSectionId();
    this.semester = instructorCourse.getSemester();
    this.year = instructorCourse.getYear();
  }

  public String getCourseId() {
    return courseId;
  }

  public String getSection() {
    return section;
  }

  public String getSemester() {
    return semester;
  }

  public int getYear() {
    return year;
  }
}
