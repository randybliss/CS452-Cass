package org.byu.cs452;

import org.byu.cs452.persistence.DatabaseCommonServices;
import org.byu.cs452.persistence.DatabaseStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * @author blissrj
 */
@RestController
public class CheckController {

  @Autowired
  DatabaseCommonServices databaseCommonServices;

  @RequestMapping(path="/check", method = RequestMethod.GET)
  public String checkAppAvailable() {
    return "cs452 university app service available\n";
  }

  @RequestMapping(path="/check/db", method=RequestMethod.GET)
  public List<DatabaseStatus> checkDatabaseAvailable() {
    return databaseCommonServices.getDatabaseStatusList();
  }
}
