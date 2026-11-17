package com.busapp.busbackend.busstop;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BusStopController.class)
class BusStopControllerTests {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private BusStopService busStopService;

	@Test
	void searchesBusStops() throws Exception {
		given(busStopService.search("grand", 10)).willReturn(List.of(new BusStop(
				"01012",
				"Victoria St",
				"Hotel Grand Pacific",
				new BigDecimal("1.29685"),
				new BigDecimal("103.853")
		)));

		mockMvc.perform(get("/api/v1/bus-stops")
						.queryParam("query", " grand ")
						.queryParam("limit", "10"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$[0].stopCode").value("01012"))
				.andExpect(jsonPath("$[0].description").value("Hotel Grand Pacific"))
				.andExpect(jsonPath("$[0].latitude").value(1.29685));
	}

	@Test
	void findsNearbyBusStops() throws Exception {
		given(busStopService.findNearby(1.2968, 103.853, 750, 5))
				.willReturn(List.of(new NearbyBusStop(
						"01012",
						"Victoria St",
						"Hotel Grand Pacific",
						new BigDecimal("1.29685"),
						new BigDecimal("103.853"),
						6
				)));

		mockMvc.perform(get("/api/v1/bus-stops/nearby")
						.queryParam("latitude", "1.2968")
						.queryParam("longitude", "103.853")
						.queryParam("radiusMeters", "750")
						.queryParam("limit", "5"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$[0].stopCode").value("01012"))
				.andExpect(jsonPath("$[0].distanceMeters").value(6));
	}

	@Test
	void rejectsABlankSearchQueryWithTheStandardErrorContract() throws Exception {
		mockMvc.perform(get("/api/v1/bus-stops").queryParam("query", " "))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("INVALID_REQUEST"))
				.andExpect(jsonPath("$.message").value("query must not be blank"))
				.andExpect(jsonPath("$.timestamp").isNotEmpty())
				.andExpect(jsonPath("$.path").value("/api/v1/bus-stops"));
	}

	@Test
	void rejectsAnOutOfRangeLatitude() throws Exception {
		mockMvc.perform(get("/api/v1/bus-stops/nearby")
						.queryParam("latitude", "91")
						.queryParam("longitude", "103.853"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("INVALID_REQUEST"))
				.andExpect(jsonPath("$.message").value("latitude must be at most 90"));
	}

	@Test
	void rejectsAMissingLongitudeWithTheStandardErrorContract() throws Exception {
		mockMvc.perform(get("/api/v1/bus-stops/nearby")
						.queryParam("latitude", "1.2968"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("INVALID_REQUEST"))
				.andExpect(jsonPath("$.message")
						.value("Required request parameter 'longitude' is missing"));
	}

	@Test
	void rejectsANonNumericCoordinateWithTheStandardErrorContract() throws Exception {
		mockMvc.perform(get("/api/v1/bus-stops/nearby")
						.queryParam("latitude", "north")
						.queryParam("longitude", "103.853"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("INVALID_REQUEST"))
				.andExpect(jsonPath("$.message").value("latitude has an invalid value"));
	}

}
