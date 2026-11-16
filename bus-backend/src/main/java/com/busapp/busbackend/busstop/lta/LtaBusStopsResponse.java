package com.busapp.busbackend.busstop.lta;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LtaBusStopsResponse(
		@JsonProperty("value") List<LtaBusStopResponse> value
) {
}
