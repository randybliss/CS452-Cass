package org.byu.cs452.persistence;

import com.datastax.driver.core.*;
import org.apache.cassandra.thrift.NotFoundException;
import org.byu.cs452.persistence.cassandra.CassandraDatabaseOps;
import org.byu.cs452.persistence.postgres.PgStudent;
import org.byu.cs452.persistence.postgres.PgTakes;
import org.byu.cs452.persistence.postgres.PostgresDatabaseOps;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * @author blissrj
 */
@Service
public class UniversityStore {
  private static final String CREATE_STUDENT_CQL_STMT = String.format(
      "CREATE TABLE IF NOT EXISTS %1$s (" +
          "ID TEXT, name TEXT, dept_name TEXT, tot_cred INT, PRIMARY KEY(ID))"
      , Student.tableName());

  private static final String CREATE_STUDENT_COURSES_CQL_STMT = String.format(
      "CREATE TABLE IF NOT EXISTS %1$s (" +
          "ID TEXT, record_id TIMEUUID, course_id TEXT, sec_id TEXT, semester TEXT, year INT, grade TEXT, " +
          "PRIMARY KEY((ID), record_id))"
      , StudentCourse.tableName());

  private CassandraDatabaseOps cassandraDatabaseOps;
  private PostgresDatabaseOps postgresDatabaseOps;
  private Session session;

  @Autowired
  public UniversityStore(CassandraDatabaseOps cassandraDatabaseOps, PostgresDatabaseOps postgresDatabaseOps) {
    this.cassandraDatabaseOps = cassandraDatabaseOps;
    this.postgresDatabaseOps = postgresDatabaseOps;
    init();
  }

  private void init() {
    this.session = cassandraDatabaseOps.getSession();
    ensureTableCreated(CREATE_STUDENT_CQL_STMT);
    ensureTableCreated(CREATE_STUDENT_COURSES_CQL_STMT);
  }

  public Student readStudent(String id) {
    String cqlString = String.format("SELECT %1$s FROM %2$s WHERE id=?", Student.columnNames(), Student.tableName());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement selectStatement = preparedStatement.bind(id);
    ResultSet resultSet = session.execute(selectStatement);
    Row row = resultSet.one();
    if (row == null) {
      throw new RecordNotFoundException(String.format("Record not found for student id: %1$s", id));
    }
    return Student.getInstance(row);
  }

  public List<Student> readStudents() {
    List<Student> students = new ArrayList<>();
    String cqlString = String.format("SELECT %1$s FROM %2$s", Student.columnNames(), Student.tableName());
    ResultSet resultSet = session.execute(cqlString);
    for (Row row : resultSet) {
      students.add(Student.getInstance(row));
    }
    return students;
  }

  public void writeStudent(Student student) {
    String cqlString = String.format("INSERT INTO %1$s (%2$s) VALUES(?,?,?,?)", Student.tableName(), Student.columnNames());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement insertStatement = preparedStatement.bind(student.getId(), student.getName(), student.getDepartmentName(), student.getTotalCredits());
    ResultSet resultSet = session.execute(insertStatement);
    if (!resultSet.wasApplied()) {
      throw new RuntimeException("Insert student failed");
    }
  }

  public List<StudentCourse> readStudentCourses(String id) {
    List<StudentCourse> studentCourses = new ArrayList<>();
    String cqlString = String.format("SELECT %1$s FROM %2$s WHERE ID=?", StudentCourse.columnNames(), StudentCourse.tableName());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement selectStatement = preparedStatement.bind(id);
    ResultSet resultSet = session.execute(selectStatement);
    for (Row row : resultSet) {
      studentCourses.add(StudentCourse.getInstance(row));
    }
    return studentCourses;
  }

  public void writeStudentCourse(StudentCourse studentCourse) {
    String cqlString = String.format("INSERT INTO %1$s (%2$s) VALUES(?,now(),?,?,?,?,?)", StudentCourse.tableName(), StudentCourse.columnNames());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement insertStatement = preparedStatement.bind(
        studentCourse.getId(),
        studentCourse.getCourseId(),
        studentCourse.getSectionId(),
        studentCourse.getSemester(),
        studentCourse.getYear(),
        studentCourse.getGrade());
    ResultSet resultSet = session.execute(insertStatement);
    if (!resultSet.wasApplied()) {
      throw new RuntimeException("Insert studentCourse failed");
    }
  }

  public String slurp() {
    try (Connection conn = postgresDatabaseOps.getConnection()){
      //Copy postgreSQL student table to Cassandra student table
      String sqlString = String.format("SELECT %1$s FROM %2$s", PgStudent.columnNames(), PgStudent.tableName());
      java.sql.PreparedStatement statement = conn.prepareStatement(sqlString);
      java.sql.ResultSet resultSet = statement.executeQuery();
      while (resultSet.next()) {
        PgStudent pgStudent = PgStudent.getInstance(resultSet);
        Student student = new Student();
        student.setId(pgStudent.getId());
        student.setName(pgStudent.getName());
        student.setDepartmentName(pgStudent.getDepartmentName());
        student.setTotalCredits(pgStudent.getTotalCredits());
        writeStudent(student);
      }
      //Copy postgreSQL takes table to Cassandra studentcourses table
      sqlString = String.format("SELECT %1$s FROM %2$s order by year ASC, semester ASC", PgTakes.columnNames(), PgTakes.tableName());
      statement = conn.prepareStatement(sqlString);
      resultSet = statement.executeQuery();
      while (resultSet.next())  {
        PgTakes takes = PgTakes.getInstance(resultSet);
        StudentCourse studentCourse = new StudentCourse();
        studentCourse.setId(takes.getId());
        studentCourse.setCourseId(takes.getCourse_id());
        studentCourse.setSectionId(takes.getSection_id());
        studentCourse.setSemester(takes.getSemester());
        studentCourse.setYear(takes.getYear());
        studentCourse.setGrade(takes.getGrade());
        writeStudentCourse(studentCourse);
      }
    }
    catch (SQLException e) {
      throw new RuntimeException("Unexpected database exception attempting to read postgres students", e);
    }
    return "SUCCESS";
  }

  private void ensureTableCreated(String cqlStatementString) {
    session.execute(cqlStatementString);
  }
}
