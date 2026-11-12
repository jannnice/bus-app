package com.busapp.busbackend.arrival.lta;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LtaBusArrivalResponse(
		@JsonProperty("BusStopCode") String busStopCode,
		@JsonProperty("Services") List<LtaBusServiceResponse> services
) {
}
