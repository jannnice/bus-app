package com.busapp.busbackend.arrival;

public record ApiErrorResponse(
		String code,
		String message
) {
}
