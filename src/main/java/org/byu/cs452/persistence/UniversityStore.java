package org.byu.cs452.persistence;

import com.datastax.driver.core.*;
import org.apache.commons.lang3.StringUtils;
import org.byu.cs452.persistence.cassandra.CassandraDatabaseOps;
import org.byu.cs452.persistence.dataObjects.Instructor;
import org.byu.cs452.persistence.dataObjects.InstructorCourse;
import org.byu.cs452.persistence.dataObjects.Student;
import org.byu.cs452.persistence.dataObjects.StudentCourse;
import org.byu.cs452.persistence.postgres.*;
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
  @SuppressWarnings({"FieldCanBeLocal", "unused"})
  private CassandraDatabaseOps cassandraDatabaseOps;
  private PostgresDatabaseOps postgresDatabaseOps;
  private Session session;

  @Autowired
  public UniversityStore(CassandraDatabaseOps cassandraDatabaseOps, PostgresDatabaseOps postgresDatabaseOps) {
    this.cassandraDatabaseOps = cassandraDatabaseOps;
    this.postgresDatabaseOps = postgresDatabaseOps;
    this.session = cassandraDatabaseOps.getSession();
    ensureTablesCreated();
  }

  private void ensureTablesCreated() {
    createTable(Student.CREATE_STUDENT_CQL_STMT);
    createTable(StudentCourse.CREATE_STUDENT_COURSES_CQL_STMT);
    createTable(Instructor.CREATE_INSTRUCTOR_CQL_STMT);
    createTable(InstructorCourse.CREATE_INSTRUCTOR_COURSES_CQL_STMT);
  }

  private void createTable(String cqlStatementString) {
    if (!StringUtils.isEmpty(cqlStatementString)) {
      session.execute(cqlStatementString);
    }
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

  @SuppressWarnings("WeakerAccess")
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

  @SuppressWarnings("WeakerAccess")
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
      throw new RuntimeException("Insert instructorCourse failed");
    }
  }

  public Instructor readInstructor(String id) {
    String cqlString = String.format("SELECT %1$s FROM %2$s WHERE id=?", Instructor.columnNames(), Instructor.tableName());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement selectStatement = preparedStatement.bind(id);
    ResultSet resultSet = session.execute(selectStatement);
    Row row = resultSet.one();
    if (row == null) {
      throw new RecordNotFoundException(String.format("Record not found for student id: %1$s", id));
    }
    return Instructor.getInstance(row);
  }

  public List<Instructor> readInstructors() {
    List<Instructor> instructors = new ArrayList<>();
    String cqlString = String.format("SELECT %1$s FROM %2$s", Instructor.columnNames(), Instructor.tableName());
    ResultSet resultSet = session.execute(cqlString);
    for (Row row : resultSet) {
      instructors.add(Instructor.getInstance(row));
    }
    return instructors;
  }

  @SuppressWarnings("WeakerAccess")
  public void writeInstructor(Instructor instructor) {
    String cqlString = String.format("INSERT INTO %1$s (%2$s) VALUES(?,?,?,?)", Instructor.tableName(), Instructor.columnNames());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement insertStatement = preparedStatement.bind(instructor.getId(), instructor.getName(), instructor.getDepartmentName(), instructor.getSalary());
    ResultSet resultSet = session.execute(insertStatement);
    if (!resultSet.wasApplied()) {
      throw new RuntimeException("Insert student failed");
    }
  }

  public List<InstructorCourse> readInstructorCourses(String id) {
    List<InstructorCourse> instructorCourses = new ArrayList<>();
    String cqlString = String.format("SELECT %1$s FROM %2$s WHERE ID=?", InstructorCourse.columnNames(), InstructorCourse.tableName());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement selectStatement = preparedStatement.bind(id);
    ResultSet resultSet = session.execute(selectStatement);
    for (Row row : resultSet) {
      instructorCourses.add(InstructorCourse.getInstance(row));
    }
    return instructorCourses;
  }

  @SuppressWarnings("WeakerAccess")
  public void writeInstructorCourse(InstructorCourse instructorCourse) {
    String cqlString = String.format("INSERT INTO %1$s (%2$s) VALUES(?,now(),?,?,?,?)", InstructorCourse.tableName(), InstructorCourse.columnNames());
    PreparedStatement preparedStatement = session.prepare(cqlString);
    Statement insertStatement = preparedStatement.bind(
        instructorCourse.getId(),
        instructorCourse.getCourseId(),
        instructorCourse.getSectionId(),
        instructorCourse.getSemester(),
        instructorCourse.getYear());
    ResultSet resultSet = session.execute(insertStatement);
    if (!resultSet.wasApplied()) {
      throw new RuntimeException("Insert instructorCourse failed");
    }
  }

  public String slurp() {
    slurpStudentData();
    slurpInstructorData();
    return "SUCCESS";
  }

  private void slurpStudentData() {
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
  }

  private void slurpInstructorData() {
    try (Connection conn = postgresDatabaseOps.getConnection()){
      //Copy postgreSQL instructor table to Cassandra instructor table
      String sqlString = String.format("SELECT %1$s FROM %2$s", PgInstructor.columnNames(), PgInstructor.tableName());
      java.sql.PreparedStatement statement = conn.prepareStatement(sqlString);
      java.sql.ResultSet resultSet = statement.executeQuery();
      while (resultSet.next()) {
        PgInstructor pgInstructor = PgInstructor.getInstance(resultSet);
        Instructor instructor = new Instructor();
        instructor.setId(pgInstructor.getId());
        instructor.setName(pgInstructor.getName());
        instructor.setDepartmentName(pgInstructor.getDepartmentName());
        instructor.setSalary(pgInstructor.getSalary());
        writeInstructor(instructor);
      }
      //Copy postgreSQL teaches table to Cassandra instructorCourses table
      sqlString = String.format("SELECT %1$s FROM %2$s order by year ASC, semester ASC", PgTeaches.columnNames(), PgTeaches.tableName());
      statement = conn.prepareStatement(sqlString);
      resultSet = statement.executeQuery();
      while (resultSet.next())  {
        PgTeaches teaches = PgTeaches.getInstance(resultSet);
        InstructorCourse instructorCourse = new InstructorCourse();
        instructorCourse.setId(teaches.getId());
        instructorCourse.setCourseId(teaches.getCourse_id());
        instructorCourse.setSectionId(teaches.getSection_id());
        instructorCourse.setSemester(teaches.getSemester());
        instructorCourse.setYear(teaches.getYear());
        writeInstructorCourse(instructorCourse);
      }
    }
    catch (SQLException e) {
      throw new RuntimeException("Unexpected database exception attempting to read postgres students", e);
    }
  }
}
