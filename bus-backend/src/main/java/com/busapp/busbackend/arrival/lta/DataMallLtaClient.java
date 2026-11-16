package com.busapp.busbackend.arrival.lta;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

@Component
public class DataMallLtaClient implements LtaClient {

	private static final String ACCOUNT_KEY_HEADER = "AccountKey";

	private final RestClient restClient;
	private final String accountKey;

	public DataMallLtaClient(
			@Qualifier("ltaRestClient") RestClient restClient,
			LtaApiProperties properties
	) {
		this.restClient = restClient;
		this.accountKey = properties.accountKey();
	}

	@Override
	public LtaBusArrivalResponse getBusArrivals(String stopCode, String serviceNo) {
		if (!StringUtils.hasText(accountKey)) {
			throw new LtaClientConfigurationException(
					"LTA DataMall access is unavailable because LTA_ACCOUNT_KEY is not configured"
			);
		}

		try {
			LtaBusArrivalResponse response = restClient.get()
					.uri(uriBuilder -> {
						uriBuilder.path("/v3/BusArrival")
								.queryParam("BusStopCode", stopCode);
						if (StringUtils.hasText(serviceNo)) {
							uriBuilder.queryParam("ServiceNo", serviceNo);
						}
						return uriBuilder.build();
					})
					.header(ACCOUNT_KEY_HEADER, accountKey)
					.retrieve()
					.body(LtaBusArrivalResponse.class);

			if (response == null) {
				throw new LtaClientException("LTA DataMall returned an empty response");
			}
			return response;
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

}
