package com.busapp.busbackend.busstop;

import java.util.List;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/bus-stops")
public class BusStopController {

	private final BusStopService busStopService;

	public BusStopController(BusStopService busStopService) {
		this.busStopService = busStopService;
	}

	@GetMapping
	public List<BusStop> search(
			@RequestParam
			@NotBlank(message = "query must not be blank")
			@Size(max = 100, message = "query must contain at most 100 characters")
			String query,
			@RequestParam(defaultValue = "20")
			@Min(value = 1, message = "limit must be at least 1")
			@Max(value = 100, message = "limit must be at most 100")
			int limit
	) {
		return busStopService.search(query.trim(), limit);
	}

	@GetMapping("/nearby")
	public List<NearbyBusStop> findNearby(
			@RequestParam
			@DecimalMin(value = "-90", message = "latitude must be at least -90")
			@DecimalMax(value = "90", message = "latitude must be at most 90")
			double latitude,
			@RequestParam
			@DecimalMin(value = "-180", message = "longitude must be at least -180")
			@DecimalMax(value = "180", message = "longitude must be at most 180")
			double longitude,
			@RequestParam(defaultValue = "500")
			@Min(value = 1, message = "radiusMeters must be at least 1")
			@Max(value = 5000, message = "radiusMeters must be at most 5000")
			int radiusMeters,
			@RequestParam(defaultValue = "20")
			@Min(value = 1, message = "limit must be at least 1")
			@Max(value = 100, message = "limit must be at most 100")
			int limit
	) {
		return busStopService.findNearby(
				latitude,
				longitude,
				radiusMeters,
				limit
		);
	}

}
