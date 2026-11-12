package com.busapp.busbackend.arrival.lta;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "lta.api")
public record LtaApiProperties(
		String baseUrl,
		String accountKey,
		Duration connectTimeout,
		Duration readTimeout
) {
}
