package org.byu.cs452.persistence.dataObjects;

import com.datastax.driver.core.Row;

/**
 * @author blissrj
 */
@SuppressWarnings("ALL")
public class Instructor {
  public static final String ID = "ID";
  public static final String NAME = "name";
  public static final String DEPARTMENT_NAME = "dept_name";
  public static final String SALARY = "salary";

  public static final String TABLE_NAME = "instructor";

  public static final String CREATE_INSTRUCTOR_CQL_STMT = String.format(
      "CREATE TABLE IF NOT EXISTS %1$s (" +
          "ID TEXT, name TEXT, dept_name TEXT, salary INT, PRIMARY KEY(ID))", TABLE_NAME);

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

  public static Instructor getInstance(Row row) {
    Instructor instructor = new Instructor();
    instructor.setId(row.getString(ID));
    instructor.setName(row.getString(NAME));
    instructor.setDepartmentName(row.getString(DEPARTMENT_NAME));
    instructor.setSalary(row.getInt(SALARY));
    return instructor;
  }
}
