package com.busapp.busbackend.web.access;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ObjectNode;
import org.springframework.http.HttpStatus;

final class ApiAccessFilter implements Filter {

	static final String TOKEN_HEADER = "X-App-Token";
	private static final long WINDOW_MILLIS = Duration.ofMinutes(1).toMillis();

	private final byte[] expectedToken;
	private final int requestsPerMinute;
	private final ObjectMapper objectMapper;
	private final Clock clock;
	private final Object rateLimitMonitor = new Object();

	private long windowStartedAtMillis;
	private int requestsInWindow;

	ApiAccessFilter(
			String expectedToken,
			int requestsPerMinute,
			ObjectMapper objectMapper,
			Clock clock
	) {
		this.expectedToken = expectedToken.getBytes(StandardCharsets.UTF_8);
		this.requestsPerMinute = requestsPerMinute;
		this.objectMapper = objectMapper;
		this.clock = clock;
		this.windowStartedAtMillis = clock.millis();
	}

	@Override
	public void doFilter(
			ServletRequest servletRequest,
			ServletResponse servletResponse,
			FilterChain filterChain
	) throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) servletRequest;
		HttpServletResponse response = (HttpServletResponse) servletResponse;

		if (!hasValidToken(request.getHeader(TOKEN_HEADER))) {
			writeError(
					response,
					request,
					HttpServletResponse.SC_UNAUTHORIZED,
					"UNAUTHORIZED",
					"A valid X-App-Token header is required"
			);
			return;
		}

		if (!tryAcquire()) {
			response.setHeader("Retry-After", Long.toString(secondsUntilReset()));
			writeError(
					response,
					request,
					HttpStatus.TOO_MANY_REQUESTS.value(),
					"RATE_LIMITED",
					"Too many requests; retry after the current rate-limit window"
			);
			return;
		}

		filterChain.doFilter(request, response);
	}

	private boolean hasValidToken(String providedToken) {
		if (providedToken == null) {
			return false;
		}
		return MessageDigest.isEqual(
				expectedToken,
				providedToken.getBytes(StandardCharsets.UTF_8)
		);
	}

	private boolean tryAcquire() {
		synchronized (rateLimitMonitor) {
			resetWindowIfNeeded();
			if (requestsInWindow >= requestsPerMinute) {
				return false;
			}
			requestsInWindow++;
			return true;
		}
	}

	private long secondsUntilReset() {
		synchronized (rateLimitMonitor) {
			resetWindowIfNeeded();
			long remainingMillis = WINDOW_MILLIS - (clock.millis() - windowStartedAtMillis);
			return Math.max(1, (remainingMillis + 999) / 1_000);
		}
	}

	private void resetWindowIfNeeded() {
		long now = clock.millis();
		if (now - windowStartedAtMillis >= WINDOW_MILLIS) {
			windowStartedAtMillis = now;
			requestsInWindow = 0;
		}
	}

	private void writeError(
			HttpServletResponse response,
			HttpServletRequest request,
			int status,
			String code,
			String message
	) throws IOException {
		response.setStatus(status);
		response.setContentType("application/json");
		response.setCharacterEncoding(StandardCharsets.UTF_8.name());

		ObjectNode body = objectMapper.createObjectNode();
		body.put("code", code);
		body.put("message", message);
		body.put("timestamp", Instant.now(clock).toString());
		body.put("path", request.getRequestURI());
		objectMapper.writeValue(response.getOutputStream(), body);
	}

}
