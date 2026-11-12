package com.busapp.busbackend.arrival.lta;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LtaBusPredictionResponse(
		@JsonProperty("OriginCode") String originCode,
		@JsonProperty("DestinationCode") String destinationCode,
		@JsonProperty("EstimatedArrival") String estimatedArrival,
		@JsonProperty("Monitored") Integer monitored,
		@JsonProperty("Latitude") String latitude,
		@JsonProperty("Longitude") String longitude,
		@JsonProperty("VisitNumber") String visitNumber,
		@JsonProperty("Load") String load,
		@JsonProperty("Feature") String feature,
		@JsonProperty("Type") String type
) {
}
