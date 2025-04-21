package org.petify.funding.service;

import feign.FeignException;
import lombok.RequiredArgsConstructor;
import org.petify.funding.client.ShelterClient;
import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.exception.ResourceNotFoundException;
import org.petify.funding.model.Donation;
import org.petify.funding.repository.DonationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Service
public class DonationService {

    private final DonationRepository donationRepository;
    private final ShelterClient shelterClient;

    /**
     * Fetch all donations.
     */
    public List<DonationResponse> getAllDonations() {
        return donationRepository.findAll().stream()
                .map(DonationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Find one by ID, or 404 if not found.
     */
    public DonationResponse getDonationById(Long id) {
        Donation d = donationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Donation not found: " + id));
        return DonationResponse.fromEntity(d);
    }

    /**
     * Find all donations made to a given shelter.
     */
    public List<DonationResponse> getDonationsForShelter(Long shelterId) {
        return donationRepository.findByShelterId(shelterId).stream()
                .map(DonationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Find all donations made to a given pet.
     */
    public List<DonationResponse> getDonationsForPet(Long petId) {
        return donationRepository.findByPetId(petId).stream()
                .map(DonationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Create any subtype of Donation.
     * Validates that the shelter (and optional pet) exist before saving.
     */
    @Transactional
    public DonationResponse createDonation(DonationRequest req) {
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
                                + " in shelter: " + donation.getShelterId());
            }
        }

        Donation saved = donationRepository.save(donation);
        return DonationResponse.fromEntity(saved);
    }

    /**
     * Delete a donation by ID.
     */
    @Transactional
    public void deleteDonation(Long id) {
        if (!donationRepository.existsById(id)) {
            throw new ResourceNotFoundException("Donation not found: " + id);
        }
        donationRepository.deleteById(id);
    }
}