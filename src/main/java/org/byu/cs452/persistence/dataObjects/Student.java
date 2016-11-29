package org.byu.cs452.persistence.dataObjects;


import com.datastax.driver.core.Row;

/**
 * @author blissrj
 */
@SuppressWarnings("ALL")
public class Student {
  public static final String ID = "ID";
  public static final String NAME = "name";
  public static final String DEPARTMENT_NAME = "dept_name";
  public static final String TOTAL_CREDITS = "tot_cred";

  public static final String TABLE_NAME = "student";

  public static final String CREATE_STUDENT_CQL_STMT = String.format(
      "CREATE TABLE IF NOT EXISTS %1$s (ID TEXT, name TEXT, dept_name TEXT, tot_cred INT, PRIMARY KEY(ID))"
      , TABLE_NAME);

  private String id;
  private String name;
  private String departmentName;
  private int totalCredits;

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public String getDepartmentName() {
    return departmentName;
  }

  public void setDepartmentName(String departmentName) {
    this.departmentName = departmentName;
  }

  public int getTotalCredits() {
    return totalCredits;
  }

  public void setTotalCredits(int totalCredits) {
    this.totalCredits = totalCredits;
  }

  public static String tableName() {
    return TABLE_NAME;
  }

  public static String columnNames() {
    return String.join(",", ID, NAME, DEPARTMENT_NAME, TOTAL_CREDITS);
  }

  public static Student getInstance(Row row) {
    Student student = new Student();
      student.setId(row.getString(ID));
      student.setName(row.getString(NAME));
      student.setDepartmentName(row.getString(DEPARTMENT_NAME));
      student.setTotalCredits(row.getInt(TOTAL_CREDITS));
      return student;
  }
}
