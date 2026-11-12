package com.busapp.busbackend.arrival;

import java.util.List;

import com.busapp.busbackend.arrival.lta.LtaBusArrivalResponse;
import com.busapp.busbackend.arrival.lta.LtaBusPredictionResponse;
import com.busapp.busbackend.arrival.lta.LtaBusServiceResponse;

final class LtaTestResponses {

	private LtaTestResponses() {
	}

	static LtaBusArrivalResponse sample() {
		return new LtaBusArrivalResponse(
				"83139",
				List.of(new LtaBusServiceResponse(
						"15",
						"GAS",
						new LtaBusPredictionResponse(
								"77009",
								"77009",
								"2026-11-12T12:03:00+08:00",
								1,
								"1.3154918333333334",
								"103.9059125",
								"1",
								"SEA",
								"WAB",
								"SD"
						),
						new LtaBusPredictionResponse(
								"77009",
								"77009",
								"2026-11-12T12:12:00+08:00",
								0,
								"0.0",
								"0.0",
								"1",
								"SDA",
								"",
								"DD"
						),
						new LtaBusPredictionResponse(
								"",
								"",
								"",
								0,
								"",
								"",
								"",
								"",
								"",
								""
						)
				))
		);
	}

}
