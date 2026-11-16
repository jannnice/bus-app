package com.busapp.busbackend.web.error;

import java.time.Instant;

public record ApiErrorResponse(
		String code,
		String message,
		Instant timestamp,
		String path
) {
}
