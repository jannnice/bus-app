package com.busapp.busbackend.arrival;

import com.busapp.busbackend.arrival.lta.LtaArrivalMapper;
import com.busapp.busbackend.arrival.lta.LtaClient;
import com.busapp.busbackend.arrival.lta.LtaBusArrivalResponse;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class BusArrivalService {

	private final LtaClient ltaClient;
	private final LtaArrivalMapper ltaArrivalMapper;

	public BusArrivalService(LtaClient ltaClient, LtaArrivalMapper ltaArrivalMapper) {
		this.ltaClient = ltaClient;
		this.ltaArrivalMapper = ltaArrivalMapper;
	}

	@Cacheable(cacheNames = "busArrivals", sync = true)
	public BusArrivalResponse getArrivals(String stopCode, String serviceNo) {
		LtaBusArrivalResponse ltaResponse = ltaClient.getBusArrivals(stopCode, serviceNo);
		return ltaArrivalMapper.toApiResponse(ltaResponse);
	}

}
