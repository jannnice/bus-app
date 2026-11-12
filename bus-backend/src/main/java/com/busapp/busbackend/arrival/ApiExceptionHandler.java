package com.busapp.busbackend.arrival;

import com.busapp.busbackend.arrival.lta.LtaClientConfigurationException;
import com.busapp.busbackend.arrival.lta.LtaClientException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {

	@ExceptionHandler(LtaClientConfigurationException.class)
	public ResponseEntity<ApiErrorResponse> handleMissingLtaConfiguration(
			LtaClientConfigurationException exception
	) {
		return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
				.body(new ApiErrorResponse("LTA_NOT_CONFIGURED", exception.getMessage()));
	}

	@ExceptionHandler(LtaClientException.class)
	public ResponseEntity<ApiErrorResponse> handleLtaFailure(LtaClientException exception) {
		return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
				.body(new ApiErrorResponse("LTA_UNAVAILABLE", exception.getMessage()));
	}

}
