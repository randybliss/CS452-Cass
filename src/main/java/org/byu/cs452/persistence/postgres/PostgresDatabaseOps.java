package org.byu.cs452.persistence.postgres;

import org.byu.cs452.persistence.ConnectionFactory;
import org.byu.cs452.persistence.DatabaseOps;
import org.byu.cs452.persistence.DatabaseStatus;
import org.springframework.stereotype.Service;

import java.sql.*;

/**
 * @author blissrj
 */
@Service
public class PostgresDatabaseOps implements DatabaseOps {

  private ConnectionFactory connectionFactory = new PostgreSQLPooledConnectionFactory("localhost", "CS452", "university", 10, "postgres", "postgres");

  public Connection getConnection() {
    return connectionFactory.getConnection();
  }

  @Override
  public DatabaseStatus getDbStatus() {
    DatabaseStatus status = new DatabaseStatus("university-postgres", DatabaseStatus.Status.UP);
    try (Connection conn = connectionFactory.getConnection()) {
      DatabaseMetaData metaData = conn.getMetaData();
      status.setDbProductName(metaData.getDatabaseProductName());
      status.setVersion(metaData.getDatabaseProductVersion());
      return status;
    }
    catch (Exception e) {
      status.setStatus(DatabaseStatus.Status.DOWN);
    }
    return status;
  }
}
