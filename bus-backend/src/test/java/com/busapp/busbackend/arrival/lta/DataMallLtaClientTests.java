package com.busapp.busbackend.arrival.lta;

import java.nio.charset.StandardCharsets;
import java.time.Duration;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class DataMallLtaClientTests {

	private static final String BASE_URL = "https://datamall2.mytransport.sg/ltaodataservice";

	@Test
	void sendsTheAccountKeyAndDeserializesLtaJson() throws Exception {
		RestClient.Builder builder = RestClient.builder();
		MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
		DataMallLtaClient client = new DataMallLtaClient(
				builder.baseUrl(BASE_URL).build(),
				properties("test-account-key")
		);
		String responseJson = new ClassPathResource("fixtures/lta-bus-arrival.json")
				.getContentAsString(StandardCharsets.UTF_8);

		server.expect(once(), requestTo(BASE_URL + "/v3/BusArrival?BusStopCode=83139"))
				.andExpect(method(HttpMethod.GET))
				.andExpect(header("AccountKey", "test-account-key"))
				.andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

		LtaBusArrivalResponse response = client.getBusArrivals("83139");

		assertThat(response.busStopCode()).isEqualTo("83139");
		assertThat(response.services()).hasSize(1);
		assertThat(response.services().getFirst().nextBus().monitored()).isEqualTo(1);
		assertThat(response.services().getFirst().nextBus3().estimatedArrival()).isEmpty();
		server.verify();
	}

	@Test
	void rejectsCallsWhenTheAccountKeyIsMissing() {
		DataMallLtaClient client = new DataMallLtaClient(
				RestClient.builder().baseUrl(BASE_URL).build(),
				properties("")
		);

		assertThatThrownBy(() -> client.getBusArrivals("83139"))
				.isInstanceOf(LtaClientConfigurationException.class)
				.hasMessageContaining("LTA_ACCOUNT_KEY");
	}

	@Test
	void convertsUpstreamHttpErrorsIntoAnLtaClientFailure() {
		RestClient.Builder builder = RestClient.builder();
		MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
		DataMallLtaClient client = new DataMallLtaClient(
				builder.baseUrl(BASE_URL).build(),
				properties("test-account-key")
		);
		server.expect(requestTo(BASE_URL + "/v3/BusArrival?BusStopCode=83139"))
				.andRespond(withServerError());

		assertThatThrownBy(() -> client.getBusArrivals("83139"))
				.isInstanceOf(LtaClientException.class)
				.hasMessageContaining("HTTP 500");
		server.verify();
	}

	private LtaApiProperties properties(String accountKey) {
		return new LtaApiProperties(
				BASE_URL,
				accountKey,
				Duration.ofSeconds(2),
				Duration.ofSeconds(5)
		);
	}

}
