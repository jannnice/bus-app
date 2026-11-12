package com.busapp.busbackend.arrival;

import jakarta.validation.constraints.Pattern;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/arrivals")
public class BusArrivalController {

	private final BusArrivalService busArrivalService;

	public BusArrivalController(BusArrivalService busArrivalService) {
		this.busArrivalService = busArrivalService;
	}

	@GetMapping("/{stopCode}")
	public BusArrivalResponse getArrivals(
			@PathVariable
			@Pattern(regexp = "\\d{5}", message = "stopCode must contain exactly 5 digits")
			String stopCode
	) {
		return busArrivalService.getArrivals(stopCode);
	}

}
