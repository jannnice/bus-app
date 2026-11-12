package com.busapp.busbackend.arrival;

import java.util.List;

public record BusServiceArrival(
		String serviceNo,
		String operator,
		List<BusArrivalPrediction> arrivals
) {
}
