package org.byu.cs452.persistence.cassandra;

import com.datastax.driver.core.Cluster;
import com.datastax.driver.core.Metadata;
import com.datastax.driver.core.ProtocolVersion;
import com.datastax.driver.core.Session;
import com.datastax.driver.core.exceptions.NoHostAvailableException;
import org.byu.cs452.persistence.DatabaseOps;
import org.byu.cs452.persistence.DatabaseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;

/**
 * @author blissrj
 */
@Service
public class CassandraDatabaseOps implements DatabaseOps {

  private final Logger LOG = LoggerFactory.getLogger(this.getClass());
  private final static String UNIVERSITY_KEYSPACE_NAME = "university";

  private Cluster.Builder clusterBuilder;
  private Session session;

  public CassandraDatabaseOps() {
    init();
  }

  private void init() {
    String username = "cs452";
    String password = "cs452";

    this.clusterBuilder = Cluster.builder()
        .withProtocolVersion(ProtocolVersion.V3) // V3 means client-side timestamps are used which are necessary for speculative execution.
        .addContactPoints("localhost").withPort(9042)
        .withCredentials(username, password);
    Cluster cluster = this.clusterBuilder.build();
    try {
      ensureKeyspaceCreated(cluster);
      this.session = cluster.connect(UNIVERSITY_KEYSPACE_NAME);
    }
    catch (NoHostAvailableException e) {
      cluster.close();
      LOG.warn("Cassandra host unavailable for connection at {} - university will start, but no database services will be available", "localhost");
    }
  }

  public Session getSession() {
    return this.session;
  }

  @Override
  public DatabaseStatus getDbStatus() {
    DatabaseStatus status = new DatabaseStatus("university-cassandra", DatabaseStatus.Status.DOWN);
    status.setDbProductName("cassandra");
    Cluster cluster = this.clusterBuilder.build();
    Metadata metadata;
    try {
      metadata = cluster.getMetadata();
    }
    catch (NoHostAvailableException e) {
      return status;
    }
    if (metadata == null) {
      return status;
    }
    if (metadata.getKeyspace(UNIVERSITY_KEYSPACE_NAME) == null) {
      return status;
    }
    status.setDbKeyspaceName(UNIVERSITY_KEYSPACE_NAME);
    status.setDbClusterName(metadata.getClusterName());
    status.setStatus(DatabaseStatus.Status.UP);
    return status;
  }

  private static final String CREATE_KEYSPACE_LOCAL_CASSANDRA = "CREATE KEYSPACE " + UNIVERSITY_KEYSPACE_NAME + " WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1}";

  private void ensureKeyspaceCreated(Cluster cluster) {
    Metadata metadata = cluster.getMetadata();
    if (metadata.getKeyspace(UNIVERSITY_KEYSPACE_NAME) == null) {
      Session session = cluster.connect();
      if (session == null) {
        throw new NoHostAvailableException(new HashMap<>());
      }
          session.execute(CREATE_KEYSPACE_LOCAL_CASSANDRA);
      session.close();
    }
  }
}
