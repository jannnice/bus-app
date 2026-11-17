package com.busapp.busbackend.busstop;

import java.math.BigDecimal;

public record BusStop(
		String stopCode,
		String roadName,
		String description,
		BigDecimal latitude,
		BigDecimal longitude
) {
}
