package com.busapp.busbackend.web.error;

import java.time.Instant;
import java.util.List;

import com.busapp.busbackend.arrival.lta.LtaClientConfigurationException;
import com.busapp.busbackend.arrival.lta.LtaClientException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.springframework.context.MessageSourceResolvable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class GlobalExceptionHandler {

	@ExceptionHandler(HandlerMethodValidationException.class)
	public ResponseEntity<ApiErrorResponse> handleRequestValidation(
			HandlerMethodValidationException exception,
			HttpServletRequest request
	) {
		return errorResponse(
				HttpStatus.BAD_REQUEST,
				"INVALID_REQUEST",
				firstMessage(exception.getAllErrors(), "Request validation failed"),
				request
		);
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<ApiErrorResponse> handleRequestBodyValidation(
			MethodArgumentNotValidException exception,
			HttpServletRequest request
	) {
		return errorResponse(
				HttpStatus.BAD_REQUEST,
				"INVALID_REQUEST",
				firstMessage(exception.getBindingResult().getAllErrors(), "Request validation failed"),
				request
		);
	}

	@ExceptionHandler(ConstraintViolationException.class)
	public ResponseEntity<ApiErrorResponse> handleConstraintViolation(
			ConstraintViolationException exception,
			HttpServletRequest request
	) {
		String message = exception.getConstraintViolations().stream()
				.map(violation -> violation.getMessage())
				.findFirst()
				.orElse("Request validation failed");

		return errorResponse(
				HttpStatus.BAD_REQUEST,
				"INVALID_REQUEST",
				message,
				request
		);
	}

	@ExceptionHandler(MissingServletRequestParameterException.class)
	public ResponseEntity<ApiErrorResponse> handleMissingRequestParameter(
			MissingServletRequestParameterException exception,
			HttpServletRequest request
	) {
		return errorResponse(
				HttpStatus.BAD_REQUEST,
				"INVALID_REQUEST",
				"Required request parameter '" + exception.getParameterName() + "' is missing",
				request
		);
	}

	@ExceptionHandler(MethodArgumentTypeMismatchException.class)
	public ResponseEntity<ApiErrorResponse> handleRequestParameterTypeMismatch(
			MethodArgumentTypeMismatchException exception,
			HttpServletRequest request
	) {
		return errorResponse(
				HttpStatus.BAD_REQUEST,
				"INVALID_REQUEST",
				exception.getName() + " has an invalid value",
				request
		);
	}

	@ExceptionHandler(LtaClientConfigurationException.class)
	public ResponseEntity<ApiErrorResponse> handleMissingLtaConfiguration(
			LtaClientConfigurationException exception,
			HttpServletRequest request
	) {
		return errorResponse(
				HttpStatus.SERVICE_UNAVAILABLE,
				"LTA_NOT_CONFIGURED",
				exception.getMessage(),
				request
		);
	}

	@ExceptionHandler(LtaClientException.class)
	public ResponseEntity<ApiErrorResponse> handleLtaFailure(
			LtaClientException exception,
			HttpServletRequest request
	) {
		return errorResponse(
				HttpStatus.BAD_GATEWAY,
				"LTA_UNAVAILABLE",
				exception.getMessage(),
				request
		);
	}

	private ResponseEntity<ApiErrorResponse> errorResponse(
			HttpStatus status,
			String code,
			String message,
			HttpServletRequest request
	) {
		return ResponseEntity.status(status).body(new ApiErrorResponse(
				code,
				message,
				Instant.now(),
				request.getRequestURI()
		));
	}

	private String firstMessage(
			List<? extends MessageSourceResolvable> errors,
			String fallback
	) {
		return errors.stream()
				.map(MessageSourceResolvable::getDefaultMessage)
				.filter(message -> message != null && !message.isBlank())
				.findFirst()
				.orElse(fallback);
	}

}
