package org.petify.backend.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.oauth2.jwt.*;

import java.util.Collection;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TokenServiceTest {

    @Mock
    private JwtEncoder jwtEncoder;

    @Mock
    private JwtDecoder jwtDecoder;

    @Mock
    private Authentication authentication;

    @Mock
    private OAuth2User oauth2User;

    @InjectMocks
    private TokenService tokenService;

    private List<GrantedAuthority> authorities;

    @BeforeEach
    void setUp() {
        authorities = List.of(
                new SimpleGrantedAuthority("USER"),
                new SimpleGrantedAuthority("ROLE_ADMIN")
        );
    }

    @Test
    void generateJwt_WhenStandardAuthentication_ShouldGenerateJwtWithCorrectClaims() {
        Jwt mockJwt = mock(Jwt.class);
        when(mockJwt.getTokenValue()).thenReturn("encoded-jwt-token");

        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getAuthorities()).thenReturn((Collection) authorities);
        when(authentication.getPrincipal()).thenReturn("testuser");
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(mockJwt);

        String result = tokenService.generateJwt(authentication);

        assertThat(result).isEqualTo("encoded-jwt-token");

        verify(jwtEncoder).encode(any(JwtEncoderParameters.class));
        verify(authentication).getName();
        verify(authentication).getAuthorities();
        verify(authentication).getPrincipal();
    }

    @Test
    void generateJwt_WhenOAuth2Authentication_ShouldGenerateJwtWithOAuth2Claims() {
        Jwt mockJwt = mock(Jwt.class);
        when(mockJwt.getTokenValue()).thenReturn("encoded-jwt-token");

        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getAuthorities()).thenReturn((Collection) authorities);
        when(authentication.getPrincipal()).thenReturn(oauth2User);

        when(oauth2User.getAttribute(eq("userId"))).thenReturn("12345");
        when(oauth2User.getAttribute(eq("email"))).thenReturn("test@example.com");
        when(oauth2User.getAttribute(eq("name"))).thenReturn("Test User");

        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(mockJwt);

        String result = tokenService.generateJwt(authentication);

        assertThat(result).isEqualTo("encoded-jwt-token");

        verify(oauth2User, atLeastOnce()).getAttribute("userId");
        verify(oauth2User, atLeastOnce()).getAttribute("email");
        verify(oauth2User, atLeastOnce()).getAttribute("name");
        verify(jwtEncoder).encode(any(JwtEncoderParameters.class));
    }


    @Test
    void generateJwt_WhenOAuth2WithPartialAttributes_ShouldGenerateJwtWithAvailableClaims() {
        Jwt mockJwt = mock(Jwt.class);
        when(mockJwt.getTokenValue()).thenReturn("encoded-jwt-token");

        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getAuthorities()).thenReturn((Collection) authorities);
        when(authentication.getPrincipal()).thenReturn(oauth2User);

        when(oauth2User.getAttribute("userId")).thenReturn(null);
        when(oauth2User.getAttribute("email")).thenReturn("test@example.com", "test@example.com");
        when(oauth2User.getAttribute("name")).thenReturn(null);
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(mockJwt);

        String result = tokenService.generateJwt(authentication);

        assertThat(result).isEqualTo("encoded-jwt-token");

        verify(oauth2User).getAttribute("userId");
        verify(oauth2User, atLeastOnce()).getAttribute("email");
        verify(oauth2User).getAttribute("name");
        verify(jwtEncoder).encode(any(JwtEncoderParameters.class));
    }

    @Test
    void generateJwt_ShouldSetCorrectExpirationTime() {
        Jwt mockJwt = mock(Jwt.class);
        when(mockJwt.getTokenValue()).thenReturn("encoded-jwt-token");

        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getAuthorities()).thenReturn((Collection) authorities);
        when(authentication.getPrincipal()).thenReturn("testuser");
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(mockJwt);

        String result = tokenService.generateJwt(authentication);

        assertThat(result).isEqualTo("encoded-jwt-token");
        verify(jwtEncoder).encode(any(JwtEncoderParameters.class));
    }

    @Test
    void generateJwt_ShouldHandleRolePrefixCorrectly() {
        List<GrantedAuthority> mixedAuthorities = List.of(
                new SimpleGrantedAuthority("USER"),
                new SimpleGrantedAuthority("ROLE_ADMIN"),
                new SimpleGrantedAuthority("ROLE_MODERATOR"),
                new SimpleGrantedAuthority("VOLUNTEER")
        );

        Jwt mockJwt = mock(Jwt.class);
        when(mockJwt.getTokenValue()).thenReturn("encoded-jwt-token");

        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getAuthorities()).thenReturn((Collection) mixedAuthorities);
        when(authentication.getPrincipal()).thenReturn("testuser");
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(mockJwt);

        String result = tokenService.generateJwt(authentication);

        assertThat(result).isEqualTo("encoded-jwt-token");
        verify(jwtEncoder).encode(any(JwtEncoderParameters.class));
    }

    @Test
    void generateJwt_WhenNoAuthorities_ShouldGenerateJwtWithEmptyRoles() {
        Jwt mockJwt = mock(Jwt.class);
        when(mockJwt.getTokenValue()).thenReturn("encoded-jwt-token");

        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getAuthorities()).thenReturn(List.of());
        when(authentication.getPrincipal()).thenReturn("testuser");
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(mockJwt);

        String result = tokenService.generateJwt(authentication);

        assertThat(result).isEqualTo("encoded-jwt-token");
        verify(jwtEncoder).encode(any(JwtEncoderParameters.class));
    }

    @Test
    void validateJwt_WhenValidToken_ShouldReturnDecodedJwt() {
        String token = "valid-jwt-token";
        Jwt decodedJwt = mock(Jwt.class);
        when(jwtDecoder.decode(token)).thenReturn(decodedJwt);

        Jwt result = tokenService.validateJwt(token);

        assertThat(result).isEqualTo(decodedJwt);
        verify(jwtDecoder).decode(token);
    }

    @Test
    void validateJwt_WhenInvalidToken_ShouldThrowJwtException() {
        String invalidToken = "invalid-jwt-token";
        when(jwtDecoder.decode(invalidToken)).thenThrow(new JwtException("Invalid token"));

        assertThatThrownBy(() -> tokenService.validateJwt(invalidToken))
                .isInstanceOf(JwtException.class)
                .hasMessage("Invalid token");

        verify(jwtDecoder).decode(invalidToken);
    }

    @Test
    void validateJwt_WhenExpiredToken_ShouldThrowJwtException() {
        String expiredToken = "expired-jwt-token";
        when(jwtDecoder.decode(expiredToken)).thenThrow(new JwtException("Token expired"));

        assertThatThrownBy(() -> tokenService.validateJwt(expiredToken))
                .isInstanceOf(JwtException.class)
                .hasMessage("Token expired");

        verify(jwtDecoder).decode(expiredToken);
    }

    @Test
    void validateJwt_WhenNullToken_ShouldThrowException() {
        when(jwtDecoder.decode(null)).thenThrow(new IllegalArgumentException("Token cannot be null"));

        assertThatThrownBy(() -> tokenService.validateJwt(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Token cannot be null");
    }

    @Test
    void validateJwt_WhenEmptyToken_ShouldThrowException() {
        String emptyToken = "";
        when(jwtDecoder.decode(emptyToken)).thenThrow(new JwtException("Token cannot be empty"));

        assertThatThrownBy(() -> tokenService.validateJwt(emptyToken))
                .isInstanceOf(JwtException.class)
                .hasMessage("Token cannot be empty");
    }
}
