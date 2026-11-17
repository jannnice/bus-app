package com.busapp.busbackend.busstop;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class BusStopServiceTests {

	private final BusStopCatalog busStopCatalog = mock(BusStopCatalog.class);
	private final BusStopService busStopService = new BusStopService(busStopCatalog);

	@Test
	void searchesCodesDescriptionsAndRoadNamesCaseInsensitively() {
		when(busStopCatalog.getAll()).thenReturn(List.of(
				busStop("01013", "Victoria St", "St. Joseph's Ch"),
				busStop("01012", "Victoria St", "Hotel Grand Pacific"),
				busStop("83139", "Jln Eunos", "Eunos Int")
		));

		List<BusStop> results = busStopService.search("VICTORIA", 20);

		assertThat(results)
				.extracting(BusStop::stopCode)
				.containsExactly("01012", "01013");
	}

	@Test
	void ranksAnExactStopCodeFirstAndHonoursTheLimit() {
		when(busStopCatalog.getAll()).thenReturn(List.of(
				busStop("83130", "Jln Eunos", "Opp Blk 16"),
				busStop("83139", "Jln Eunos", "Blk 17"),
				busStop("18313", "Clementi Rd", "Opp SIM HQ")
		));

		List<BusStop> results = busStopService.search("83139", 1);

		assertThat(results).extracting(BusStop::stopCode).containsExactly("83139");
	}

	@Test
	void returnsOnlyNearbyStopsOrderedByDistance() {
		when(busStopCatalog.getAll()).thenReturn(List.of(
				busStop("00003", "Far Rd", "Far", "1.3100", "103.8000"),
				busStop("00002", "Near Rd", "Second", "1.3010", "103.8000"),
				busStop("00001", "Near Rd", "First", "1.3001", "103.8000")
		));

		List<NearbyBusStop> results = busStopService.findNearby(1.3000, 103.8000, 500, 20);

		assertThat(results)
				.extracting(NearbyBusStop::stopCode)
				.containsExactly("00001", "00002");
		assertThat(results.getFirst().distanceMeters()).isLessThan(
				results.getLast().distanceMeters()
		);
	}

	private BusStop busStop(String stopCode, String roadName, String description) {
		return busStop(stopCode, roadName, description, "1.3000", "103.8000");
	}

	private BusStop busStop(
			String stopCode,
			String roadName,
			String description,
			String latitude,
			String longitude
	) {
		return new BusStop(
				stopCode,
				roadName,
				description,
				new BigDecimal(latitude),
				new BigDecimal(longitude)
		);
	}

}
