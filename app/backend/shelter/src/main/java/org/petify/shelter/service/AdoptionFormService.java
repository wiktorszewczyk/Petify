package org.petify.shelter.service;

import lombok.AllArgsConstructor;
import org.petify.shelter.repository.AdoptionFormRepository;
import org.springframework.stereotype.Service;

@AllArgsConstructor
@Service
public class AdoptionFormService {
    private final AdoptionFormRepository adoptionFormRepository;


}
