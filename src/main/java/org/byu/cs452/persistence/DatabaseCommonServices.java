package org.byu.cs452.persistence;

import org.byu.cs452.persistence.cassandra.CassandraDatabaseOps;
import org.byu.cs452.persistence.postgres.PostgresDatabaseOps;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * @author blissrj
 */
@Service
public class DatabaseCommonServices {

  @Autowired
  private PostgresDatabaseOps postgresDatabaseOps;

  @Autowired
  private CassandraDatabaseOps cassandraDatabaseOps;

  public List<DatabaseStatus> getDatabaseStatusList() {
    List<DatabaseStatus> rtrn = new ArrayList<>();
    rtrn.add(postgresDatabaseOps.getDbStatus());
    rtrn.add(cassandraDatabaseOps.getDbStatus());
    return rtrn;
  }
}

