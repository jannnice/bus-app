package com.busapp.busbackend.web.access;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("app.api-access")
public record ApiAccessProperties(
		boolean enabled,
		String token,
		int requestsPerMinute
) {
}
