package org.byu.cs452.persistence.dataObjects;

import com.datastax.driver.core.Row;

import java.util.UUID;

/**
 * @author blissrj
 */
@SuppressWarnings("ALL")
public class InstructorCourse {
  public static final String ID = "ID";
  public static final String RECORD_ID = "record_id";
  public static final String COURSE_ID = "course_id";
  public static final String SECTION_ID = "sec_id";
  public static final String SEMESTER = "semester";
  public static final String YEAR = "year";

  public static final String TABLE_NAME = "instructorCourses";

  public static final String CREATE_INSTRUCTOR_COURSES_CQL_STMT = String.format(
      "CREATE TABLE IF NOT EXISTS %1$s (" +
          "ID TEXT, record_id TIMEUUID, course_id TEXT, sec_id TEXT, semester TEXT, year INT, " +
          "PRIMARY KEY((ID), record_id))"
      , TABLE_NAME);

  private String id;
  private UUID recordId;
  private String courseId;
  private String sectionId;
  private String semester;
  private int year;

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

  public static String tableName() {
    return TABLE_NAME;
  }

  public static String columnNames() {
    return String.join(",", ID, RECORD_ID, COURSE_ID, SECTION_ID, SEMESTER, YEAR);
  }

  public static InstructorCourse getInstance(Row row) {
    InstructorCourse instructorCourse = new InstructorCourse();
    instructorCourse.setId(row.getString(ID));
    instructorCourse.setRecordId(row.getUUID(RECORD_ID));
    instructorCourse.setCourseId(row.getString(COURSE_ID));
    instructorCourse.setSectionId(row.getString(SECTION_ID));
    instructorCourse.setSemester(row.getString(SEMESTER));
    instructorCourse.setYear(row.getInt(YEAR));
    return instructorCourse;
  }
}
