package com.busapp.busbackend.busstop;

import java.util.List;

import com.busapp.busbackend.busstop.lta.LtaBusStopClient;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class BusStopCatalog {

	private final LtaBusStopClient ltaBusStopClient;

	public BusStopCatalog(LtaBusStopClient ltaBusStopClient) {
		this.ltaBusStopClient = ltaBusStopClient;
	}

	@Cacheable(cacheNames = "busStops", key = "'all'", sync = true)
	public List<BusStop> getAll() {
		return List.copyOf(ltaBusStopClient.getAllBusStops());
	}

}
