package com.busapp.busbackend.arrival;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record BusArrivalPrediction(
		String originCode,
		String destinationCode,
		OffsetDateTime estimatedArrival,
		boolean monitored,
		BigDecimal latitude,
		BigDecimal longitude,
		Integer visitNumber,
		BusLoad load,
		boolean wheelchairAccessible,
		BusType type
) {
}
