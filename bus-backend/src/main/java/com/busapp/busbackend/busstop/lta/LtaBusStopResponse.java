package com.busapp.busbackend.busstop.lta;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LtaBusStopResponse(
		@JsonProperty("BusStopCode") String busStopCode,
		@JsonProperty("RoadName") String roadName,
		@JsonProperty("Description") String description,
		@JsonProperty("Latitude") BigDecimal latitude,
		@JsonProperty("Longitude") BigDecimal longitude
) {
}
