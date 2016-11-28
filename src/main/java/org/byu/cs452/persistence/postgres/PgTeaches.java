package org.byu.cs452.persistence.postgres;

import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * @author blissrj
 */
@SuppressWarnings("ALL")
public class PgTeaches {
  public static final String ID = "ID";
  public static final String COURSE_ID = "course_id";
  public static final String SECTION_ID = "sec_id";
  public static final String SEMESTER = "semester";
  public static final String YEAR = "year";

  public static final String TABLE_NAME = "teaches";

  private String id;
  private String course_id;
  private String section_id;
  private String semester;
  private int year;

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

  public static String tableName() {
    return TABLE_NAME;
  }

  public static String columnNames() {
    return String.join(",", ID, COURSE_ID, SECTION_ID, SEMESTER, YEAR);
  }

  public static PgTeaches getInstance(ResultSet resultSet) {
    PgTeaches teaches = new PgTeaches();
    try {
      teaches.setId(resultSet.getString(ID));
      teaches.setCourse_id(resultSet.getString(COURSE_ID));
      teaches.setSection_id(resultSet.getString(SECTION_ID));
      teaches.setSemester(resultSet.getString(SEMESTER));

      teaches.setYear(resultSet.getInt(YEAR));
      return teaches;
    }
    catch (SQLException e) {
      throw new RuntimeException("Failed to populate PgTeaches from ResultSet", e);
    }
  }
}
