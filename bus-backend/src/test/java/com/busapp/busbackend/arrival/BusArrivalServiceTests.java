package com.busapp.busbackend.arrival;

import com.busapp.busbackend.arrival.lta.LtaArrivalMapper;
import com.busapp.busbackend.arrival.lta.LtaClient;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;

class BusArrivalServiceTests {

	@Test
	void transformsLtaDataIntoThePublicApiModel() {
		LtaClient ltaClient = mock(LtaClient.class);
		given(ltaClient.getBusArrivals("83139", "15")).willReturn(LtaTestResponses.sample());
		BusArrivalService busArrivalService = new BusArrivalService(
				ltaClient,
				new LtaArrivalMapper()
		);

		BusArrivalResponse response = busArrivalService.getArrivals("83139", "15");

		assertThat(response.stopCode()).isEqualTo("83139");
		assertThat(response.services()).hasSize(1);
		BusServiceArrival service = response.services().getFirst();
		assertThat(service.serviceNo()).isEqualTo("15");
		assertThat(service.operator()).isEqualTo("GAS");
		assertThat(service.arrivals()).hasSize(2);
		assertThat(service.arrivals().getFirst().load()).isEqualTo(BusLoad.SEATS_AVAILABLE);
		assertThat(service.arrivals().getFirst().wheelchairAccessible()).isTrue();
		assertThat(service.arrivals().getFirst().type()).isEqualTo(BusType.SINGLE_DECK);
		assertThat(service.arrivals().get(1).latitude()).isNull();
		assertThat(service.arrivals().get(1).monitored()).isFalse();
	}

}
