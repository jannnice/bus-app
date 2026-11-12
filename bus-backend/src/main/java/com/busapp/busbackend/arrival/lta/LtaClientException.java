package com.busapp.busbackend.arrival.lta;

public class LtaClientException extends RuntimeException {

	public LtaClientException(String message) {
		super(message);
	}

	public LtaClientException(String message, Throwable cause) {
		super(message, cause);
	}

}
