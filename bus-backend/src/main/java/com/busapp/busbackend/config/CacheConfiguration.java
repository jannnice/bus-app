package com.busapp.busbackend.config;

import java.time.Duration;
import java.util.List;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCache;
import org.springframework.cache.support.SimpleCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
@EnableCaching
public class CacheConfiguration {

	@Bean
	CacheManager cacheManager() {
		CaffeineCache busArrivals = new CaffeineCache(
				"busArrivals",
				Caffeine.newBuilder()
						.maximumSize(1_000)
						.expireAfterWrite(Duration.ofSeconds(20))
						.recordStats()
						.build()
		);
		CaffeineCache busStops = new CaffeineCache(
				"busStops",
				Caffeine.newBuilder()
						.maximumSize(1)
						.expireAfterWrite(Duration.ofHours(24))
						.recordStats()
						.build()
		);

		SimpleCacheManager cacheManager = new SimpleCacheManager();
		cacheManager.setCaches(List.of(busArrivals, busStops));
		return cacheManager;
	}

}
