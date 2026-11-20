package com.busapp.busbackend.web.access;

import java.time.Clock;

import tools.jackson.databind.ObjectMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.util.Assert;

@Configuration(proxyBeanMethods = false)
@ConditionalOnProperty(
		prefix = "app.api-access",
		name = "enabled",
		havingValue = "true"
)
public class ApiAccessConfiguration {

	@Bean
	FilterRegistrationBean<ApiAccessFilter> apiAccessFilter(
			ApiAccessProperties properties,
			ObjectMapper objectMapper
	) {
		Assert.hasText(
				properties.token(),
				"APP_API_TOKEN must be configured when API access protection is enabled"
		);
		Assert.isTrue(
				properties.token().length() >= 32,
				"APP_API_TOKEN must contain at least 32 characters"
		);
		Assert.isTrue(
				properties.requestsPerMinute() > 0,
				"APP_REQUESTS_PER_MINUTE must be greater than zero"
		);

		ApiAccessFilter filter = new ApiAccessFilter(
				properties.token(),
				properties.requestsPerMinute(),
				objectMapper,
				Clock.systemUTC()
		);

		FilterRegistrationBean<ApiAccessFilter> registration =
				new FilterRegistrationBean<>(filter);
		registration.addUrlPatterns("/api/v1/*");
		registration.setOrder(Ordered.HIGHEST_PRECEDENCE);
		return registration;
	}

}
