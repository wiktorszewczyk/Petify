package org.petify.shelter.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.shelter.enums.MatchType;
import org.petify.shelter.exception.PetIsArchivedException;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.exception.ShelterIsNotActiveException;
import org.petify.shelter.model.FavoritePet;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FavoritePetServiceTest {

    @Mock
    private FavoritePetRepository favoritePetRepository;

    @Mock
    private PetRepository petRepository;

    @InjectMocks
    private FavoritePetService favoritePetService;

    @Test
    void like_ShouldCreateOrUpdateFavoritePetWithLikeStatus() {
        // Arrange
        String username = "user1";
        Long petId = 1L;
        Pet pet = createActivePet(petId);
        FavoritePet favoritePet = new FavoritePet();

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));
        when(favoritePetRepository.findByUsernameAndPetId(username, petId)).thenReturn(Optional.of(favoritePet));

        // Act
        favoritePetService.like(username, petId);

        // Assert
        verify(favoritePetRepository).save(favoritePet);
        assertThat(favoritePet.getStatus()).isEqualTo(MatchType.LIKE);
    }

    @Test
    void dislike_ShouldCreateOrUpdateFavoritePetWithDislikeStatus() {
        // Arrange
        String username = "user1";
        Long petId = 1L;
        Pet pet = createActivePet(petId);
        FavoritePet favoritePet = new FavoritePet();

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));
        when(favoritePetRepository.findByUsernameAndPetId(username, petId)).thenReturn(Optional.of(favoritePet));

        // Act
        favoritePetService.dislike(username, petId);

        // Assert
        verify(favoritePetRepository).save(favoritePet);
        assertThat(favoritePet.getStatus()).isEqualTo(MatchType.DISLIKE);
    }

    @Test
    void support_ShouldCreateOrUpdateFavoritePetWithSupportStatus() {
        // Arrange
        String username = "user1";
        Long petId = 1L;
        Pet pet = createActivePet(petId);
        FavoritePet favoritePet = new FavoritePet();

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));
        when(favoritePetRepository.findByUsernameAndPetId(username, petId)).thenReturn(Optional.of(favoritePet));

        // Act
        favoritePetService.support(username, petId);

        // Assert
        verify(favoritePetRepository).save(favoritePet);
        assertThat(favoritePet.getStatus()).isEqualTo(MatchType.SUPPORT);
    }

    @Test
    void like_WhenPetNotFound_ShouldThrowException() {
        // Arrange
        String username = "user1";
        Long petId = 1L;

        when(petRepository.findById(petId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> favoritePetService.like(username, petId))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining(petId.toString());
    }

    @Test
    void like_WhenPetIsArchived_ShouldThrowException() {
        // Arrange
        String username = "user1";
        Long petId = 1L;
        Pet pet = createActivePet(petId);
        pet.setArchived(true);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act & Assert
        assertThatThrownBy(() -> favoritePetService.like(username, petId))
                .isInstanceOf(PetIsArchivedException.class)
                .hasMessageContaining(petId.toString());
    }

    @Test
    void like_WhenShelterIsNotActive_ShouldThrowException() {
        // Arrange
        String username = "user1";
        Long petId = 1L;
        Pet pet = createActivePet(petId);
        pet.getShelter().setIsActive(false);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act & Assert
        assertThatThrownBy(() -> favoritePetService.like(username, petId))
                .isInstanceOf(ShelterIsNotActiveException.class);
    }

    private Pet createActivePet(Long id) {
        Shelter shelter = new Shelter();
        shelter.setIsActive(true);

        Pet pet = new Pet();
        pet.setId(id);
        pet.setShelter(shelter);
        pet.setArchived(false);
        return pet;
    }
}