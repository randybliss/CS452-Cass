package org.byu.cs452.persistence;

/**
 * @author blissrj
 */
public class DatabaseStatus {

  private Status status;
  private String dbInstanceName;
  private String dbProductName;
  private String dbClusterName;
  private String dbKeyspaceName;
  private String version;

  public DatabaseStatus(String dbInstanceName, Status status) {
    this.dbInstanceName = dbInstanceName;
    this.status = status;
  }

  public String getDbInstanceName() {
    return dbInstanceName;
  }

  public Status getStatus() {
    return status;
  }

  public String getDbProductName() {
    return dbProductName;
  }

  public String getVersion() {
    return version;
  }

  public String getDbClusterName() {
    return dbClusterName;
  }

  public String getDbKeyspaceName() {
    return dbKeyspaceName;
  }

  public void setDbProductName(String dbProductName) {
    this.dbProductName = dbProductName;
  }

  public void setVersion(String version) {
    this.version = version;
  }

  public void setStatus(Status status) {
    this.status = status;
  }

  public void setDbClusterName(String dbClusterName) {
    this.dbClusterName = dbClusterName;
  }

  public void setDbKeyspaceName(String dbKeyspaceName) {
    this.dbKeyspaceName = dbKeyspaceName;
  }

  public enum Status{
    UP,
    DOWN
  }
}
