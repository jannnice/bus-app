package com.busapp.busbackend.busstop.lta;

import com.busapp.busbackend.arrival.lta.LtaClientException;
import com.busapp.busbackend.busstop.BusStop;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class LtaBusStopMapper {

	public BusStop toBusStop(LtaBusStopResponse source) {
		if (source == null
				|| !StringUtils.hasText(source.busStopCode())
				|| source.latitude() == null
				|| source.longitude() == null) {
			throw new LtaClientException("LTA DataMall returned malformed bus stop data");
		}

		return new BusStop(
				source.busStopCode(),
				source.roadName() == null ? "" : source.roadName(),
				source.description() == null ? "" : source.description(),
				source.latitude(),
				source.longitude()
		);
	}

}
