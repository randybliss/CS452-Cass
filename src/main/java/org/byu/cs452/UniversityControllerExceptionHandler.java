package org.byu.cs452;

import org.byu.cs452.persistence.RecordNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * @author blissrj
 */
@RestControllerAdvice
public class UniversityControllerExceptionHandler {
  @ResponseStatus(HttpStatus.NOT_FOUND)
  @ExceptionHandler(RecordNotFoundException.class)
  public void handleNotFoundException(RecordNotFoundException ex, HttpServletResponse response) {
    try {
      response.sendError(HttpStatus.NOT_FOUND.value(), ex.getMessage());
    }
    catch (IOException ignore) {
    }
  }
}
