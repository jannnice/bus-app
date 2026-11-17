package com.busapp.busbackend.busstop;

import java.math.BigDecimal;
import java.util.List;

import com.busapp.busbackend.busstop.lta.LtaBusStopClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cache.CacheManager;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@SpringBootTest
class BusStopCachingTests {

	@Autowired
	private BusStopCatalog busStopCatalog;

	@Autowired
	private CacheManager cacheManager;

	@MockitoBean
	private LtaBusStopClient ltaBusStopClient;

	@BeforeEach
	void clearCache() {
		cacheManager.getCache("busStops").clear();
	}

	@Test
	void reusesTheBusStopCatalogWithinTheCacheWindow() {
		List<BusStop> busStops = List.of(new BusStop(
				"01012",
				"Victoria St",
				"Hotel Grand Pacific",
				new BigDecimal("1.29685"),
				new BigDecimal("103.853")
		));
		given(ltaBusStopClient.getAllBusStops()).willReturn(busStops);

		List<BusStop> first = busStopCatalog.getAll();
		List<BusStop> second = busStopCatalog.getAll();

		assertThat(second).isEqualTo(first);
		verify(ltaBusStopClient, times(1)).getAllBusStops();
	}

}
