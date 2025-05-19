package org.petify.funding.service;

import org.petify.funding.client.ShelterClient;
import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.exception.ResourceNotFoundException;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.DonationType;
import org.petify.funding.repository.DonationRepository;

import feign.FeignException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
@Service
public class DonationService {

    private final DonationRepository donationRepository;
    private final ShelterClient shelterClient;

    @Transactional(readOnly = true)
    public Page<DonationResponse> getAll(Pageable pageable, DonationType type) {
        Page<Donation> page = (type == null)
                ? donationRepository.findAll(pageable)
                : donationRepository.findAllByDonationType(type, pageable);
        return page.map(DonationResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public DonationResponse get(Long id) {
        Donation d = donationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Donation not found: " + id));
        return DonationResponse.fromEntity(d);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getForShelter(Long shelterId, Pageable pageable) {
        return donationRepository.findByShelterId(shelterId, pageable)
                .map(DonationResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getForPet(Long petId, Pageable pageable) {
        return donationRepository.findByPetId(petId, pageable)
                .map(DonationResponse::fromEntity);
    }

    @Transactional
    public DonationResponse create(@Valid DonationRequest req) {
        Donation donation = req.toEntity();

        try {
            shelterClient.checkShelterExists(donation.getShelterId());
        } catch (FeignException.NotFound ex) {
            throw new ResourceNotFoundException("Shelter not found: " + donation.getShelterId());
        }

        if (donation.getPetId() != null) {
            try {
                shelterClient.checkPetExists(donation.getShelterId(), donation.getPetId());
            } catch (FeignException.NotFound ex) {
                throw new ResourceNotFoundException(
                        "Pet not found: " + donation.getPetId()
                                + " in shelter: " + donation.getShelterId()
                );
            }
        }

        donation.setStatus(DonationStatus.PENDING);
        Donation saved = donationRepository.save(donation);
        return DonationResponse.fromEntity(saved);
    }

    @Transactional
    public void delete(Long id) {
        try {
            donationRepository.deleteById(id);
        } catch (EmptyResultDataAccessException ex) {
            throw new ResourceNotFoundException("Donation with id:"
                    + id + "not found");
        }
    }
}
