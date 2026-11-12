package com.busapp.busbackend.arrival;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

import com.busapp.busbackend.arrival.lta.LtaClientConfigurationException;
import com.busapp.busbackend.arrival.lta.LtaClientException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BusArrivalController.class)
class BusArrivalControllerTests {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private BusArrivalService busArrivalService;

	@Test
	void returnsArrivalsAsJson() throws Exception {
		given(busArrivalService.getArrivals("83139"))
				.willReturn(new BusArrivalResponse(
						"83139",
						List.of(new BusServiceArrival(
								"15",
								"GAS",
								List.of(new BusArrivalPrediction(
										"77009",
										"77009",
										OffsetDateTime.parse("2026-11-12T12:03:00+08:00"),
										true,
										new BigDecimal("1.3154918333333334"),
										new BigDecimal("103.9059125"),
										1,
										BusLoad.SEATS_AVAILABLE,
										true,
										BusType.SINGLE_DECK
								))
						))
				));

		mockMvc.perform(get("/api/v1/arrivals/83139"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.stopCode").value("83139"))
				.andExpect(jsonPath("$.services[0].serviceNo").value("15"))
				.andExpect(jsonPath("$.services[0].operator").value("GAS"))
				.andExpect(jsonPath("$.services[0].arrivals[0].estimatedArrival")
						.value("2026-11-12T12:03:00+08:00"))
				.andExpect(jsonPath("$.services[0].arrivals[0].load")
						.value("SEATS_AVAILABLE"));
	}

	@Test
	void rejectsInvalidStopCode() throws Exception {
		mockMvc.perform(get("/api/v1/arrivals/not-a-stop"))
				.andExpect(status().isBadRequest());
	}

	@Test
	void returnsBadGatewayWhenLtaIsUnavailable() throws Exception {
		given(busArrivalService.getArrivals("83139"))
				.willThrow(new LtaClientException("Could not reach LTA DataMall"));

		mockMvc.perform(get("/api/v1/arrivals/83139"))
				.andExpect(status().isBadGateway())
				.andExpect(jsonPath("$.code").value("LTA_UNAVAILABLE"));
	}

	@Test
	void returnsServiceUnavailableWhenTheAccountKeyIsMissing() throws Exception {
		given(busArrivalService.getArrivals("83139"))
				.willThrow(new LtaClientConfigurationException("LTA_ACCOUNT_KEY is not configured"));

		mockMvc.perform(get("/api/v1/arrivals/83139"))
				.andExpect(status().isServiceUnavailable())
				.andExpect(jsonPath("$.code").value("LTA_NOT_CONFIGURED"));
	}

}
