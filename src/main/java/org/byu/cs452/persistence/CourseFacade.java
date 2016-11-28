package org.byu.cs452.persistence;

/**
 * @author blissrj
 */
public class CourseFacade {
  private String courseId;
  private String section;
  private String semester;
  private int year;
  private String grade;

  public CourseFacade(StudentCourse studentCourse) {
    this.courseId = studentCourse.getCourseId();
    this.section = studentCourse.getSectionId();
    this.semester = studentCourse.getSemester();
    this.year = studentCourse.getYear();
    this.grade = studentCourse.getGrade();
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

  public String getGrade() {
    return grade;
  }
}
