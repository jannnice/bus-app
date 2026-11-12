package com.busapp.busbackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class BusBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BusBackendApplication.class, args);
	}

}
