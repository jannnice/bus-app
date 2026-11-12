package com.busapp.busbackend.arrival.lta;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.stream.Stream;

import com.busapp.busbackend.arrival.BusArrivalPrediction;
import com.busapp.busbackend.arrival.BusArrivalResponse;
import com.busapp.busbackend.arrival.BusLoad;
import com.busapp.busbackend.arrival.BusServiceArrival;
import com.busapp.busbackend.arrival.BusType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class LtaArrivalMapper {

	public BusArrivalResponse toApiResponse(LtaBusArrivalResponse source) {
		List<BusServiceArrival> services = source.services() == null
				? List.of()
				: source.services().stream().map(this::toService).toList();

		return new BusArrivalResponse(source.busStopCode(), services);
	}

	private BusServiceArrival toService(LtaBusServiceResponse source) {
		List<BusArrivalPrediction> arrivals = Stream.of(
					source.nextBus(), source.nextBus2(), source.nextBus3()
			)
				.map(this::toPrediction)
				.filter(Objects::nonNull)
				.toList();

		return new BusServiceArrival(source.serviceNo(), source.operator(), arrivals);
	}

	private BusArrivalPrediction toPrediction(LtaBusPredictionResponse source) {
		if (source == null || !StringUtils.hasText(source.estimatedArrival())) {
			return null;
		}

		try {
			return new BusArrivalPrediction(
					source.originCode(),
					source.destinationCode(),
					OffsetDateTime.parse(source.estimatedArrival()),
					Integer.valueOf(1).equals(source.monitored()),
					parseCoordinate(source.latitude()),
					parseCoordinate(source.longitude()),
					parseInteger(source.visitNumber()),
					toLoad(source.load()),
					"WAB".equals(source.feature()),
					toBusType(source.type())
			);
		}
		catch (DateTimeParseException | NumberFormatException exception) {
			throw new LtaClientException("LTA DataMall returned malformed bus arrival data", exception);
		}
	}

	private BigDecimal parseCoordinate(String value) {
		if (!StringUtils.hasText(value)) {
			return null;
		}
		BigDecimal coordinate = new BigDecimal(value);
		return coordinate.compareTo(BigDecimal.ZERO) == 0 ? null : coordinate;
	}

	private Integer parseInteger(String value) {
		return StringUtils.hasText(value) ? Integer.valueOf(value) : null;
	}

	private BusLoad toLoad(String value) {
		return switch (value == null ? "" : value) {
			case "SEA" -> BusLoad.SEATS_AVAILABLE;
			case "SDA" -> BusLoad.STANDING_AVAILABLE;
			case "LSD" -> BusLoad.LIMITED_STANDING;
			default -> BusLoad.UNKNOWN;
		};
	}

	private BusType toBusType(String value) {
		return switch (value == null ? "" : value) {
			case "SD" -> BusType.SINGLE_DECK;
			case "DD" -> BusType.DOUBLE_DECK;
			case "BD" -> BusType.BENDY;
			default -> BusType.UNKNOWN;
		};
	}

}
