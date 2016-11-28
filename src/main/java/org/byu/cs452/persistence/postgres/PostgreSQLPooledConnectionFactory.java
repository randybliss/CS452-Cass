package org.byu.cs452.persistence.postgres;

import org.apache.commons.dbcp2.BasicDataSource;
import org.byu.cs452.persistence.ConnectionFactory;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * @author blissrj
 */
public class PostgreSQLPooledConnectionFactory implements ConnectionFactory {
  private static final String POSTGRESQL_DRIVER_NAME = "org.postgresql.Driver";

  private DataSource dataSource;
  private String schema;
  private String databaseName;

  PostgreSQLPooledConnectionFactory(String host, String database, String schema, int maxConnections, String userName, String password) {
    this.databaseName = database;
    this.dataSource = configureDataSource(host, database, maxConnections, userName, password);
    if (schema != null) {
      this.schema = schema;
    }
    else {
      this.schema = "public";
    }
  }

  @Override
  public Connection getConnection() {
    try {
      Connection conn = dataSource.getConnection();
      conn.setSchema(schema);
      return conn;
    }
    catch (SQLException e) {
      throw new RuntimeException(String.format("Failed to get connection to database: %s schema: %s", databaseName, schema), e);
    }
  }

  private DataSource configureDataSource(String host, String database, int maxConnections, String userName, String password) {
    String url = String.format("jdbc:postgresql://%s:5432/%s", host, database);
    BasicDataSource dataSource = new BasicDataSource();
    dataSource.setDriverClassName(POSTGRESQL_DRIVER_NAME);
    dataSource.setUrl(url);
    dataSource.setUsername(userName);
    dataSource.setPassword(password);
    dataSource.setMaxTotal(maxConnections);
    return dataSource;
  }
}
