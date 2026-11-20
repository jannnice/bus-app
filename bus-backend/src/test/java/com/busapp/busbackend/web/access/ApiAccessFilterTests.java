package com.busapp.busbackend.web.access;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class ApiAccessFilterTests {

	private static final String TOKEN = "a-personal-api-token-with-32-characters";
	private static final Instant NOW = Instant.parse("2026-11-20T04:00:00Z");

	private final ObjectMapper objectMapper = new ObjectMapper();

	@Test
	void acceptsARequestWithTheConfiguredToken() throws Exception {
		ApiAccessFilter filter = filterWithLimit(120);
		MockHttpServletRequest request = requestWithToken(TOKEN);
		MockHttpServletResponse response = new MockHttpServletResponse();
		FilterChain chain = mock(FilterChain.class);

		filter.doFilter(request, response, chain);

		verify(chain).doFilter(request, response);
		assertThat(response.getStatus()).isEqualTo(200);
	}

	@Test
	void rejectsARequestWithoutTheConfiguredToken() throws Exception {
		ApiAccessFilter filter = filterWithLimit(120);
		MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/arrivals/83139");
		MockHttpServletResponse response = new MockHttpServletResponse();
		FilterChain chain = mock(FilterChain.class);

		filter.doFilter(request, response, chain);

		verify(chain, never()).doFilter(request, response);
		assertThat(response.getStatus()).isEqualTo(401);
		JsonNode body = objectMapper.readTree(response.getContentAsByteArray());
		assertThat(body.get("code").asText()).isEqualTo("UNAUTHORIZED");
		assertThat(body.get("timestamp").asText()).isEqualTo(NOW.toString());
		assertThat(body.get("path").asText()).isEqualTo("/api/v1/arrivals/83139");
	}

	@Test
	void rejectsRequestsBeyondTheConfiguredLimit() throws Exception {
		ApiAccessFilter filter = filterWithLimit(2);
		FilterChain chain = mock(FilterChain.class);

		filter.doFilter(requestWithToken(TOKEN), new MockHttpServletResponse(), chain);
		filter.doFilter(requestWithToken(TOKEN), new MockHttpServletResponse(), chain);
		MockHttpServletResponse limitedResponse = new MockHttpServletResponse();
		filter.doFilter(requestWithToken(TOKEN), limitedResponse, chain);

		assertThat(limitedResponse.getStatus()).isEqualTo(429);
		assertThat(limitedResponse.getHeader("Retry-After")).isEqualTo("60");
		JsonNode body = objectMapper.readTree(limitedResponse.getContentAsByteArray());
		assertThat(body.get("code").asText()).isEqualTo("RATE_LIMITED");
	}

	private ApiAccessFilter filterWithLimit(int requestsPerMinute) {
		return new ApiAccessFilter(
				TOKEN,
				requestsPerMinute,
				objectMapper,
				Clock.fixed(NOW, ZoneOffset.UTC)
		);
	}

	private MockHttpServletRequest requestWithToken(String token) {
		MockHttpServletRequest request =
				new MockHttpServletRequest("GET", "/api/v1/arrivals/83139");
		request.addHeader(ApiAccessFilter.TOKEN_HEADER, token);
		return request;
	}

}
