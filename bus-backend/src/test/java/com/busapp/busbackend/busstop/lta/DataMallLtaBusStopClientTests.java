package com.busapp.busbackend.busstop.lta;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;

import com.busapp.busbackend.arrival.lta.LtaApiProperties;
import com.busapp.busbackend.arrival.lta.LtaClientConfigurationException;
import com.busapp.busbackend.arrival.lta.LtaClientException;
import com.busapp.busbackend.busstop.BusStop;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class DataMallLtaBusStopClientTests {

	private static final String BASE_URL = "https://datamall2.mytransport.sg/ltaodataservice";
	private final ObjectMapper objectMapper = new ObjectMapper();

	@Test
	void sendsTheAccountKeyAndRetrievesEveryPage() throws Exception {
		RestClient.Builder builder = RestClient.builder();
		MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
		DataMallLtaBusStopClient client = client(builder, "test-account-key");

		server.expect(once(), requestTo(BASE_URL + "/BusStops"))
				.andExpect(method(HttpMethod.GET))
				.andExpect(header("AccountKey", "test-account-key"))
				.andRespond(withSuccess(pageJson(0, 500), MediaType.APPLICATION_JSON));
		server.expect(once(), requestTo(BASE_URL + "/BusStops?$skip=500"))
				.andExpect(method(HttpMethod.GET))
				.andRespond(withSuccess(pageJson(500, 1), MediaType.APPLICATION_JSON));
		server.expect(once(), requestTo(BASE_URL + "/BusStops?$skip=501"))
				.andExpect(method(HttpMethod.GET))
				.andRespond(withSuccess(pageJson(501, 0), MediaType.APPLICATION_JSON));

		List<BusStop> busStops = client.getAllBusStops();

		assertThat(busStops).hasSize(501);
		assertThat(busStops.getFirst().stopCode()).isEqualTo("00000");
		assertThat(busStops.getLast().stopCode()).isEqualTo("00500");
		server.verify();
	}

	@Test
	void rejectsCallsWhenTheAccountKeyIsMissing() {
		DataMallLtaBusStopClient client = client(RestClient.builder(), "");

		assertThatThrownBy(client::getAllBusStops)
				.isInstanceOf(LtaClientConfigurationException.class)
				.hasMessageContaining("LTA_ACCOUNT_KEY");
	}

	@Test
	void convertsUpstreamHttpErrorsIntoAnLtaClientFailure() {
		RestClient.Builder builder = RestClient.builder();
		MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
		DataMallLtaBusStopClient client = client(builder, "test-account-key");
		server.expect(requestTo(BASE_URL + "/BusStops")).andRespond(withServerError());

		assertThatThrownBy(client::getAllBusStops)
				.isInstanceOf(LtaClientException.class)
				.hasMessageContaining("HTTP 500");
		server.verify();
	}

	private DataMallLtaBusStopClient client(RestClient.Builder builder, String accountKey) {
		return new DataMallLtaBusStopClient(
				builder.baseUrl(BASE_URL).build(),
				new LtaApiProperties(
						BASE_URL,
						accountKey,
						Duration.ofSeconds(2),
						Duration.ofSeconds(5)
				),
				new LtaBusStopMapper()
		);
	}

	private String pageJson(int firstIndex, int count) throws Exception {
		List<Map<String, Object>> busStops = IntStream.range(firstIndex, firstIndex + count)
				.mapToObj(index -> Map.<String, Object>of(
						"BusStopCode", "%05d".formatted(index),
						"RoadName", "Example Rd",
						"Description", "Stop " + index,
						"Latitude", 1.30,
						"Longitude", 103.80
				))
				.toList();
		return objectMapper.writeValueAsString(Map.of("value", busStops));
	}

}
