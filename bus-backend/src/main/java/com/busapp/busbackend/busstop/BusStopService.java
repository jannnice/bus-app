package com.busapp.busbackend.busstop;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;

import org.springframework.stereotype.Service;

@Service
public class BusStopService {

	private static final double EARTH_RADIUS_METERS = 6_371_000;

	private final BusStopCatalog busStopCatalog;

	public BusStopService(BusStopCatalog busStopCatalog) {
		this.busStopCatalog = busStopCatalog;
	}

	public List<BusStop> search(String query, int limit) {
		String normalizedQuery = normalize(query);

		return busStopCatalog.getAll().stream()
				.filter(busStop -> matches(busStop, normalizedQuery))
				.sorted(Comparator
						.comparingInt((BusStop busStop) -> relevance(busStop, normalizedQuery))
						.thenComparing(BusStop::description, String.CASE_INSENSITIVE_ORDER)
						.thenComparing(BusStop::stopCode))
				.limit(limit)
				.toList();
	}

	public List<NearbyBusStop> findNearby(
			double latitude,
			double longitude,
			int radiusMeters,
			int limit
	) {
		return busStopCatalog.getAll().stream()
				.map(busStop -> toNearbyBusStop(busStop, latitude, longitude))
				.filter(busStop -> busStop.distanceMeters() <= radiusMeters)
				.sorted(Comparator
						.comparingLong(NearbyBusStop::distanceMeters)
						.thenComparing(NearbyBusStop::stopCode))
				.limit(limit)
				.toList();
	}

	private boolean matches(BusStop busStop, String query) {
		return normalize(busStop.stopCode()).contains(query)
				|| normalize(busStop.description()).contains(query)
				|| normalize(busStop.roadName()).contains(query);
	}

	private int relevance(BusStop busStop, String query) {
		String stopCode = normalize(busStop.stopCode());
		String description = normalize(busStop.description());
		String roadName = normalize(busStop.roadName());

		if (stopCode.equals(query)) {
			return 0;
		}
		if (stopCode.startsWith(query)) {
			return 1;
		}
		if (description.equals(query)) {
			return 2;
		}
		if (description.startsWith(query)) {
			return 3;
		}
		if (roadName.startsWith(query)) {
			return 4;
		}
		return 5;
	}

	private NearbyBusStop toNearbyBusStop(
			BusStop busStop,
			double latitude,
			double longitude
	) {
		long distanceMeters = Math.round(distanceMeters(
				latitude,
				longitude,
				busStop.latitude().doubleValue(),
				busStop.longitude().doubleValue()
		));

		return new NearbyBusStop(
				busStop.stopCode(),
				busStop.roadName(),
				busStop.description(),
				busStop.latitude(),
				busStop.longitude(),
				distanceMeters
		);
	}

	private double distanceMeters(
			double latitude,
			double longitude,
			double stopLatitude,
			double stopLongitude
	) {
		double latitudeDelta = Math.toRadians(stopLatitude - latitude);
		double longitudeDelta = Math.toRadians(stopLongitude - longitude);
		double startLatitude = Math.toRadians(latitude);
		double endLatitude = Math.toRadians(stopLatitude);
		double haversine = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2)
				+ Math.cos(startLatitude) * Math.cos(endLatitude)
				* Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);

		return 2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(Math.min(1, haversine)));
	}

	private String normalize(String value) {
		return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
	}

}
