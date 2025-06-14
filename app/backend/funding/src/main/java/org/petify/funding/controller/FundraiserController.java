package org.petify.funding.controller;

import org.petify.funding.dto.FundraiserRequest;
import org.petify.funding.dto.FundraiserResponse;
import org.petify.funding.dto.FundraiserStats;
import org.petify.funding.model.FundraiserStatus;
import org.petify.funding.service.FundraiserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/fundraisers")
@RequiredArgsConstructor
@Slf4j
public class FundraiserController {

    private final FundraiserService fundraiserService;

    @PostMapping
    @PreAuthorize("hasAuthority('ROLE_SHELTER')")
    public ResponseEntity<FundraiserResponse> createFundraiser(
            @RequestBody @Valid FundraiserRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        log.info("Creating fundraiser for shelter: {}", request.getShelterId());
        FundraiserResponse fundraiser = fundraiserService.create(request, jwt);
        return ResponseEntity.status(HttpStatus.CREATED).body(fundraiser);
    }

    @GetMapping("/{id}")
    public ResponseEntity<FundraiserResponse> getFundraiser(@PathVariable Long id) {
        FundraiserResponse fundraiser = fundraiserService.get(id);
        return ResponseEntity.ok(fundraiser);
    }

    @GetMapping
    public ResponseEntity<Page<FundraiserResponse>> getActiveFundraisers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<FundraiserResponse> fundraisers = fundraiserService.getActiveFundraisers(
                PageRequest.of(page, size, Sort.by("createdAt").descending()));
        return ResponseEntity.ok(fundraisers);
    }

    @GetMapping("/shelter/{shelterId}")
    public ResponseEntity<Page<FundraiserResponse>> getFundraisersByShelter(
            @PathVariable Long shelterId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<FundraiserResponse> fundraisers = fundraiserService.getByShelter(
                shelterId, PageRequest.of(page, size, Sort.by("createdAt").descending()));
        return ResponseEntity.ok(fundraisers);
    }

    @GetMapping("/shelter/{shelterId}/main")
    public ResponseEntity<FundraiserResponse> getMainFundraiser(@PathVariable Long shelterId) {
        Optional<FundraiserResponse> fundraiser = fundraiserService.getMainFundraiser(shelterId);
        return fundraiser.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_SHELTER')")
    public ResponseEntity<FundraiserResponse> updateFundraiser(
            @PathVariable Long id,
            @RequestBody @Valid FundraiserRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        FundraiserResponse fundraiser = fundraiserService.update(id, request, jwt);
        return ResponseEntity.ok(fundraiser);
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAuthority('ROLE_SHELTER')")
    public ResponseEntity<FundraiserResponse> updateFundraiserStatus(
            @PathVariable Long id,
            @RequestParam FundraiserStatus status) {

        FundraiserResponse fundraiser = fundraiserService.updateStatus(id, status);
        return ResponseEntity.ok(fundraiser);
    }

    @GetMapping("/{id}/stats")
    public ResponseEntity<FundraiserStats> getFundraiserStats(@PathVariable Long id) {
        FundraiserStats stats = fundraiserService.getStats(id);
        return ResponseEntity.ok(stats);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public void deleteFundraiser(@PathVariable Long id) {
        fundraiserService.delete(id);
    }
}
