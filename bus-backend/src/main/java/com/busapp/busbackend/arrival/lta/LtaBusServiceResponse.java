package com.busapp.busbackend.arrival.lta;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LtaBusServiceResponse(
		@JsonProperty("ServiceNo") String serviceNo,
		@JsonProperty("Operator") String operator,
		@JsonProperty("NextBus") LtaBusPredictionResponse nextBus,
		@JsonProperty("NextBus2") LtaBusPredictionResponse nextBus2,
		@JsonProperty("NextBus3") LtaBusPredictionResponse nextBus3
) {
}
