package com.busapp.busbackend.arrival;

import java.util.Locale;

import jakarta.validation.constraints.Pattern;

import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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
			String stopCode,
			@RequestParam(required = false)
			@Pattern(
					regexp = "[A-Za-z0-9]{1,5}",
					message = "serviceNo must contain 1 to 5 letters or digits"
			)
			String serviceNo
	) {
		String normalizedServiceNo = StringUtils.hasText(serviceNo)
				? serviceNo.toUpperCase(Locale.ROOT)
				: null;
		return busArrivalService.getArrivals(stopCode, normalizedServiceNo);
	}

}
