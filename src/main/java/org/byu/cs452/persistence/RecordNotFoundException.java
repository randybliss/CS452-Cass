package org.byu.cs452.persistence;

/**
 * @author blissrj
 */
public class RecordNotFoundException extends RuntimeException {
  public RecordNotFoundException(String message) {
    super(message);
  }
}
