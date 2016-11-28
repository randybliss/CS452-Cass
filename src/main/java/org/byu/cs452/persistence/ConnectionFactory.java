package org.byu.cs452.persistence;

import java.sql.Connection;

/**
 * @author blissrj
 */
public interface ConnectionFactory {
  Connection getConnection();
}
