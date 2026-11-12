package com.busapp.busbackend.arrival;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cache.CacheManager;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.busapp.busbackend.arrival.lta.LtaClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@SpringBootTest
class BusArrivalCachingTests {

	@Autowired
	private BusArrivalService busArrivalService;

	@Autowired
	private CacheManager cacheManager;

	@MockitoBean
	private LtaClient ltaClient;

	@BeforeEach
	void clearCache() {
		cacheManager.getCache("busArrivals").clear();
	}

	@Test
	void reusesAnLtaResponseWithinTheCacheWindow() {
		given(ltaClient.getBusArrivals("83139")).willReturn(LtaTestResponses.sample());

		BusArrivalResponse first = busArrivalService.getArrivals("83139");
		BusArrivalResponse second = busArrivalService.getArrivals("83139");

		assertThat(second).isEqualTo(first);
		verify(ltaClient, times(1)).getBusArrivals("83139");
	}

}
