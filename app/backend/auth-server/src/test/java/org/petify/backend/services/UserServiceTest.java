package org.petify.backend.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder encoder;

    @InjectMocks
    private UserService userService;

    private ApplicationUser testUser;

    @BeforeEach
    void setUp() {
        testUser = new ApplicationUser();
        testUser.setUserId(1);
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setPhoneNumber("123456789");
        testUser.setPassword("encodedPassword");
        testUser.setActive(true);
    }

    @Test
    void loadUserByUsername_WhenUserExistsByUsername_ShouldReturnUser() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        UserDetails result = userService.loadUserByUsername("testuser");

        assertThat(result).isNotNull();
        assertThat(result.getUsername()).isEqualTo("testuser");
        verify(userRepository).findByUsername("testuser");
    }

    @Test
    void loadUserByUsername_WhenUserExistsByEmail_ShouldReturnUser() {
        when(userRepository.findByUsername("test@example.com")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));

        UserDetails result = userService.loadUserByUsername("test@example.com");

        assertThat(result).isNotNull();
        assertThat(result.getUsername()).isEqualTo("testuser");
        verify(userRepository).findByUsername("test@example.com");
        verify(userRepository).findByEmail("test@example.com");
    }

    @Test
    void loadUserByUsername_WhenUserExistsByPhoneNumber_ShouldReturnUser() {
        when(userRepository.findByUsername("123456789")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("123456789")).thenReturn(Optional.empty());
        when(userRepository.findByPhoneNumber("123456789")).thenReturn(Optional.of(testUser));

        UserDetails result = userService.loadUserByUsername("123456789");

        assertThat(result).isNotNull();
        assertThat(result.getUsername()).isEqualTo("testuser");
        verify(userRepository).findByUsername("123456789");
        verify(userRepository).findByEmail("123456789");
        verify(userRepository).findByPhoneNumber("123456789");
    }

    @Test
    void loadUserByUsername_WhenUserDoesNotExist_ShouldThrowUsernameNotFoundException() {
        String nonExistentLogin = "nonexistent";
        when(userRepository.findByUsername(nonExistentLogin)).thenReturn(Optional.empty());
        when(userRepository.findByEmail(nonExistentLogin)).thenReturn(Optional.empty());
        when(userRepository.findByPhoneNumber(nonExistentLogin)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.loadUserByUsername(nonExistentLogin))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessage("User is not valid");

        verify(userRepository).findByUsername(nonExistentLogin);
        verify(userRepository).findByEmail(nonExistentLogin);
        verify(userRepository).findByPhoneNumber(nonExistentLogin);
    }

    @Test
    void loadUserByUsername_WhenUsernameIsNull_ShouldThrowUsernameNotFoundException() {
        when(userRepository.findByUsername(null)).thenReturn(Optional.empty());
        when(userRepository.findByEmail(null)).thenReturn(Optional.empty());
        when(userRepository.findByPhoneNumber(null)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.loadUserByUsername(null))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessage("User is not valid");
    }

    @Test
    void loadUserByUsername_WhenUsernameIsEmpty_ShouldThrowUsernameNotFoundException() {
        String emptyLogin = "";
        when(userRepository.findByUsername(emptyLogin)).thenReturn(Optional.empty());
        when(userRepository.findByEmail(emptyLogin)).thenReturn(Optional.empty());
        when(userRepository.findByPhoneNumber(emptyLogin)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.loadUserByUsername(emptyLogin))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessage("User is not valid");
    }

    @Test
    void loadUserByUsername_ShouldSearchInCorrectOrder() {
        String login = "searchvalue";

        when(userRepository.findByUsername(login)).thenReturn(Optional.empty());
        when(userRepository.findByEmail(login)).thenReturn(Optional.empty());
        when(userRepository.findByPhoneNumber(login)).thenReturn(Optional.of(testUser));

        UserDetails result = userService.loadUserByUsername(login);

        assertThat(result).isNotNull();

        var inOrder = org.mockito.Mockito.inOrder(userRepository);
        inOrder.verify(userRepository).findByUsername(login);
        inOrder.verify(userRepository).findByEmail(login);
        inOrder.verify(userRepository).findByPhoneNumber(login);
    }
}
