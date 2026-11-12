package com.busapp.busbackend.arrival;

import java.util.List;

public record BusArrivalResponse(
		String stopCode,
		List<BusServiceArrival> services
) {
}
