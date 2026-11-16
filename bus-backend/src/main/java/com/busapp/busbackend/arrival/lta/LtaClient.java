package com.busapp.busbackend.arrival.lta;

public interface LtaClient {

	LtaBusArrivalResponse getBusArrivals(String stopCode, String serviceNo);

}
