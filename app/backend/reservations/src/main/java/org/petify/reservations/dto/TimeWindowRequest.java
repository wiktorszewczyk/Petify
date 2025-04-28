package org.petify.reservations.dto;

import java.time.LocalTime;

public record TimeWindowRequest(LocalTime start, LocalTime end) {}