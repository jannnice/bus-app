package com.busapp.busbackend.busstop.lta;

import java.util.ArrayList;
import java.util.List;

import com.busapp.busbackend.arrival.lta.LtaApiProperties;
import com.busapp.busbackend.arrival.lta.LtaClientConfigurationException;
import com.busapp.busbackend.arrival.lta.LtaClientException;
import com.busapp.busbackend.busstop.BusStop;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

@Component
public class DataMallLtaBusStopClient implements LtaBusStopClient {

	private static final String ACCOUNT_KEY_HEADER = "AccountKey";

	private final RestClient restClient;
	private final String accountKey;
	private final LtaBusStopMapper mapper;

	public DataMallLtaBusStopClient(
			@Qualifier("ltaRestClient") RestClient restClient,
			LtaApiProperties properties,
			LtaBusStopMapper mapper
	) {
		this.restClient = restClient;
		this.accountKey = properties.accountKey();
		this.mapper = mapper;
	}

	@Override
	public List<BusStop> getAllBusStops() {
		if (!StringUtils.hasText(accountKey)) {
			throw new LtaClientConfigurationException(
					"LTA DataMall access is unavailable because LTA_ACCOUNT_KEY is not configured"
			);
		}

		try {
			List<BusStop> busStops = new ArrayList<>();
			int skip = 0;

			while (true) {
				List<LtaBusStopResponse> page = getPage(skip);
				if (page.isEmpty()) {
					break;
				}
				page.stream().map(mapper::toBusStop).forEach(busStops::add);
				skip += page.size();
			}

			return List.copyOf(busStops);
		}
		catch (RestClientResponseException exception) {
			throw new LtaClientException(
					"LTA DataMall returned HTTP " + exception.getStatusCode().value(),
					exception
			);
		}
		catch (RestClientException exception) {
			throw new LtaClientException("Could not reach LTA DataMall", exception);
		}
	}

	private List<LtaBusStopResponse> getPage(int skip) {
		LtaBusStopsResponse response = restClient.get()
				.uri(uriBuilder -> {
					uriBuilder.path("/BusStops");
					if (skip > 0) {
						uriBuilder.queryParam("$skip", skip);
					}
					return uriBuilder.build();
				})
				.header(ACCOUNT_KEY_HEADER, accountKey)
				.retrieve()
				.body(LtaBusStopsResponse.class);

		if (response == null) {
			throw new LtaClientException("LTA DataMall returned an empty response");
		}
		return response.value() == null ? List.of() : response.value();
	}

}
