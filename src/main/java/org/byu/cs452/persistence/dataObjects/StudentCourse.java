package org.byu.cs452.persistence.dataObjects;

import com.datastax.driver.core.Row;

import java.util.UUID;

/**
 * @author blissrj
 */
@SuppressWarnings("ALL")
public class StudentCourse {
  public static final String ID = "ID";
  public static final String RECORD_ID = "record_id";
  public static final String COURSE_ID = "course_id";
  public static final String SECTION_ID = "sec_id";
  public static final String SEMESTER = "semester";
  public static final String YEAR = "year";
  public static final String GRADE = "grade";

  public static final String TABLE_NAME = "studentCourses";

  public static final String CREATE_STUDENT_COURSES_CQL_STMT = String.format(
      "CREATE TABLE IF NOT EXISTS %1$s (" +
          "ID TEXT, record_id TIMEUUID, course_id TEXT, sec_id TEXT, semester TEXT, year INT, grade TEXT, " +
          "PRIMARY KEY((ID), record_id))", TABLE_NAME);

  private String id;
  private UUID recordId;
  private String courseId;
  private String sectionId;
  private String semester;
  private int year;
  private String grade;

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public UUID getRecordId() {
    return recordId;
  }

  public void setRecordId(UUID recordId) {
    this.recordId = recordId;
  }

  public String getCourseId() {
    return courseId;
  }

  public void setCourseId(String courseId) {
    this.courseId = courseId;
  }

  public String getSectionId() {
    return sectionId;
  }

  public void setSectionId(String sectionId) {
    this.sectionId = sectionId;
  }

  public String getSemester() {
    return semester;
  }

  public void setSemester(String semester) {
    this.semester = semester;
  }

  public int getYear() {
    return year;
  }

  public void setYear(int year) {
    this.year = year;
  }

  public String getGrade() {
    return grade;
  }

  public void setGrade(String grade) {
    this.grade = grade;
  }

  public static String tableName() {
    return TABLE_NAME;
  }
  public static String columnNames() {
    return String.join(",", ID, RECORD_ID, COURSE_ID, SECTION_ID, SEMESTER, YEAR, GRADE);
  }

  public static StudentCourse getInstance(Row row) {
    StudentCourse studentCourse = new StudentCourse();
    studentCourse.setId(row.getString(ID));
    studentCourse.setRecordId(row.getUUID(RECORD_ID));
    studentCourse.setCourseId(row.getString(COURSE_ID));
    studentCourse.setSectionId(row.getString(SECTION_ID));
    studentCourse.setSemester(row.getString(SEMESTER));
    studentCourse.setYear(row.getInt(YEAR));
    studentCourse.setGrade(row.getString(GRADE));
    return studentCourse;
  }
}
