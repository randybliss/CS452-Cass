package org.byu.cs452;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;

import java.util.Arrays;

/**
 * @author blissrj
 */
@SpringBootApplication
public class UniversityApplication {
  private static ObjectMapper objectMapper = new ObjectMapper(new JsonFactory());

  public static void main(String[] args) {
    ApplicationContext ctx = SpringApplication.run(UniversityApplication.class, args);

    System.out.println("Let's inspect the beans provided by Spring Boot:");

    String[] beanNames = ctx.getBeanDefinitionNames();
    Arrays.sort(beanNames);
    for (String beanName : beanNames) {
      System.out.println(beanName);
    }
  }

  public static ObjectMapper getObjectMapper() {
    return objectMapper;
  }
}
