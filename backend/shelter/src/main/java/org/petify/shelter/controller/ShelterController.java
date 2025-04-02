package org.petify.shelter.controller;

import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.service.ShelterService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/shelters")
public class ShelterController {
    private ShelterService shelterService;

    @GetMapping()
    public ResponseEntity<List<ShelterResponse>> getShelters() {
        return ResponseEntity.ok(shelterService.getShelters());
    }

    @PostMapping()
    public ResponseEntity<?> addShelter(@RequestBody ShelterRequest input) {
        return ResponseEntity.ok(shelterService.createShelter(input));
    }
}
