package org.byu.cs452.persistence.postgres;

import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * @author blissrj
 */
public class PgTakes {
  public static final String ID = "ID";
  public static final String COURSE_ID = "course_id";
  public static final String SECTION_ID = "sec_id";
  public static final String SEMESTER = "semester";
  public static final String YEAR = "year";
  public static final String GRADE = "grade";
  public static final String TABLE_NAME = "takes";

  private String id;
  private String course_id;
  private String section_id;
  private String semester;
  private int year;
  private String grade;

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public String getCourse_id() {
    return course_id;
  }

  public void setCourse_id(String course_id) {
    this.course_id = course_id;
  }

  public String getSection_id() {
    return section_id;
  }

  public void setSection_id(String section_id) {
    this.section_id = section_id;
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
    return String.join(",", ID, COURSE_ID, SECTION_ID, SEMESTER, YEAR, GRADE);
  }

  public static PgTakes getInstance(ResultSet resultSet) {
    PgTakes takes = new PgTakes();
    try {
      takes.setId(resultSet.getString(ID));
      takes.setCourse_id(resultSet.getString(COURSE_ID));
      takes.setSection_id(resultSet.getString(SECTION_ID));
      takes.setSemester(resultSet.getString(SEMESTER));
      takes.setYear(resultSet.getInt(YEAR));
      takes.setGrade(resultSet.getString(GRADE));
      return takes;
    }
    catch (SQLException e) {
      throw new RuntimeException("Failed to populate PgStudent from ResultSet", e);
    }
  }
}
