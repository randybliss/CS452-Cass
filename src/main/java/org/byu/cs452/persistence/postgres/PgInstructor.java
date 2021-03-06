package org.byu.cs452.persistence.postgres;

import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * @author blissrj
 */
@SuppressWarnings("ALL")
public class PgInstructor {
  public static final String ID = "ID";
  public static final String NAME = "name";
  public static final String DEPARTMENT_NAME = "dept_name";
  public static final String SALARY = "salary";

  public static final String TABLE_NAME = "instructor";

  private String id;
  private String name;
  private String departmentName;
  private int salary;

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

  public int getSalary() {
    return salary;
  }

  public void setSalary(int salary) {
    this.salary = salary;
  }

  public static String tableName() {
    return TABLE_NAME;
  }

  public static String columnNames() {
    return String.join(",", ID, NAME, DEPARTMENT_NAME, SALARY);
  }

  public static PgInstructor getInstance(ResultSet resultSet) {
    PgInstructor instructor = new PgInstructor();
    try {
      instructor.setId(resultSet.getString(ID));
      instructor.setName(resultSet.getString(NAME));
      instructor.setDepartmentName(resultSet.getString(DEPARTMENT_NAME));
      instructor.setSalary(resultSet.getInt(SALARY));
      return instructor;
    }
    catch (SQLException e) {
      throw new RuntimeException("Failed to populate PgStudent from ResultSet", e);
    }
  }
}
